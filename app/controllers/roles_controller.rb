class RolesController < ApplicationController
  include RolesHelper

  before_action :authenticate_user!
  before_action :get_role_variables_for_create, only: %i[create]
  before_action :get_role_variables_for_destroy, only: %i[destroy]
  after_action :verify_authorized, except: :index
  after_action :verify_policy_scoped, only: :index
  rescue_from ActiveRecord::RecordNotFound do |exception|
    if exception.model == 'Role' || exception.message == 'Role'
      flash[:danger] = I18n.t('flash.roles.role_not_found')
      redirect_back_or_to roles_url, status: :not_found
    else
      handle_not_found(exception)
    end
  end


  # GET /roles or /roles.json
  def index
    # Get paginated roles with users
    roles_scope = policy_scope(Role).includes(:users)
    @pagy, @roles = pagy(roles_scope, limit: 20)
    authorize @roles

    # Set up variables for the view
    setup_role_assignment
    @role_return_path = roles_path
    
    # Use helper to prepare roles for display
    @grouped_roles = prepare_roles_for_display(@roles)
    
    respond_to do |format|
      format.html
      format.json { render json: @roles }
    end
  end

  # GET /roles/new
  def new
    @role = Role.new # Required as vehicle for error_messages
    authorize @role
    setup_role_assignment
