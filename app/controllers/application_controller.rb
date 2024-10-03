class ApplicationController < ActionController::Base

  include Pundit::Authorization
  include Pagy::Backend

  around_action :switch_locale
  before_action :configure_permitted_parameters, if: :devise_controller?

  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized
#  rescue_from ActionController::Redirecting::UnsafeRedirectError do
#    redirect_to root_url
#  end

  def xeqq(sql) # For use in console
    results = ActiveRecord::Base.connection.exec_query(sql)
    if results.present?
      return results
    else
      return nil
    end
  end

  protected

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
