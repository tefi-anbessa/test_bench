class RolesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_create_params, only: %i[ create ]
  before_action :set_destroy_params, only: %i[ destroy ]
  after_action :verify_authorized, except: :index
  after_action :verify_policy_scoped, only: :index

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
    
    if @user # Check user is valid
      if @resource_type.nil? # This is a global role
        if @user.grant @name
          flash[:success] = "Global role was granted."
          redirect_to roles_url
        else
          flash[:danger] = "Failed to grant global role"
          redirect_back_or_to roles_url, status: :unprocessable_entity
        end
      else
        if @resource_id.nil? # This is a resource role
          if @user.grant @name, @resource_type_class
            flash[:success] = "Resource role was granted."
            redirect_to roles_url
          else
            flash[:danger] = "Failed to grant resource role"
            redirect_back_or_to roles_url, status: :unprocessable_entity
          end
        else  # This is a resource instance role
          if @user.grant @name, @resource
            flash[:success] = "Resource instance role was granted."
            redirect_to @resource_return_path
          else
            flash[:danger] = "Failed to grant resource instance role"
            redirect_to @resource_return_path,
                    status: :unprocessable_entity
          end
        end
      end
    else
      flash.now[:danger] = "User not found"
      if @resource_id.nil?
        redirect_back_or_to roles_url, status: :unprocessable_entity
      else
        redirect_back_or_to @resource_return_path, status: :unprocessable_entity
      end
    end
  end

  # DELETE /roles/1 or /roles/1.json
  def destroy
    if @user # Check user is valid
      if @resource_type.nil? # This is a global role
        if @user.revoke @role.name
          flash[:success] = "Global role was revoked"
          redirect_back_or_to roles_url
        else
          flash[:danger] = "Failed to revoke global role"
          redirect_back_or_to roles_url, status: :unprocessable_entity
        end
      else
        if @role.resource_id.nil? # This is a resource role
          if @user.revoke @role.name, @role.resource_type.constantize
            flash[:success] = "Resource role was revoked"
            redirect_back_or_to roles_url
          else
            flash[:danger] = "Failed to revoke resource role"
            redirect_back_or_to roles_url, status: :unprocessable_entity
          end
        else  # This is a resource instance role
          if @user.revoke @role.name, @resource
            flash[:success] = "Resource instance role was revoked"
            redirect_to @resource_return_path
          else
            flash[:danger] = "Failed to revoke resource instance role"
            redirect_back_or_to @resource_return_path, status: :unprocessable_entity
          end
        end
      end
    else
      flash.now[:danger] = "User not found"
      if @resource_id.nil?
        redirect_back_or_to roles_url, status: :unprocessable_entity
      else
        redirect_back_or_to @resource_return_path, status: :unprocessable_entity
      end
    end
  end

  private

    # Only allow a list of trusted parameters through.
    # Separate list for create and destroy actions because destroy is called
    # from a view not a form, and I don't know how to get the helper to set the params correctly.
    def create_role_params
      params.require(:role).permit(:id, :name,
        :resource_type, :resource_id, :user_id)
    end

    # Set instance variables to avoid repeated long winded calls to params.
    def set_create_params
      @user = User.find(create_role_params[:user_id])
      @name = create_role_params[:name].to_sym
      @resource_type = create_role_params[:resource_type]
      if @resource_type.blank?
        @resource_type = nil
      end
      unless @resource_type.nil?
        @resource_type_class = @resource_type.constantize
        @resource_id = create_role_params[:resource_id]
        if @resource_id.blank?
          @resource_id = nil
        end
        unless @resource_id.nil?
          @resource = @resource_type_class.find(@resource_id)
          @resource_return_path = "/edit_#{@resource_type.tableize.singularize}_path(#{@resource_id})"
        end
      end
    end

    # Destroy is called from an index view, not form.
    # The only params are role id and user id.
    # Need to find resource type and index to determine the type of revoke.
    # Can't get safe params to work so using this kludge...
    def set_destroy_params
      @user = User.find(params[:user_id])
      @role = Role.find(params[:id])
      unless @role.resource_type.nil?
        @resource_type = @role.resource_type.constantize
        unless @role.resource_id.nil?
          @resource = @resource_type.find(@role.resource_id)
          @resource_return_path = "/edit_#{@role.resource_type.tableize.singularize}_path(#{@role.resource_id})"
        end
      end
    end
end