debugger
  end

  # POST /roles or /roles.json
  def create
    authorize @role

      target = case role_type
               when 'global' then nil
               when 'resource_wide' then @resource_type_class
               when 'resource_instance' then @resource
      end

      if @user.grant(@role_name, target)
        respond_to do |format|
          format.any do
            flash[:success] = I18n.t('rolify.flash.granted', role_type: role_type_name)
            redirect_to @role_return_path
          end
        end
      else
        error_message = I18n.t('rolify.flash.failed_to_grant', role_type: role_type_name)
        respond_to do |format|
          format.any do
            flash[:danger] = error_message
            @users = User.all
            @resources = Rolify.resource_types.uniq
            redirect_back fallback_location: @role_return_path, status: :unprocessable_content
          end
        end
      end
  end

  # DELETE /roles/1 or /roles/1.json
  def destroy
    authorize @role

    target = case role_type
      when 'global' then nil
      when 'resource_wide' then @resource_type_class
      when 'resource_instance' then @resource
    end

    if @user.revoke(@role.name, target)
      # resource_retun_path is a fallback, delete should return to the calling form
      respond_to do |format|
        format.any do
          flash[:success] = I18n.t('rolify.flash.revoked', role_type: role_type_name)
          redirect_to @role_return_path
        end
      end
    else
      flash[:danger] = I18n.t('rolify.flash.failed_to_revoke', role_type: role_type_name)
      redirect_to @role_return_path, status: :unprocessable_content
    end
  end

  private

    # Only allow a list of trusted parameters through.
    def create_role_params
      params.require(:role).permit(:id, :name, :resource_type, :resource_id, :user_id, :role_return_path)
    end

    # Sets up variables from params for role creation
    def get_role_variables_for_create
      @role_return_path = safe_return_path(create_role_params[:role_return_path]) || roles_path
      @role = Role.new
      # Check resource
      @resource_type = create_role_params[:resource_type].presence
      @resource_id = create_role_params[:resource_id].presence

      if @resource_type.present?
        unless Rolify.resource_types.include?(@resource_type)
          # Log security event if resource type doesn't exist or isn't resourcified
          Rails.logger.error("Security event: Attempt to create role on invalid resource: #{@resource_type}")
          # trap invalid resource - trying to create a role on a resource that isn't resourcified.
          trap_forbidden
          return false
        end
        @resource_type_class = @resource_type.safe_constantize

        if @resource_id.present?
          @resource = @resource_type_class.find_by(id: @resource_id)
          # Log security event if resource instance doesn't exist
          unless @resource
            Rails.logger.error("Security event: Attempt to create role on non existent resource instance: #{@resource_type} id #{@resource_id}")
            return trap_forbidden
          end
          @role.resource = @resource
          @role_type = :resource_instance
        else
          @role.resource_type = @resource_type
          @role.resource_id = nil
          @role_type = :resource_wide
        end
      else
        @role.resource_type = nil
        @role.resource_id = nil
        @role_type = :global
      end

      # Check user_id
      @user_id = create_role_params[:user_id].presence
      unless @user_id
        flash[:alert] = I18n.t("rolify.flash.user_id_blank")
        # Return to form with warning - user error (should be caught by required field)
        redirect_back(fallback_location: @role_return_path, status: :unprocessable_content)
        return false
      end

      # Log security event if user doesn't exist
      unless @user = User.find_by(id: @user_id)
        Rails.logger.error("Security event: Attempt to create role for non existent user id: #{@user_id}")
        return trap_forbidden
      end

      # Check name
      @role_name = create_role_params[:name].presence
      unless @role_name.present?
        # Return to form with warning - user error (should be caught by required field)
        flash.now[:alert] = I18n.t("rolify.flash.name_blank")
        redirect_back(fallback_location: @role_return_path, status: :unprocessable_content)
        return false
      end

      @role_name = @role_name.to_sym
      unless Role.valid_role?(@role_name, @resource_type, @resource_id)
        flash.now[:alert] = I18n.t("rolify.flash.name_invalid",
          name: I18n.t("rolify.names.#{@role_name}", default: @role_name.to_s.humanize),
          resource: @resource_type ? 
            I18n.t("activerecord.models.#{@resource_type}.one", default: @resource_type) : 
            I18n.t('rolify.role_types.global')
        )
          # Return to form with warning - user error [TODO] Check whether this should be upgraded to security after
          # the name select is upgraded with only valid names available.
          redirect_back(fallback_location: @role_return_path, status: :unprocessable_content)
        return false
      end

      # Trap if trying to manage admin/app_owner roles, and redirect to forbidden.
      if %i[admin app_owner].include?(@role_name) && !current_user.is_app_owner?
        Rails.logger.error("Security event: Attempt to grant admin role by non app owner: #{current_user.name}")
        return trap_forbidden
      end
      @role.name = @role_name
      true
    end

    # Set up variables from params for role destroy
    def get_role_variables_for_destroy
      @role_return_path = safe_return_path(params[:role_return_path]) || roles_path
      @user = User.find_by(id: params[:user_id])
      # [TODO: Is it possible that orphaned users_role entries exist?
      # If user doesn't exist, revoke method won't work.
      # It may still be possible to destroy the habtm entry for the role.]
      @role = Role.find_by(id: params[:id])
      unless @role
        # trap role not found - trying to destroy non-existent role
        Rails.logger.error("Security event: Attempt to destroy non existent role id: #{params[:id]}")
        return trap_forbidden
      end
      @resource_type = @role.resource_type.presence
      @resource_id = @role.resource_id.presence
      # No checks on the resource type: even if it is non-existent, the role can still be destroyed if it exists.
      if @resource_type.present?
          @resource_type_class = @resource_type.safe_constantize
          if @resource_id.present?
            @resource = @resource_type_class.find(@resource_id)
            @role_type = :resource_instance
          else
            @role_type = :resource_wide
          end
      else
        @role_type = :global
      end

    end

    # Returns the type name for ensuring the correct format of the .grant method
    # [HOLD I also have a @role_type instance variable which I think is simpler]
    def role_type
      if @resource_id.present?
        'resource_instance'
      elsif @resource_type.present?
        'resource_wide'
      else
        'global'
      end
    end

    def role_type_name
      I18n.t("rolify.role_types.#{role_type}")
    end

    # Use safe_return_path
    def role_return_path
      return roles_url(locale: I18n.locale) if @resource_type.blank? || @resource_id.blank?

      resource_class = @resource_type.safe_constantize
      return roles_url(locale: I18n.locale) unless resource_class

      begin
        edit_path = "edit_#{@resource_type.underscore.singularize}_path"
        send(edit_path, @resource_id, locale: I18n.locale)
      rescue NoMethodError, ActionController::UrlGenerationError
        roles_url(locale: I18n.locale)
      end
    end

    # Validates that a return path is safe (relative or same domain)
    def safe_return_path(path)
      return nil if path.blank?

      # Only allow relative paths or paths starting with root path
      uri = URI.parse(path) rescue nil
      return nil unless uri

      # Allow relative paths
      if uri.relative?
        path if path.start_with?('/')
      # Or absolute paths that match our domain
      elsif uri.host == request.host
        path
      end
    rescue URI::InvalidURIError
      nil
    end

    # Return with flash message to the appropriate form for the role type, which should be where the user came from.
    # This is used when there's a controller detected validation error in the form submission.
    def return_to_form
      @role = Role.new # Required as vehicle for validation error_messages [if used]
      # Reset the collection select variables
      @users = User.all
      Rails.application.eager_load! if Rails.env.development?
      @resources = Rolify.resource_types.uniq

      # Set flash message if not already set
      flash[:alert] ||= flash.now[:alert]

      # Use roles_path as the fallback if no return path is specified
      redirect_back(
        fallback_location: @role_return_path.presence || roles_path,
        status: :unprocessable_content
      )
    end

    def trap_forbidden
      respond_to do |format|
        format.html { render 'errors/forbidden', status: :forbidden }
        # format.any  { head :forbidden }  # Simple response for non-HTML formats
      end
      return false
    end

    # Prepare roles for display using the helper method
    def prepare_roles_for_display(roles_scope)
      roles_helper.prepare_roles_for_display(roles_scope)
    end
  
    # Access roles helper methods
    def roles_helper
      @roles_helper ||= Class.new do
        include RolesHelper
        include ActionView::Helpers::TranslationHelper
        include ActionView::Helpers::TextHelper
      end.new
    end
end
