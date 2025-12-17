module TagablesController
  extend ActiveSupport::Concern

  included do
    before_action :authenticate_user!
    before_action :require_project!, only: %i[ new create edit update ]
    before_action :set_resource, only: %i[ show edit update destroy ]
  end

  # Configuration methods that subclasses should override
  private

    def set_resource
      @resource = resource_class.find(params[:id])
    end

    # Main abstracted methods
    # GET /index - abstracted index action with proper authorization
    # This method will set the resources instance variable (e.g., @motors, @switchboards)
    # in accordance with the policy scope for the resource, ransack seach params, and pagy.
    def index_tagable
      authorize resource_class, :index?
      @q = policy_scope(resource_class).ransack(params[:q])
      @pagy, @resources = pagy(@q.result.includes(:tag), limit: 20)

      # Set the resources instance variable (e.g., @motors, @switchboards)
      # At present, orphans will only be visible to admins, as other users 
      # have their scope set by current_project, and orphans do not have a project.
      resources_var_name = "@#{controller_name}"
      # Separate resources with tags from orphans (resources without tags)
      @resources, @orphans = @resources.partition(&:tag)
      instance_variable_set(resources_var_name, @resources)

      # Find any tags that have tagable_type for this resource but do not have valid tagable.
      @link_errors = policy_scope(Tag).select { |tag| tag.tagable_type == controller_path.classify && tag.tagable.nil? }
      # Separate incomplete links (no tagable_id) from broken links (has tagable_id but missing resource)
      @link_incomplete, @link_broken = @link_errors.partition { |tag| tag.tagable_id.nil? }

    end

    # GET /show - abstracted show action
    def show_tagable
      authorize @resource, :show?
      instance_variable_set(resource_var_name, @resource)
    end

    # GET /new - abstracted new action
    def new_tagable
      @resource = resource_class.new()
      authorize @resource, :new?
      set_tag
      setup_form
    end

  # POST /switchboards 
    def create_tagable
      # For create action, we need to create a new resource
      begin
        @resource = resource_class.new(resource_params.except(:tag))
      rescue ArgumentError => _
        # Handle invalid enum values as a conflict
        raise ApplicationController::ConflictError, :invalid_enum
      end

      set_tag
      if @tag.instance_variable_get(:@custom_error).present? || !@tag.valid?
        handle_invalid_tag
        return
      end
      # Authorize tag to check project (via discipline) against current project context
      authorize @tag, :create?

      authorize @resource, :create?
      unless @resource.valid?
        flash.now[:alert] = t("flash.create.alert",
                          resource_name: @resource.model_name.human.downcase)
        failed_to_save
        return
      end
      
      if @tag.persisted?
        update_tag_with_tagable_resource
      else
        create_tag_and_resource
      end
    end

    # GET /edit 
    def edit_tagable
      authorize @resource, :edit?

      # Allow edit of resource without a tag as a way to rescue orphans
      @tag = (@resource.tag&.present? && @resource.tag.valid?)? @resource.tag : Tag.new(tagable_type: controller_path.classify)
      setup_form
    end

    # PATCH/PUT /switchboards/1 
    def update_tagable
      authorize @resource, :update?

      # Tagable allows a new tag to be created via update, as a way to rescue orphans
      @tag = @resource.tag&.present? ? @resource.tag : Tag.new(tag_params.merge(tagable: @resource))

      unless @tag.valid?
        flash.now[:alert] = t("flash.create.alert",
                            resource_name: @tag.model_name.human.downcase)
        failed_to_save
        return
      end

      # Make a dummy resource object for checking params
      begin
        dummy_resource = @resource.dup
        dummy_resource.assign_attributes(resource_params.except(:tag))
      rescue ArgumentError => _
        # Handle invalid enum values as a conflict
        raise ApplicationController::ConflictError, :invalid_enum
      end

      unless dummy_resource.valid?
        flash.now[:alert] = t("flash.update.alert",
                            resource_name: @resource.model_name.human.downcase)
        failed_to_save
        return
      end

      # Separate authorization for tag update to check project against current project context
      if @tag&.persisted?
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
      authorize @resource, :destroy?
      if @resource.destroy
        respond_to do |format|
          format.html do
            flash[:success] = t('flash.destroy.notice',
                              resource_name: @resource.model_name.human)
            redirect_to send("#{resource_path.to_s}_path"), 
                        status: :see_other
          end
          format.json { head :no_content }
        end

      else
        flash.now[:alert] = t("flash.destroy.alert",
                            resource_name: @resource.model_name.human.downcase)
        failed_to_save
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
          @tag.instance_variable_set(:@custom_error, :tag_already_assigned)
          return false
        elsif @tag.tagable_type&.present? && @tag.tagable_type != resource_class.name
          # Tag designated for different controller type
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
        flash.now[:alert] = t("flash.create.alert",
                          resource_name: @tag.model_name.human.downcase)
        failed_to_save
        return
      end
    end

    # Existing tag: Create resource from params and update tag with tagable
    def update_tag_with_tagable_resource
      begin
        @tag.update(tagable: @resource)
        flash[:success] = [t('flash.tagables.assigned_to',
                          resource_name: @resource.model_name.human,
                          id: @resource.id,
                          tag: @tag.label)]
        after_create_hook(@resource)
        redirect_after_save
        return
      rescue ActiveRecord::RecordInvalid => _
        # Should not reach here - @tag and @resource have been validated
        flash.now[:alert] = t("flash.create.alert",
                          resource_name: @resource.model_name.human.downcase)
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
                          resource_name: @resource.model_name.human,
                          id: @resource.id,
                          tag: @tag.label)]
        after_create_hook(@resource)
        redirect_after_save
        return
      rescue ActiveRecord::RecordInvalid => _
        # Should not reach here - @tag and @resource have been validated
        flash.now[:alert] = t("flash.create.alert",
                          resource_name: @resource.model_name.human.downcase)
        failed_to_save
      end
    end

    # Update existing tag and resource
    def update_resource
      begin
        @resource.class.transaction do
          @tag = @resource.tag
          @resource.update!(resource_params.except(:tag))
        end
        flash[:success] = [t("flash.update.notice", 
          resource_name: @resource.model_name.human)]
        after_update_hook(@resource)
        redirect_after_save
        return
      rescue ActiveRecord::RecordInvalid
        # Should not reach here - @tag and @resource have been validated
        flash.now[:alert] = t("flash.update.alert",
                          resource_name: @resource.model_name.human.downcase)
        failed_to_save
      end
    end

    # Create new tag and associate with resource
    def create_tag_for_orphan_resource
      begin
        @resource.class.transaction do
          @resource.update!(resource_params.except(:tag))
          @tag = Tag.create!(tag_params.merge(tagable: @resource))
        end
        flash[:success] = [t("flash.tagables.assigned_to", 
          resource_name: @resource.model_name.human,
          id: @resource.id,
          tag: @tag.label)]
        after_update_hook(@resource)
        redirect_after_save
      rescue ActiveRecord::RecordInvalid
        # Should not reach here - @tag and @resource have been validated
        flash.now[:alert] = t("flash.update.alert",
                          resource_name: @resource.model_name.human.downcase)
        failed_to_save
        return
      end
    end

    def setup_form
      instance_variable_set(resource_var_name, @resource)
      @projects = policy_scope(Project)
      @disciplines = policy_scope(Discipline)
        .joins(:project)
        .select('projects.code as project_code, disciplines.id, disciplines.code')
        .order('projects.code ASC, disciplines.code ASC')
        .group_by(&:project_code)
        .transform_values { |discs| discs.map { |d| [d.code, d.id] } }
      
      # Set tag type and discipline according to the resource defaults (if not already set,
      # which could be the case when re-rendering because of parameter errors).
      @tag.tagable_type ||= controller_path.classify
      @tag.discipline ||= Discipline.find_by(code: resource_class.discipline_code)

      # Hook for model-specific form setup
      setup_additional_form_data
    end

    def failed_to_save
      # If we get here, there was a validation error preventing save
      # @resource has been set in the calling action
      # @tag needs to be set also, otherwise setup_form will error
      return_action = @resource.persisted? ? :edit : :new
      setup_form
      respond_to do |format|
        format.html { render return_action, status: :unprocessable_content }
        format.json { render json: @resource.errors, status: :unprocessable_content }
      end
    end

    def redirect_after_save
      respond_to do |format|
        format.html { redirect_to @resource }
        format.json { render :show, status: :created, location: @resource }
      end
    end

    # controller_path returns the namespaced controller class, e.g. Electrical::CablesController
    # classify.constantize converts this to a model class, e.g. Electrical::Cable
    # Use this for creating a new resource matching the calling controller 
    def resource_class
      controller_path.classify.constantize
    end

    # The resource_class provides the model_name methods, e.g. electrical_cables
    # Use resource_path for redirecting to the index action of the calling controller
    def resource_path
      resource_class.model_name.route_key.to_sym
    end

    # Provide the instance variable name expected by resource forms, e.g. @cable
    def resource_var_name
      "@#{resource_class.model_name.element}"
    end

    # Provide the strong parameters name used in resource controllers, which are based on the 
    # model class element, e.g. cable_params
#    def resource_params
#      method_name = "#{resource_class.model_name.element}_params"
#      if respond_to?(method_name, true)
#        send(method_name)
#      else
#        raise NotImplementedError, 
#              "Controller must implement `#{method_name}` method for strong parameters"
#      end
#    end

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
      return nil if params[:tag_id].present?
      if params[:tag].present?
        tag_source = params[:tag]
      elsif params.dig(resource_class.model_name.param_key, :tag).present?
        tag_source = params[resource_class.model_name.param_key][:tag]
      else
        tag_source = {}
      end

      tag_params = tag_source.is_a?(ActionController::Parameters) ?
                  tag_source :
                  ActionController::Parameters.new(tag_source)

      # Permitted parameters
      tag_params.permit(
        :discipline_id, :prefix, :serial, :suffix,
        :service, :stage, :location, :notes, :tagable_id, :tagable_type
      )
    end
end
