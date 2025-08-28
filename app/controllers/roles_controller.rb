class RolesController < ApplicationController
  
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
    @pagy, @roles = pagy(policy_scope(Role).joins(:users), limit: 20)
    authorize @roles
  end

  # GET /roles/new
  def new
    @role = Role.new # Required as vehicle for error_messages
    authorize @role
    @users = User.all
    Rails.application.eager_load! if Rails.env.development?
    @resources = Rolify.resource_types.uniq
  end

  # POST /roles or /roles.json
  def create
    @role = Role.new # For policy authorization
    authorize @role
    
    if @user
      # Check if trying to manage admin/app_owner roles
      if %i[admin app_owner].include?(@name) && !current_user.is_app_owner?
        flash[:danger] = I18n.t('flash.roles.insufficient_permissions')
        return redirect_back_or_to root_path, status: :forbidden
      end
      
      case role_type
      when 'global'
        target = nil
      when 'resource_wide'
        target = @resource_type_class
      when 'resource_instance'
        target = @resource
      end
      
      if @user.grant(@name, target)
        flash[:success] = I18n.t('flash.roles.granted', role_type: role_type_name)
        redirect_to resource_return_path
      else
        flash[:danger] = I18n.t('flash.roles.failed_to_grant', role_type: role_type_name)
        redirect_back_or_to @resource_return_path, status: :unprocessable_entity
      end
    else
      handle_user_not_found
    end
  end

  # DELETE /roles/1 or /roles/1.json
  def destroy
    authorize @role
    
    if @user
      # Check if trying to manage admin/app_owner roles
      if %i[admin app_owner].include?(@role.name.to_sym) && !current_user.is_app_owner?
        flash[:danger] = I18n.t('flash.roles.insufficient_permissions')
        return redirect_back_or_to root_path, status: :forbidden
      end
      
      target = nil
      if @role.resource_id
        target = @resource
      elsif @role.resource_type
        target = @role.resource_type.constantize
      end
      
      if @user.revoke(@role.name, target)
        flash[:success] = I18n.t('flash.roles.revoked', role_type: role_type_name)
        redirect_back_or_to resource_return_path
      else
        flash[:danger] = I18n.t('flash.roles.failed_to_revoke', role_type: role_type_name)
        redirect_back_or_to resource_return_path, status: :unprocessable_entity
      end
    else
      handle_user_not_found
    end
  end

  private

    # Only allow a list of trusted parameters through.
    def create_role_params
      params.require(:role).permit(:id, :name, :resource_type, :resource_id, :user_id)
    end

    # Sets up variables from params for role creation
    def get_role_variables_for_create
      @user = User.find(create_role_params[:user_id])
      @name = create_role_params[:name].to_sym
      @resource_type = create_role_params[:resource_type].presence
      
      @resource_id = create_role_params[:resource_id].presence
      
      if @resource_type.present?
        begin
          @resource_type_class = @resource_type.safe_constantize
          raise ActiveRecord::RecordNotFound, @resource_type unless @resource_type_class
          
          if @resource_id.present?
            @resource = @resource_type_class.find(@resource_id)
          end
        rescue NameError
          raise ActiveRecord::RecordNotFound, @resource_type
        end
      end
    end

    # Set up variables from params for role destroy 
    def get_role_variables_for_destroy
      @user = User.find(params[:user_id])
      @role = Role.find(params[:id])
      @resource_type = @role.resource_type.presence
      @resource_id = @role.resource_id.presence
      
      if @resource_type.present? && @resource_id.present?
        begin
          @resource_type_class = @resource_type.safe_constantize
          raise ActiveRecord::RecordNotFound, @resource_type unless @resource_type_class
          @resource = @resource_type_class.find(@resource_id)
        rescue NameError
          raise ActiveRecord::RecordNotFound, @resource_type
        end
      end
    end

    # Returns the type name for flash messages
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
      I18n.t("flash.role_types.#{role_type}")
    end

    def resource_return_path
      if @resource_id
        @resource_return_path = send("edit_#{@resource_type.underscore.singularize}_path", 
                                     @resource_id, locale: I18n.locale)
      else
        @resource_return_path = roles_url(locale: I18n.locale)
      end
    end
    
    # Handle user not found error
    def handle_user_not_found
      flash.now[:danger] = I18n.t('flash.roles.user_not_found')
      redirect_back_or_to(@resource_id ? @resource_return_path : roles_url, 
                         status: :unprocessable_entity)
    end
    
    # Handle not found errors
  def handle_not_found(exception)
    case exception
    when ActiveRecord::RecordNotFound
      if exception.model == 'User'
        flash[:danger] = I18n.t('flash.roles.user_not_found')
        redirect_back_or_to(resource_return_path, status: :not_found)
      else
        flash[:danger] = I18n.t('flash.roles.resource_not_found')
        redirect_to roles_url, status: :not_found
      end
    end
  end
end
