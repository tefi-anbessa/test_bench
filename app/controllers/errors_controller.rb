# frozen_string_literal: true

# Handles custom error pages
class ErrorsController < ActionController::Base
  include ActionView::Layouts
  include ActionController::Rendering
  include ActionView::Rendering
  include Rails.application.routes.url_helpers
  include Devise::Controllers::Helpers
  
  # Set the layout
  layout 'error'
  
  # Skip authentication for error pages
  skip_before_action :verify_authenticity_token, raise: false
  
  # Helper methods
  helper_method :current_user, :user_signed_in?
  
  # Simple current_user method for error pages
  def current_user
    @current_user ||= warden.authenticate(scope: :user) if defined?(warden)
  end
  
  # Check if user is signed in
  def user_signed_in?
    !!current_user
  end
  
  # GET /403
  # Custom forbidden page with HAL 9000 and audio
  def forbidden
    @exception = request.env['action_dispatch.exception']
    @status_code = :forbidden
    
    respond_to do |format|
      format.html { render status: :forbidden }
      format.json { render json: { error: 'Forbidden' }, status: :forbidden }
      format.any { head :forbidden }
    end
  end

  # GET /409
  # Conflict error page (e.g., resource already exists, business rule violation)
  def conflict
    @exception = request.env['action_dispatch.exception']
    @status_code = :conflict
    
    respond_to do |format|
      format.html { render status: :conflict }
      format.json { render json: { error: @exception&.message || 'Conflict' }, status: :conflict }
      format.any { head :conflict }
    end
  end
  
  # GET /404
  # Not found error page
  def not_found
    @status_code = :not_found
    
    respond_to do |format|
      format.html { render status: :not_found }
      format.json { render json: { error: 'Not Found' }, status: :not_found }
      format.any { head :not_found }
    end
  end

  # GET /500
  # Internal server error page
  def internal_server_error
    @status_code = :internal_server_error
    
    respond_to do |format|
      format.html { render status: :internal_server_error }
      format.json { render json: { error: 'Internal Server Error' }, status: :internal_server_error }
      format.any { head :internal_server_error }
    end
  end
  
  # GET /422
  # Unprocessable entity error page
  def unprocessable_entity
    @status_code = :unprocessable_entity
    
    respond_to do |format|
      format.html { render status: :unprocessable_entity }
      format.json { render json: { error: 'Unprocessable Entity' }, status: :unprocessable_content }
      format.any { head :unprocessable_content }
    end
  end
end
