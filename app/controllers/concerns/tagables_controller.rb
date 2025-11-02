module TagablesController
  extend ActiveSupport::Concern

  included do
    before_action :authenticate_user!
  end

  # Configuration methods that subclasses should override
  private


    # Main abstracted methods
    # GET /index - abstracted index action with proper authorization
    def index_tagable
      resource_class = controller_name.classify.constantize

      @q = policy_scope(resource_class).ransack(params[:q])
      @pagy, @resources = pagy(@q.result.includes(:tag), limit: 20)

      # Set the resources instance variable (e.g., @motors, @switchboards)
      resources_var_name = "@#{controller_name}"
      instance_variable_set(resources_var_name, @resources)
      # Orphans are resources without a parent tag so are unusable.
      @orphans = @resources.select{ |resource| resource.tag.nil? }

      # Find any tags that have tagable_type for this resource but do not have valid tagable.
      @link_errors = policy_scope(Tag).select { |tag| tag.tagable_type == controller_name.classify && tag.tagable.nil? }
      # These tags are marked with tagable type for this resource but not yet assigned: normal.
      @link_incomplete = @link_errors.select{ |tag| tag.tagable_id.nil? }
      # These tags are linked to missing resources, tagable needs to be nullified: broken.
      @link_broken = @link_errors.select{ |tag| !tag.tagable_id.nil? }

      authorize @resources, :index?
    end

    # GET /new - abstracted new action
    def new_tagable
      resource_class = controller_name.classify.constantize
      resource_var = resource_class.new()
      instance_variable_set("@#{resource_name}", resource_var)

      @resource = resource_var
      authorize @resource, :new?
      set_tag
      setup_form
    end

  # POST /switchboards 
    def create_tagable
      # For create action, we need to create a new resource
      resource_class = controller_name.classify.constantize

      begin
        @resource = resource_class.new(send("#{resource_name}_params").except(:tag))
      rescue ArgumentError => _
        # Handle invalid enum values as a conflict
        raise ApplicationController::ConflictError, :invalid_enum
      end

      authorize @resource, :create?
      unless @resource.valid?
        flash.now[:alert] = t("flash.actions.create.alert",
                          resource_name: @resource.class.model_name.human.downcase)
        failed_to_save
        return
      end

      set_tag
      unless @tag.valid?
        handle_invalid_tag
        return
      end
      # Authorize tag to check project (via discipline) against current project context
      authorize @tag, :create?
      
      if @tag.persisted?
        update_tag_with_tagable_resource
      else
        create_tag_and_resource
      end
    end

    # GET /edit 
    def edit_tagable
      @resource = instance_variable_get("@#{resource_name}")
      authorize @resource, :edit?

      # Allow edit of resource without a tag as a way to rescue orphans
      @tag = @resource.tag&.present? ? @resource.tag : Tag.new(tagable_type: controller_name.classify)
      setup_form
    end

    # PATCH/PUT /switchboards/1 
    def update_tagable
      @resource = instance_variable_get("@#{resource_name}")

      # Make a dummy resource object for checking params
      begin
        dummy_resource = @resource.dup
        dummy_resource.assign_attributes(send("#{resource_name}_params").except(:tag))
      rescue ArgumentError => _
        # Handle invalid enum values as a conflict
        raise ApplicationController::ConflictError, :invalid_enum
      end

      unless dummy_resource.valid?
        flash.now[:alert] = t("flash.actions.update.alert",
                            resource_name: @resource.class.model_name.human.downcase)
        failed_to_save
        return
      end
      authorize @resource, :update?

      # Tagable allows a new tag to be created via update, as a way to rescue orphans
      @tag = @resource.tag&.present? ? @resource.tag : Tag.new(tag_params.merge(tagable: @resource))

      unless @tag.valid?
        flash.now[:alert] = t("flash.actions.update.alert",
                            resource_name: @tag.class.model_name.human.downcase)
        failed_to_save
        return
      end
      # Separate authorization for tag update to check project against current project context

      if @resource.tag&.persisted?
        authorize @tag, :update?
        # Update existing tag and resource
        update_resource
      else
      authorize @tag, :create?
        # Create new tag and assign resource
        create_tag_for_orphan_resource
      end
    end

    # DELETE /:id - abstracted destroy action
    def destroy_tagable
      @resource = instance_variable_get("@#{resource_name}")
      authorize @resource, :destroy?
      @resource.destroy

      respond_to do |format|
        format.html {
          flash[:success] = t('flash.actions.destroy.notice',
            resource_name: @resource.class.model_name.human)
          redirect_to send("#{controller_name}_path"), status: :see_other
        }
        format.json { head :no_content }
      end
    end

    def set_tag
      # Rails.logger.info "tag_params: #{tag_params}"
      # Handle case when linking to existing tag through tagable_id association first
      # Uses shallow nested route
      if params[:tag_id].present?
        @tag = Tag.find_by(id: params[:tag_id])
        if @tag.nil?
          # Tag not found in database
          @tag = Tag.new
          @tag.instance_variable_set(:@custom_error, :tag_not_found)
          return false
        elsif @tag.tagable.present?
          # Tag already assigned to a tagable
          @tag = Tag.new
          @tag.instance_variable_set(:@custom_error, :tag_already_assigned)
          return false
        elsif @tag.tagable_type&.present? && @tag.tagable_type != controller_name.classify
          # Tag designated for different controller type
          @tag = Tag.new
          @tag.instance_variable_set(:@custom_error, :tagable_type_mismatch)
          return false
        end
      else
        if tag_params.present?
          # Handle case with tag parameters
          @tag = Tag.new(tag_params)
        else
          # No tag parameters: new resource
          @tag = Tag.new()
        end
      end
    end

    def handle_invalid_tag
      case @tag.instance_variable_get(:@custom_error)
      when :tag_not_found, :tag_already_assigned, :tagable_type_mismatch
        # tag_id was set but trapped in set_tag
        raise ApplicationController::ConflictError, @tag.instance_variable_get(:@custom_error)
        return
      else
        flash.now[:alert] = t("flash.actions.create.alert",
                          resource_name: @tag.class.model_name.human.downcase)
        failed_to_save
        return
      end
    end

    # Existing tag: Create resource from params and update tag with tagable
    def update_tag_with_tagable_resource
      begin
        @tag.update(tagable: @resource)
        flash[:success] = [t('flash.tagables.assigned_to',
                          resource_name: @resource.class.model_name.human,
                          id: @resource.id,
                          tag: @tag.label)]
        after_create_hook(@resource)
        redirect_after_save
        return
      rescue ActiveRecord::RecordInvalid => _
        # Should not reach here - @tag and @resource have been validated
        flash.now[:alert] = t("flash.actions.create.alert",
                          resource_name: @resource.class.model_name.human.downcase)
        failed_to_save
      end
    end

    # New resource and tag from params
    def create_tag_and_resource
      begin
        @resource.class.transaction do
          @tag.save!
          @tag.update(tagable: @resource)
        end
        @tag.reload
        flash[:success] = [t('flash.tagables.created_and_assigned',
                          resource_name: @resource.class.model_name.human,
                          id: @resource.id,
                          tag: @tag.label)]
        after_create_hook(@resource)
        redirect_after_save
        return
      rescue ActiveRecord::RecordInvalid => _
        # Should not reach here - @tag and @resource have been validated
        flash.now[:alert] = t("flash.actions.create.alert",
                          resource_name: @resource.class.model_name.human.downcase)
        failed_to_save
      end
    end

    def failed_to_save
      # If we get here, there was a validation error preventing save
      # Ensure the resource variable is set for the view before setup_form
      resource_var_name = "@#{resource_name}"
      instance_variable_set(resource_var_name, @resource) unless instance_variable_get(resource_var_name)
      return_action = @resource.persisted? ? :edit : :new
      setup_form
      respond_to do |format|
        format.html { render return_action, status: :unprocessable_content }
        format.json { render json: @resource.errors, status: :unprocessable_content }
      end
    end

    # Update existing tag and resource
    def update_resource
      begin
        @resource.class.transaction do
          @tag = @resource.tag
          @tag.update!(tag_params) # This is a relic. The form doesn't have tag fields if the tag is persisted.
          @resource.update!(send("#{resource_name}_params").except(:tag))
        end
        flash[:success] = [t("flash.actions.update.notice", 
          resource_name: @resource.class.model_name.human)]
        after_update_hook(@resource)
        redirect_after_save
        return
      rescue ActiveRecord::RecordInvalid => e
        # Should not reach here - @tag and @resource have been validated
        flash.now[:alert] = t("flash.actions.update.alert",
                          resource_name: @resource.class.model_name.human.downcase)
        failed_to_save
      end
    end

    # Create new tag and associate with resource
    def create_tag_for_orphan_resource
      begin
        @resource.class.transaction do
          @tag = Tag.create!(tag_params.merge(tagable: @resource))
          @resource.update!(send("#{resource_name}_params").except(:tag))
        end
        flash[:success] = [t("flash.tagables.assigned_to.notice", 
          resource_name: @resource.class.model_name.human,
          id: @resource.id,
          tag: @tag.label)]
        after_update_hook(@resource)
        redirect_after_save
      rescue ActiveRecord::RecordInvalid => e
        # Should not reach here - @tag and @resource have been validated
        flash.now[:alert] = t("flash.actions.update.alert",
                          resource_name: @resource.class.model_name.human.downcase)
        failed_to_save
        return
      end
    end

    def setup_form
      if current_project
        @project = current_project
      else
        @project = nil
      end
      @projects = policy_scope(Project)
      @disciplines = policy_scope(Discipline)

      # Set default tag attributes if tag is not persisted
      unless @tag&.persisted?
        @tag ||= Tag.new(tagable_type: controller_name.classify)
        @tag.discipline ||= Discipline.find_by(code: discipline_code)
        @tag.prefix ||= tag_prefix
      end
      # Hook for model-specific form setup
      setup_additional_form_data
    end

    def redirect_after_save
      respond_to do |format|
        format.html { redirect_to @resource }
        format.json { render :show, status: :created, location: @resource }
      end
    end

    def resource_name
      controller_name.singularize.to_sym
    end

    # Override to specify model-specific tag prefix
    def tag_prefix
      controller_name.classify.upcase[0..1]  # Default: first 2 letters of model name
    end

    # Override to specify model-specific discipline code
    def discipline_code
      "E"  # Electrical by default
    end

    # Override to specify model-specific form setup
    def setup_additional_form_data
      # Override in subclass for model-specific setup
    end

    # Override to specify model-specific post-creation logic
    def after_create_hook(resource)
      # Override in subclass for model-specific logic (e.g., circuits creation)
    end

    # Override to specify model-specific post-update logic
    def after_update_hook(resource)
      # Override in subclass for model-specific logic
    end

    def tag_params
      # Get the tag parameters from the nested structure
      tag_source = if params[controller_name.singularize.to_sym].present?
                    params[controller_name.singularize.to_sym][:tag] || {}
                  else
                    params[:tag] || {}
                  end

      # If tag_source is already an ActionController::Parameters, use it directly
      # Otherwise, convert it to ActionController::Parameters
      tag_params = tag_source.is_a?(ActionController::Parameters) ?
                  tag_source :
                  ActionController::Parameters.new(tag_source)

      # Permitted parameters
      tag_params.permit(
        :project_id, :discipline_id, :prefix, :serial, :suffix,
        :service, :stage, :notes, :tagable_id, :tagable_type
      )
    end
end
