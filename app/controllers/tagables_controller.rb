class TagablesController < ApplicationController

    before_action :authenticate_user!
    before_action :require_project!, only: [:new, :create, :edit, :update]
    before_action :set_tagable, only: [:show, :edit, :update, :destroy]

    # Main abstracted methods
    # GET /index - abstracted index action with proper authorization
    # This method will set the resources instance variable (e.g., @motors, @switchboards)
    # in accordance with the policy scope for the resource, ransack seach params, and pagy.
    def index
      set_discipline
      set_type
      authorize @resource_class
      @scope = policy_scope(@resource_class)
        .joins(:tag)
        .where(tags: { discipline_id: @discipline.id })
      @q = @scope.ransack(params[:q])
      result = @q.result.includes(tag: { discipline: :project })
      @pagy, @resources = pagy(result, limit: 20)
      # Separate resources with tags from orphans (resources without tags)
      @resources, @orphans = @resources.partition(&:tag)
      instance_variable_set(resources_var_name, @resources)
      # Find any tags that have tagable_type for this resource but do not have valid tagable.
      @link_errors = policy_scope(Tag).select { |tag| tag.tagable_type == @resource_class.name && tag.tagable.nil? }
      # Separate incomplete links (no tagable_id) from broken links (has tagable_id but missing resource)
      @link_incomplete, @link_broken = @link_errors.partition { |tag| tag.tagable_id.nil? }
      set_swatch
      render template: "#{@resource_class.model_name.collection}/index"
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
      # set_form_variables looks for a tag_id in the params.
      # If a valid tag id is found with a valid tagable_type, the action builds a new tagable on the existing tag for the form, using the tag's tagable_type. 
      # If no tag_id in params, discipline_id and tagable_type are required, and set_form_parent builds a new tag on the discipline.
      set_form_variables
      authorize @tag
      @tagable = @tag.build_tagable
      setup_form
      render template: "#{@resource_class.model_name.collection}/new"
    end

  # POST   (/:locale)/tags/:tag_id/tagable or
  # POST   (/:locale)/disciplines/:discipline_id/tagable
    def create
      # set_create_variables looks for a tag_id in the params.
      # If a valid tag id is found, it is used as the parent, and the tagable type sets the resource_class. 
      # If there is no tag_id in params, discipline_id and tagabole_type params are expected.
      # Parent is set to the discipline, and the type sets the resource class.
      set_form_variables
      # From resource class, extend the controller with model specific requirements including safe params
      extend_tagable
      begin
        if @parent.is_a?(Discipline)
          @tag = @discipline.tags.build(tag_params.merge(tagable_type: @type))
        end
        @tagable = @resource_class.new(tagable_params)

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
      @tag.tagable = @tagable
      if @tag.save
        message = @parent.is_a?(Tag) ?
          t('flash.tagables.assigned_to', resource_name: t("activerecord.models.#{@resource_class.model_name.i18n_key}.one"), id: @tagable.id, tag: @tag.label) :
          t('flash.tagables.created_and_assigned', resource_name: t("activerecord.models.#{@resource_class.model_name.i18n_key}.one"), id: @tagable.id, tag: @tag.label)
        # Flash is an array so that after_create_hook can add its own messages
        flash[:success] = [message]
        after_create_hook(@tagable)
        redirect_to tag_tagable_path(@tag)
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
      
      if @tagable.save
        # Flash is an array to allow after_update_hook to add its own messages
        flash[:success] = [t("flash.update.notice", 
          resource_name: t("activerecord.models.#{@resource_class.model_name.i18n_key}.one"))]
        after_update_hook(@tagable)
        redirect_to tag_tagable_path(@tag)
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
      authorize @tag
      type = @tag.tagable_type
      if @tagable.destroy
        flash[:success] = t('flash.destroy.notice',
                          resource_name: t("activerecord.models.#{@resource_class.model_name.i18n_key}.one"))
        redirect_to discipline_tagables_path(@discipline, tagable_type: type), 
                    status: :see_other
      else
        flash.now[:alert] = t("flash.destroy.alert",
                            resource_name: t("activerecord.models.#{@resource_class.model_name.i18n_key}.one").downcase)
        failed_to_save
      end
    end

  private

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
    def set_form_variables
      if params[:tag_id].present?
        # Handle case when linking to existing tag
        set_tag
        @resource_class = @tag.tagable_type.classify.safe_constantize
        @parent = @tag
        @discipline = @tag.discipline
      else
        # New tag and resource
        set_discipline
        @parent = @discipline
        set_type
        @tag = @discipline.tags.build(tagable_type: @type)
      end
    end

    def set_create_variables
      if params[:tag_id].present?
        # Handle case when linking to existing tag
        set_tag
        @parent = @tag
        @discipline = @tag.discipline
        @resource_class = @tag.tagable_type.classify.safe_constantize
      else
        # New tag and resource
        set_discipline
        @parent = @discipline
        set_type
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
      @resource_class = @type.classify.safe_constantize
    end

    def set_swatch
      @swatch = @discipline.present? && @discipline.swatch ||
                @resource_class.swatch ||
                @project.present && @project.swatch ||
                Swatch.find_by(name: 'app_theme')
    end

    def setup_form
      # instance_variable_set(resource_var_name, @tagable)
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
