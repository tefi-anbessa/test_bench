module TagablesController
  extend ActiveSupport::Concern

  included do
    before_action :authenticate_user!
  end

  # Configuration methods that subclasses should override
  private

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
  def after_create_hook
    # Override in subclass for model-specific logic (e.g., circuits creation)
  end

  # Override to specify model-specific post-update logic
  def after_update_hook
    # Override in subclass for model-specific logic
  end

  # Main abstracted methods
  def create_tagable
    resource_name = controller_name.singularize.to_sym

    # For create action, we need to create a new resource
    resource_class = controller_name.classify.constantize

    begin
      @resource = resource_class.new(send("#{resource_name}_params").except(:tag))
    rescue ArgumentError => e
      # Handle invalid enum values as a conflict
      raise ApplicationController::ConflictError, :invalid_enum
    end

    authorize @resource
    set_tag

    handle_create_validation_and_save
  end

  def update_tagable
    resource_name = controller_name.singularize.to_sym

    @resource = instance_variable_get("@#{resource_name}")
    authorize @resource
    @tag = @resource.tag&.present? ? @resource.tag : Tag.new(tag_params.merge(tagable: @resource))

    # Make a dummy resource object for checking params
    begin
      dummy_resource = @resource.dup
      dummy_resource.assign_attributes(send("#{resource_name}_params").except(:tag))
    rescue ArgumentError => e
      # Handle invalid enum values as a conflict
      raise ApplicationController::ConflictError, :invalid_enum
    end

    unless dummy_resource.valid?
      setup_form
      flash.now[:alert] = t("flash.actions.update.alert",
                           resource_name: @resource.class.model_name.human.downcase)
      render :edit, status: :unprocessable_content
      return
    end

    handle_update_transaction
  end

  # GET /new - abstracted new action
  def abstracted_new
    resource_name = controller_name.singularize.to_sym

    resource_class = controller_name.classify.constantize
    resource_var = resource_class.new()
    instance_variable_set("@#{resource_name}", resource_var)

    @resource = resource_var
    authorize @resource
    set_tag
    setup_form
  end

  # GET /edit - abstracted edit action
  def abstracted_edit
    resource_name = controller_name.singularize.to_sym

    @resource = instance_variable_get("@#{resource_name}")
    authorize @resource

    # Allow edit of resource without a tag as a way to rescue orphans
    @tag = @resource.tag&.present? ? @resource.tag : Tag.new(tagable_type: controller_name.classify)
    setup_form
  end

  # DELETE /:id - abstracted destroy action
  def abstracted_destroy
    resource_name = controller_name.singularize.to_sym

    @resource = instance_variable_get("@#{resource_name}")
    authorize @resource
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

  # GET /index - abstracted index action with proper authorization
  def abstracted_index
    resource_name = controller_name.singularize.to_sym
    resource_class = controller_name.classify.constantize

    @q = policy_scope(resource_class).ransack(params[:q])
    @pagy, @resources = pagy(@q.result.includes(:tag), limit: 20)

    # Set the resources instance variable (e.g., @motors, @switchboards)
    resources_var_name = "@#{controller_name}"
    instance_variable_set(resources_var_name, @resources)

    @orphans = @resources.select{ |resource| resource.tag.nil? }

    # Use policy_scope for security - only show tags user has access to
    @link_errors = policy_scope(Tag).select { |tag| tag.tagable_type == controller_name.classify && tag.tagable.nil? }
    @link_incomplete = @link_errors.select{ |tag| tag.tagable_id.nil? }
    @link_broken = @link_errors.select{ |tag| !tag.tagable_id.nil? }

    authorize @resources
  end

  private

  def set_tag
    # Rails.logger.info "tag_params: #{tag_params}"
    # Handle case when linking to existing tag through tagable_id association first
    # Uses shallow nested route
    if params[:tag_id].present?
      @tag = Tag.find_by(id: params[:tag_id])
      if @tag.nil?
        # Tag not found in database
        @tag = Tag.new
        @tag.errors.add(:base, :tag_not_found)
        return false
      elsif @tag.tagable.present?
        # Tag already assigned to a tagable
        @tag = Tag.new
        @tag.errors.add(:base, :tag_already_assigned)
        return false
      elsif @tag.tagable_type&.present? && @tag.tagable_type != controller_name.classify
        # Tag designated for different controller type
        @tag = Tag.new
        @tag.errors.add(:base, :tagable_type_mismatch)
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

  def handle_create_validation_and_save
    resource_name = controller_name.singularize.to_sym

    unless @resource.valid?
      # Ensure the resource variable is set for the view
      resource_var_name = "@#{resource_name}"
      instance_variable_set(resource_var_name, @resource) unless instance_variable_get(resource_var_name)

      setup_form
      flash.now[:alert] = t("flash.actions.create.alert",
                           resource_name: @resource.class.model_name.human.downcase)
      respond_to do |format|
        format.html { render :new, status: :unprocessable_content }
        format.json { render json: @resource.errors, status: :unprocessable_content }
      end
      return
    end

    handle_tag_assignment_for_create
  end

  def handle_tag_assignment_for_create
    resource_name = controller_name.singularize.to_sym

    if @tag.persisted?
      # Existing tag: Create resource and update tag
      @tag.update(tagable: @resource)
      flash[:success] = t('flash.tagables.assigned_to',
                        resource_name: @resource.class.model_name.human,
                        id: @resource.id,
                        tag: @tag.label)
      after_create_hook
      create_success_redirect
      return
    else
      if @tag.errors.none?
        # New tag from tag params
        begin
          @resource.class.transaction do
            @tag.save!
            @tag.update(tagable: @resource)
          end
          @tag.reload
          after_create_hook
          flash[:success] = t('flash.tagables.created_and_assigned',
                            resource_name: @resource.class.model_name.human,
                            id: @resource.id,
                            tag: @tag.label)
          create_success_redirect
          return
        rescue ActiveRecord::RecordInvalid => e
          # Fall through to render :new below
        end
      else
        # tag_id was set but trapped in set_tag
        raise ApplicationController::ConflictError, @tag.errors.first.type
        return
      end
    end

    # If we get here, there was a tag validation error
    # Ensure the resource variable is set for the view before setup_form
    resource_var_name = "@#{resource_name}"
    instance_variable_set(resource_var_name, @resource) unless instance_variable_get(resource_var_name)

    setup_form
    flash.now[:alert] = t("flash.actions.create.alert",
                         resource_name: @resource.class.model_name.human.downcase)
    render :new, status: :unprocessable_content
  end

  def handle_update_transaction
    resource_name = controller_name.singularize.to_sym

    begin
      if @resource.tag&.persisted?
        # Update existing tag and resource
        @resource.class.transaction do
          @tag = @resource.tag
          @tag.update!(tag_params)
          @resource.update!(send("#{resource_name}_params").except(:tag))
          after_update_hook
        end
      else
        # Create new tag and associate with resource
        authorize Tag, :create?
        @resource.class.transaction do
          @tag = Tag.create!(tag_params.merge(tagable: @resource))
          @resource.update!(send("#{resource_name}_params").except(:tag))
          after_update_hook
        end
      end

      flash[:success] = t("flash.actions.update.notice", resource_name: @resource.class.model_name.human)
      respond_to do |format|
        format.html { redirect_to @resource }
        format.json { render :show, status: :ok, location: @resource }
      end

    rescue ActiveRecord::RecordInvalid => e
      # Ensure the resource variable is set for the view before setup_form
      resource_var_name = "@#{resource_name}"
      instance_variable_set(resource_var_name, @resource) unless instance_variable_get(resource_var_name)

      setup_form
      flash.now[:alert] = t("flash.actions.update.alert",
                          resource_name: @resource.class.model_name.human.downcase)
      respond_to do |format|
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @resource.errors, status: :unprocessable_entity }
      end
    rescue Pundit::NotAuthorizedError => e
      flash[:danger] = e.message
      redirect_to @resource
    end
  end

  def setup_form
    if current_project
      @project = current_project
    else
      @project = nil
    end
    @projects = policy_scope(Project)
    @disciplines = Discipline.all.select(:id, :code, :name).to_a

    # Set default tag attributes if tag is not persisted
    unless @tag&.persisted?
      @tag ||= Tag.new(tagable_type: controller_name.classify)
      @tag.discipline ||= Discipline.find_by(code: discipline_code)
      @tag.prefix ||= tag_prefix
    end

    setup_additional_form_data
  end

  def create_success_redirect
    respond_to do |format|
      format.html { redirect_to @resource }
      format.json { render :show, status: :created, location: @resource }
    end
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
