class TagablesController < ApplicationController

    before_action :authenticate_user!
    before_action :require_project!, only: [:new, :create, :edit, :update]
    before_action :set_tagable, only: [:show, :edit, :update, :destroy]

    # Main abstracted methods
    # GET /index - abstracted index action with proper authorization
    # This method will set the resources instance variable (e.g., @motors, @switchboards)
    # in accordance with the policy scope for the resource, ransack seach params, and pagy.
    def index
      authorize resource_class
      set_index_parent
      @q = @scope.ransack(params[:q])
      result = @q.result.includes(tag: { discipline: :project })
      @pagy, @resources = pagy(result, limit: 20)
      # Separate resources with tags from orphans (resources without tags)
      @resources, @orphans = @resources.partition(&:tag)
      instance_variable_set(resources_var_name, @resources)

      # Find any tags that have tagable_type for this resource but do not have valid tagable.
      @link_errors = policy_scope(Tag).select { |tag| tag.tagable_type == controller_path.classify && tag.tagable.nil? }
      # Separate incomplete links (no tagable_id) from broken links (has tagable_id but missing resource)
      @link_incomplete, @link_broken = @link_errors.partition { |tag| tag.tagable_id.nil? }
      set_swatch
    end

    # GET /tag_tagables
    def show
      authorize @tagable
      instance_variable_set(resource_var_name, @tagable)
      @neighbours = Navigator.new(scope: @scope, record: @tagable).neighbours
      set_swatch
      render template: "#{@resource_class.model_name.collection}/show"
    end

    # GET    (/:locale)/tags/:tag_id/tagable/new or
    # GET    (/:locale)/disciplines/:discipline_id/tagable/new
    def new
      # set_new_parent looks for a tag_id in the params.
      # If a valid tag id is found with a valid tagable_type, the action builds a new tagable on the existing tag for the form, using the tag's tagable_type. 
      # If no tag_id in params, discipline_id and tagable_type are required, and set_form_parent builds a new tag on the discipline.
      set_new_variables
      authorize @tag
      setup_form
      render template: "#{@resource_class.model_name.collection}/new"
    end

  # POST   (/:locale)/tags/:tag_id/tagable or
  # POST   (/:locale)/disciplines/:discipline_id/tagable
    def create
      # set_create_parent looks for a tag_id in the params.
      # If a valid tag id is found, the action creates a new tagable on the existing tag. 
      # If no tag_id in params, discipline_id is expected, and the action creates a new resource
      # and new tag on the discipline.
      set_create_variables
      # Introduce model specific requirements including safe params
      extend_tagable
      begin
        if @parent.is_a?(Discipline)
          @tag = @discipline.tags.build(tag_params.merge(tagable_type: @type))
        end
        @tagable = @tag.build_tagable(tagable_params)

      rescue ArgumentError => _
        # Handle invalid enum values as a conflict
        raise ApplicationController::ConflictError, :invalid_enum
      end
      # Tag permissions apply to tagable
      authorize @tag

      unless @tag.valid?
        flash.now[:alert] = t("flash.create.alert",
                            resource_name: t("activerecord.models.tag.one").downcase)
        failed_to_save
        return
      end

      unless @tagable.valid?
        flash.now[:alert] = t('flash.create.alert', 
          resource_name: @tagable.model_name.human(count: 1).downcase)
        failed_to_save
        return
      end
      
      if @tag.save
        # Flash is an array to allow after_create_hook to add its own messages
        flash[:success] = [t('flash.tagables.created_and_assigned',
                          resource_name: @tagable.model_name.human(count: 1),
                          id: @tagable.id,
                          tag: @tag.label)]
        after_create_hook(@tagable)
        redirect_to @tagable
      else
        # Fallback protection in case something else is wrong
        flash.now[:alert] = t('flash.create.alert', 
          resource_name: @tagable.model_name.human(count: 1).downcase)
        failed_to_save
        return
      end
    end

    # GET    (/:locale)/tags/:tag_id/tagable/edit
    def edit
      authorize @tag
      setup_form
      render template: "#{@resource_class.model_name.collection}/edit"
    end

    # PATCH  (/:locale)/tags/:tag_id/tagable
    def update
      authorize @tag
      # Introduce model specific requirements including safe params
      extend_tagable
      # Catch enum validation errors
      begin
        @tagable.assign_attributes(tagable_params)
      rescue ArgumentError => _
        # Handle invalid enum values as a conflict
        raise ApplicationController::ConflictError, :invalid_enum
      end
      
      if @tag.save
        # Flash is an array to allow after_update_hook to add its own messages
        flash[:success] = [t("flash.update.notice", 
          resource_name: t("activerecord.models.#{@resource_class.model_name.i18n_key}.one"))]
        after_update_hook(@tagable)
        redirect_to @tagable
      else
        # Fallback protection in case something else is wrong
        flash.now[:alert] = t('flash.update.alert', 
          resource_name: @tagable.model_name.human(count: 1).downcase)
        failed_to_save
        return
      end
    end

    # DELETE /:id - abstracted destroy action
    def destroy
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

  private

    def set_index_parent
      if params[:discipline_id].present?
        @parent = @discipline = policy_scope(Discipline).find_by(id: params[:discipline_id])
        raise ApplicationController::ConflictError, :out_of_scope if @discipline.nil?
        @scope = policy_scope(@resource_class).joins(discipline: :project).where(discipline: @discipline)
      elsif params[:project_id].present?
        @discipline = nil
        @parent = @project = policy_scope(Project).find_by(id: params[:project_id])
        raise ApplicationController::ConflictError, :out_of_scope if @project.nil?
        @scope = policy_scope(@resource_class).joins(discipline: :project).where(projects: { id: @project.id })
      else
        @parent = @discipline = @project = nil
        @scope = policy_scope(@resource_class)
      end
    end

    def set_tagable
      @tag = policy_scope(Tag).find_by(id: params[:tag_id])
      raise ApplicationController::ConflictError, :out_of_scope if @tag.nil?
      raise ApplicationController::ConflictError, :out_of_scope if @tag.tagable.nil?
      raise ApplicationController::ConflictError, :invalid_type unless @tag.tagable_type.in?(Tag.safe_tagable_types)
      @tagable = @tag.tagable
      @discipline = @tag.discipline
      @resource_class = @tag.tagable_type.classify.safe_constantize
      @scope = policy_scope(@resource_class).joins(tag: { discipline: :project })
    end

    # For new action
    def set_new_variables
      if params[:tag_id].present?
        # Handle case when linking to existing tag
        set_tag
        @resource_class = @tag.tagable_type.classify.safe_constantize
        @parent = @tag
        @discipline = @tag.discipline
        @tagable = @tag.build_tagable
      else
        # New tag and resource
        set_discipline
        @parent = @discipline
        set_type
        @resource_class = @type.classify.safe_constantize
        @tag = @discipline.tags.build(tagable_type: @type)
        @tagable = @tag.build_tagable
      end
    end

    def set_create_variables
      debugger
      if params[:tag_id].present?
        # Handle case when linking to existing tag
        set_tag
        @parent = @tag
        @discipline = @tag.discipline
        @resource_class = @tag.tagable_type.classify.safe_constantize
        @tagable = @tag.build_tagable(tagable_params)
      else
        # New tag and resource
        set_discipline
        @parent = @discipline
        set_type
        @resource_class = @type.classify.safe_constantize
      end
    end

    def set_tag
      @tag = policy_scope(Tag).find_by(id: params[:tag_id])
      raise ApplicationController::ConflictError, :out_of_scope if @tag.nil?
      raise ApplicationController::ConflictError, :tag_already_assigned if @tag.tagable.present?
      raise ApplicationController::ConflictError, :invalid_type unless @tag.tagable_type.in?(Tag.safe_tagable_types)
    end

    def set_discipline
      raise ApplicationController::ConflictError, :missing_param unless params[:discipline_id].present?
      @discipline = policy_scope(Discipline).find_by(id: params[:discipline_id])
      raise ApplicationController::ConflictError, :out_of_scope if @discipline.nil?
    end

    def set_type
      @type = params[:tagable_type]
      raise ApplicationController::ConflictError, :missing_param unless @type.present?
      raise ApplicationController::ConflictError, :invalid_type unless @type.in?(Tag.safe_tagable_types)
    end

    def set_swatch
      @swatch = @discipline.present? && @discipline.swatch ||
                @resource_class.swatch ||
                @project.present && @project.swatch ||
                Swatch.find_by(name: 'app_theme')
    end

    # Existing tag: Create resource from params and update tag with tagable
    def update_tag_with_tagable_resource
      begin
        @tag.save!
        flash[:success] = [t('flash.tagables.assigned_to',
                          resource_name: t("activerecord.models.#{resource_class.model_name.i18n_key}.one"),
                          id: @tagable.id,
                          tag: @tag.label)]
        after_create_hook(@tagable)
        redirect_to @tagable
        return
      rescue ActiveRecord::RecordNotUnique
        # Tag already assigned to another resource
        flash.now[:alert] = t("flash.update.alert",
          resource_name: t("activerecord.models.#{resource_class.model_name.i18n_key}.one").downcase)
        @tag.errors.add(:tagable, t("activerecord.errors.models.tag.attributes.tagable_type.taken", 
          tagable_type: resource_class.model_name.human.downcase))
        failed_to_save
      rescue ActiveRecord::RecordInvalid => _
        # Should not reach here - @tag and @tagable have been validated
        flash.now[:alert] = t("flash.update.alert",
          resource_name: t("activerecord.models.#{resource_class.model_name.i18n_key}.one").downcase)
        failed_to_save
      end
    end

    # New resource and tag from params
    def create_tag_and_resource
      begin
        @tag.save!
        flash[:success] = [t('flash.tagables.created_and_assigned',
                          resource_name: t("activerecord.models.#{resource_class.model_name.i18n_key}.one"),
                          id: @tagable.id,
                          tag: @tag.label)]
        after_create_hook(@tagable)
        redirect_to @tagable
        return
      rescue ActiveRecord::RecordInvalid => _
        # Should not reach here - @tag and @tagable have already been validated
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
        redirect_to @tagable
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
        redirect_to @tagable
      rescue ActiveRecord::RecordInvalid
        # Should not reach here - @tag and @resource have been validated
        flash.now[:alert] = t("flash.update.alert",
                          resource_name: t("activerecord.models.#{resource_class.model_name.i18n_key}.one").downcase)
        failed_to_save
        return
      end
    end

    def setup_form
      instance_variable_set(resource_var_name, @tagable)
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
      # @tag and @tagable have been set in the calling action
      return_action = @tagable.persisted? ? :edit : :new
      setup_form
      render template: "#{@resource_class.model_name.collection}/#{return_action}"
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
      "@" + @resource_class.model_name.element
    end

    # Provide the instance variable name expected by resource forms, e.g. @cable
    def resources_var_name
      "@" + @resource_class.model_name.element.pluralize
    end

    # Override to specify model-specific form setup
    def setup_additional_form_data
      # Override in model specific controller for model-specific setup
    end

    # Override to specify model-specific post-creation logic
    def after_create_hook(resource)
      # Override in subclass for model-specific logic (e.g., circuits creation)
    end

    # Override to specify model-specific post-update logic
    def after_update_hook(resource)
      # Override in subclass for model-specific logic
    end

    def extend_tagable
      extension = "#{@resource_class.name}Extension".safe_constantize
      extend extension if extension
    end

    def tag_params
      params.require(@resource_class.model_name.param_key)
            .require(:tag)
            .permit(
              :stage,
              :prefix,
              :serial,
              :suffix,
              :service,
              :location,
              :notes
            )
    end
end
