class ApplicationController < ActionController::Base
  include Pundit::Authorization
  include Pagy::Backend
  include CurrentProjectConcern
  include Devise::Controllers::StoreLocation
  include ErrorsHelper

  around_action :switch_locale
  before_action :configure_permitted_parameters, if: :devise_controller?
  before_action :set_paper_trail_whodunnit

  # Custom error handling for trapped bad requests
  class ConflictError < StandardError; end
  rescue_from ConflictError, with: :handle_conflict
  
  rescue_from Pundit::NotAuthorizedError do |exception|
    @exception = exception
    respond_to do |format|
      format.html do
        flash[:danger] = I18n.t('pundit.unauthorized',
          action: exception.query.to_s.humanize.downcase,
          objects: exception.record&.model_name&.human&.pluralize&.downcase || 'these resources'
        )
        render 'errors/forbidden', status: :forbidden
      end
      format.json do
        render json: {
          error: I18n.t('pundit.unauthorized',
            action: exception.query.to_s.humanize.downcase,
            objects: exception.record&.model_name&.human&.pluralize&.downcase || 'these resources'
          )
        }, status: :forbidden
      end
    end
  end

  # Handle unknown formats consistently
  rescue_from ActionController::UnknownFormat do
    respond_to do |format|
      format.any { head :not_acceptable }
    end
  end


  # rescue_from ActionController::Redirecting::UnsafeRedirectError do
  #   redirect_to root_url
  # end

  def xeqq(sql) # For use in console
    results = ActiveRecord::Base.connection.exec_query(sql)
    results.presence
  end

  # Override Pundit's default user context
  def pundit_user
    ApplicationPolicy::UserContext.new(current_user, current_project)
  end

  # Helper method to prepare role assignment data for any resource
  # @param resource [ActiveRecord::Base] The resource to get roles for
  # @return [Hash] A hash of role data grouped by user
  def prepare_role_assignment_data(resource)
    return {} unless resource.persisted?
    
    resource.roles
      .joins(:users)
      .select('roles.id as role_id, roles.name as role_name, users.name as user_name, users.id as user_id')
      .order('users.name, roles.name')
      .group_by { |r| [r.user_id, r.user_name] }
      .transform_values { |roles| roles.map { |r| [r.role_name, r.role_id] } }
  end

  protected

    def after_sign_in_path_for(resource)
      project = load_current_project
      # If the current user's project cookie is set,
      # save it to session, update @current_project, and go to project dashboard.
      if project
        set_current_project(project)
        return project_path(project)
      end

      # If no project cookie is set, check if user has exactly one project available
      available_projects = ProjectPolicy::Scope.new(pundit_user, Project).resolve
      if available_projects.count == 1
        project = available_projects.first
        set_current_project(project)
        return project_path(project)
      end

      # Multiple or no projects available, go to projects index to select
      set_current_project(nil)
      projects_path
    end

    def default_url_options
      { locale: I18n.locale }
    end

    def configure_permitted_parameters
      added_attrs = [:name, :email, :password, :password_confirmation, :remember_me]
      devise_parameter_sanitizer.permit :sign_up, keys: added_attrs
      devise_parameter_sanitizer.permit :sign_in, keys: [:login, :password]
      devise_parameter_sanitizer.permit :account_update, keys: added_attrs
    end

    def info_for_paper_trail
      { ip: request.remote_ip, user_agent: request.user_agent, current_project_id: current_project&.id }
    end

    def switch_locale(&action)
      locale = params[:locale] || I18n.default_locale
      I18n.with_locale(locale, &action)
    end

  private

    def handle_conflict(exception)
      # Log security incident
      Rails.logger.warn(
        "Security: ConflictError raised - " \
        "Message: #{exception.message}, " \
        "Controller: #{controller_name}, " \
        "Action: #{action_name}, " \
        "User: #{current_user&.id}"
      )

      # Handle symbol translation
      error_message = exception.message
      if error_message.is_a?(Symbol)
        error_message = I18n.t("errors.#{error_message}", default: error_message.to_s)
      end

      respond_to do |format|
        format.html do
          flash[:alert] = error_message || I18n.t('errors.conflict.subheader')
          render 'errors/conflict', status: :conflict
        end
        format.json do
          render json: { error: error_message || I18n.t('errors.conflict.header') }, 
                status: :conflict
        end
      end
    end
end
