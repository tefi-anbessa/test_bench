module TagablesController
  extend ActiveSupport::Concern
  included do
    before_action :authenticate_user!
    before_action :require_project!, only: [:new, :create, :edit, :update]
    before_action :set_discipline, only: :index
    before_action :set_resource, only: [:show, :edit, :update, :destroy]
    before_action :set_swatch, only: [:index, :show]
  end

  private

    # Main abstracted methods
    # GET /index - abstracted index action with proper authorization
    # This method will set the resources instance variable (e.g., @motors, @switchboards)
    # in accordance with the policy scope for the resource, ransack seach params, and pagy.
    def index_tagable
      authorize resource_class, :index?
      @q = policy_scope(resource_class).ransack(params[:q])
      result = @q.result.includes(tag: { discipline: :project })
      @pagy, @resources = pagy(result, limit: 20)
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
      set_swatch
    end

    # GET /show - abstracted show action
    def show_tagable
      authorize @resource, :show?
      instance_variable_set(resource_var_name, @resource)
      @neighbours = Navigator.new(scope: @scope, record: @resource).neighbours
    end

    # GET /new - abstracted new action
    def new_tagable
      # set_tag looks for a tag_id in the params.
      # If a valid tag id is found, the action builds a new tagable on the existing tag for the form. 
      # If no tag_id in params, discipline_id is expected, and set_tag builds a new tag on the discipline.
      # The action builds a new resource
      set_tag
      authorize @tag, :new?
      @resource = resource_class.new()
      setup_form
    end

  # POST /switchboards 
    def create_tagable
      # set_tag looks for a tag_id in the params.
      # If a valid tag id is found, the action creates a new tagable on the existing tag. 
      # If no tag_id in params, discipline_id is expected, and the action creates a new resource
      # and new tag on the discipline.
      set_tag
      # Authorize tag to check project (via discipline) against current project context
      authorize @tag, :create? unless @tag.persisted?

      begin
        @resource = resource_class.new(resource_params.except(:tag))
      rescue ArgumentError => _
        # Handle invalid enum values as a conflict
        raise ApplicationController::ConflictError, :invalid_enum
      end

      unless @tag.valid?
        flash.now[:alert] = t("flash.create.alert",
                            resource_name: t("activerecord.models.tag.one").downcase)
        failed_to_save
        return
      end

      authorize @resource, :create?
      unless @resource.valid?
        flash[:alert] = t('flash.create.alert', 
          resource_name: t("activerecord.models.#{resource_class.model_name.i18n_key}.one").downcase)
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
      # [TODO - this won't work at present because without a project association 
      # the action will not be authorised.]
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
                            resource_name: t("activerecord.models.tag.one").downcase)
        failed_to_save
        return
      end

      # Catch enum validation errors
      begin
        @resource.assign_attributes(resource_params.except(:tag))
      rescue ArgumentError => _
        # Handle invalid enum values as a conflict
        raise ApplicationController::ConflictError, :invalid_enum
      end

      unless @resource.valid?
        flash.now[:alert] = t("flash.update.alert",
                            resource_name: t("activerecord.models.#{resource_class.model_name.i18n_key}.one").downcase)
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
        flash[:success] = t('flash.destroy.notice',
                          resource_name: t("activerecord.models.#{resource_class.model_name.i18n_key}.one"))
        redirect_to send("discipline_#{resource_path.to_s}_path", @discipline), 
                    status: :see_other
      else
        flash.now[:alert] = t("flash.destroy.alert",
                            resource_name: t("activerecord.models.#{resource_class.model_name.i18n_key}.one").downcase)
        failed_to_save
      end
    end

    def set_discipline
      @discipline = policy_scope(Discipline).find_by(id: params[:discipline_id])
      raise ApplicationController::ConflictError, :out_of_scope if @discipline.nil?
    end

    def set_resource
      @resource = policy_scope(resource_class).find_by(id: params[:id])
      raise ApplicationController::ConflictError, :out_of_scope if @resource.nil?
      @tag = @resource.tag
      @discipline = @tag.discipline
      @scope = policy_scope(resource_class).joins(tag: { discipline: :project })
    end

    def set_tag
      # Handle case when linking to existing tag through tagable association
      # Uses shallow nested route
      if params[:tag_id].present?
        @tag = policy_scope(Tag).find_by(id: params[:tag_id])
        # Tag not found in current project scope
        raise ApplicationController::ConflictError, 
          :out_of_scope if @tag.nil?
        raise ApplicationController::ConflictError, 
          :tag_already_assigned if @tag.tagable.present?
        raise ApplicationController::ConflictError, 
          :tagable_type_mismatch if @tag.tagable_type&.present? && @tag.tagable_type != resource_class.name
        @discipline = @tag.discipline
      else
        set_discipline
        if tag_params.present?
          # Handle case with tag parameters - [HOLD - how can this be initiated?]
          @tag = @discipline.tags.build(tag_params.merge(tagable_type: controller_path.classify))
        else
          # No tag parameters: new tag and resource
          @tag = @discipline.tags.build(tagable_type: controller_path.classify)
        end
      end
    end

    def set_swatch
      @swatch = @discipline.swatch ||
                resource_class.swatch || 
                Swatch.find_by(name: 'app_theme')
    end

    # Existing tag: Create resource from params and update tag with tagable
    def update_tag_with_tagable_resource
      begin
        @tag.update(tagable: @resource)
        flash[:success] = [t('flash.tagables.assigned_to',
                          resource_name: t("activerecord.models.#{resource_class.model_name.i18n_key}.one"),
                          id: @resource.id,
                          tag: @tag.label)]
        after_create_hook(@resource)
        redirect_after_save
        return
      rescue ActiveRecord::RecordNotUnique
        # Tag already assigned to another resource
        flash.now[:alert] = t("flash.update.alert",
          resource_name: t("activerecord.models.#{resource_class.model_name.i18n_key}.one").downcase)
        @tag.errors.add(:tagable, t("activerecord.errors.models.tag.attributes.tagable_type.taken", 
          tagable_type: resource_class.model_name.human.downcase))
        failed_to_save
      rescue ActiveRecord::RecordInvalid => _
        # Should not reach here - @tag and @resource have been validated
        flash.now[:alert] = t("flash.update.alert",
          resource_name: t("activerecord.models.#{resource_class.model_name.i18n_key}.one").downcase)
        failed_to_save
      end
    end

    # New resource and tag from params
    def create_tag_and_resource
      begin
        @resource.class.transaction do
          # @tag.save!
          @tag.update(tagable: @resource)
        end
        @tag.reload
        flash[:success] = [t('flash.tagables.created_and_assigned',
                          resource_name: t("activerecord.models.#{resource_class.model_name.i18n_key}.one"),
                          id: @resource.id,
                          tag: @tag.label)]
        after_create_hook(@resource)
        redirect_after_save
        return
      rescue ActiveRecord::RecordInvalid => _
        # Should not reach here - @tag and @resource have already been validated
        flash.now[:alert] = t("flash.create.alert",
                          resource_name: t("activerecord.models.#{resource_class.model_name.i18n_key}.one").downcase)
        failed_to_save
      end
    end

    # Update existing tag and resource
    def update_resource
      begin
        @resource.class.transaction do
          @resource.update!(resource_params.except(:tag))
        end
        flash[:success] = [t("flash.update.notice", 
          resource_name: t("activerecord.models.#{resource_class.model_name.i18n_key}.one"))]
        after_update_hook(@resource)
        redirect_after_save
        return
      rescue ActiveRecord::RecordInvalid
        # Should not reach here - @tag and @resource have already been validated
        flash.now[:alert] = t("flash.update.alert",
                          resource_name: t("activerecord.models.#{resource_class.model_name.i18n_key}.one").downcase)
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
          resource_name: t("activerecord.models.#{resource_class.model_name.i18n_key}.one"),
          id: @resource.id,
          tag: @tag.label)]
        after_update_hook(@resource)
        redirect_after_save
      rescue ActiveRecord::RecordInvalid
        # Should not reach here - @tag and @resource have been validated
        flash.now[:alert] = t("flash.update.alert",
                          resource_name: t("activerecord.models.#{resource_class.model_name.i18n_key}.one").downcase)
        failed_to_save
        return
      end
    end

    def setup_form
      instance_variable_set(resource_var_name, @resource)
      @tag.tagable_type ||= controller_path.classify
      set_swatch
      @parents = @tag.prospective_parents(policy_scope(Tag)).order(:discipline_id, :full_tag)
      @schema = @discipline.schema_for_form.with_indifferent_access
      # prefix parts is a hash from parsing the tag prefix against the schema type for the tag's discipline.
      # Used in the prefix build sub form. Nil means prefix is not conforming (may be new tag...)
      @parts = @tag.prefix_parts
      # Hook for model-specific form setup
      setup_additional_form_data
    end

    def failed_to_save
      # If we get here, there was a validation error preventing save
      # @resource has been set in the calling action
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
        :prefix, :serial, :suffix,
        :service, :stage, :location, :notes, :tagable_id, :tagable_type
      )
    end
end
