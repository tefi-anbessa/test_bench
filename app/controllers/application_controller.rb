class ApplicationController < ActionController::Base
  include Pundit::Authorization
  include Pagy::Backend
  include CurrentProjectConcern
  include Devise::Controllers::StoreLocation

  around_action :switch_locale
  before_action :configure_permitted_parameters, if: :devise_controller?

  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized
  # rescue_from ActionController::Redirecting::UnsafeRedirectError do
  #   redirect_to root_url
  # end

  def xeqq(sql) # For use in console
    results = ActiveRecord::Base.connection.exec_query(sql)
    results.presence
  end

  # This method is now in CurrentProjectConcern

  protected

  def after_sign_in_path_for(resource)
    # Get all projects the user has access to via roles
    accessible_projects = policy_scope(Project)
    
    case accessible_projects.count
    when 0
      # User has no access to any projects, redirect to user profile
      user_path(resource)
    when 1
      # If only one project, set it as current and proceed
      project = accessible_projects.first
      cookies.signed[:project_id] = { value: project.id, expires: 1.year.from_now }
      session[:project_id] = project.id
      
      # Clear any stored location and redirect to project or stored location
      stored_path = stored_location_for(:project)
      clear_stored_location_for(:project)
      stored_path || project_path(project)
    else
      # Multiple projects available, go to selection
      select_projects_path
    end
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

    def switch_locale(&action)
      locale = params[:locale] || I18n.default_locale
      I18n.with_locale(locale, &action)
    end

    private

    def user_not_authorized
      flash[:alert] = "You are not authorized to perform this action."
      redirect_back_or_to(root_path)
    end
end
