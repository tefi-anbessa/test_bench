# frozen_string_literal: true
# This module provides an abstracted controller with no nesting. Use only for system resources.
module ResourcesController
  extend ActiveSupport::Concern
  included do
    before_action :authenticate_user!
    before_action :require_project!, only: [:new, :create, :edit, :update]
    before_action :set_resource, only: [:show, :edit, :update, :destroy]
  end

  private

    # GET /disciplines/1/examples 
    # This method will set the resources instance variable (e.g., @motors, @switchboards)
    # in accordance with the policy scope for the resource, ransack seach params, and pagy.
    def index_resource
      authorize resource_class, :index?
      @q = policy_scope(resource_class).ransack(params[:q])
      result = @q.result
      @pagy, @resources = pagy(result, limit: 20)
      # Set the resources instance variable (e.g., @documents)
      resources_var_name = "@#{controller_name}"
      instance_variable_set(resources_var_name, @resources)
      set_swatch
    end

    # GET /examples/1
    def show_resource
      authorize @resource, :show?
      instance_variable_set(resource_var_name, @resource)
      @neighbours = Navigator.new(scope: @scope, record: @resource).neighbours
      set_swatch
    end

    # GET //disciplines/1/examples/new
    def new_resource
      # Build a new resource to authorize
      @resource = resource_class.new()
      authorize @resource, :new?
      setup_form
    end

  # POST /discipline/1/examples 
    def create_resource
      # Build an empty resource first
      @resource = resource_class.new()
      # Assign attributes, catch invalid enum values
      begin
        @resource.assign_attributes(resource_params)
      rescue ArgumentError => _
        # Handle invalid enum values as a conflict
        raise ApplicationController::ConflictError, :invalid_enum
      end

      authorize @resource, :create?
      if @resource.save
        flash[:success] = t('flash.create.notice', 
          resource_name: t("activerecord.models.#{resource_class.model_name.i18n_key}.one").downcase)
        redirect_to @resource 
      else
        flash[:alert] = t('flash.create.alert', 
          resource_name: t("activerecord.models.#{resource_class.model_name.i18n_key}.one").downcase)
        failed_to_save
        return
      end
      
    end

    # GET /examples/1/edit 
    def edit_resource
      authorize @resource, :edit?
      setup_form
    end

    # PATCH/PUT /examples/1 
    def update_resource
      authorize @resource, :update?

      # Catch enum validation errors
      begin
        @resource.assign_attributes(resource_params)
      rescue ArgumentError => _
        # Handle invalid enum values as a conflict
        raise ApplicationController::ConflictError, :invalid_enum
      end

      if @resource.save
        flash[:success] = t('flash.update.notice', 
          resource_name: t("activerecord.models.#{resource_class.model_name.i18n_key}.one").downcase)
        redirect_to @resource 
      else
        flash[:alert] = t('flash.update.alert', 
          resource_name: t("activerecord.models.#{resource_class.model_name.i18n_key}.one").downcase)
        failed_to_save
        return
      end
    end

    # DELETE /examples/1
    def destroy_resource
      authorize @resource, :destroy?
      if @resource.destroy
        flash[:success] = t('flash.destroy.notice',
                          resource_name: t("activerecord.models.#{resource_class.model_name.i18n_key}.one"))
        redirect_to resource_path, 
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
      @discipline = @resource.discipline
      @scope = policy_scope(resource_class).joins(discipline: :project)
    end

    def set_swatch
      @swatch = @discipline.swatch ||
                resource_class.swatch ||
                @discipline.project.swatch ||
                Swatch.find_by(name: 'app_theme')
    end

    def setup_form
      instance_variable_set(resource_var_name, @resource)
      set_swatch
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

    # controller_path returns the namespaced controller class, e.g. Electrical::MotorsController
    # classify.constantize converts this to a model class, e.g. Electrical::Motor
    # Use this for creating a new resource matching the calling controller 
    def resource_class
      controller_path.classify.constantize
    end

    # The resource_class provides the model_name methods, e.g. electrical_cables
    # Use resource_path for redirecting to the index action of the calling controller
    def resource_path
      "#{resource_class.model_name.route_key}_path}"
    end

    # Provide the instance variable name expected by resource forms, e.g. @cable
    def resource_var_name
      "@#{resource_class.model_name.element}"
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
end
