class ProjectsController < ApplicationController
  include PageSizeable
  
  before_action :get_project, only: %i[ show edit update destroy ]
  before_action :set_project, only: %i[ set ]
  before_action :authenticate_user!
  before_action :ensure_html_format, except: [:show] # or any actions where you want to allow

  # GET /projects or /projects.json
  def index
    @q = Project.ransack(params[:q])
    @q.result.merge(policy_scope(Project))
    @pagy, @projects = pagy_with_page_size(@q.result.ordered)
  end

  # GET /projects/1 or /projects/1.json
  def show
    @project = Project.find(params[:id])
    authorize @project
    
    respond_to do |format|
      format.html
      format.json { render json: @project }
    end

  end

  # GET /projects/new
  def new
    @project = Project.new
    authorize @project
    @roles = Constants.roles.resources[:project] || []
    @users = User.all
  end

  # POST /projects
  def create
    @project = Project.new(project_params)
    authorize @project

    if @project.save
      flash[:success] = I18n.t('flash.actions.create.notice', resource_name: I18n.t('activerecord.models.project'))
      redirect_to @project
    else
      flash.now[:alert] = I18n.t('flash.actions.create.alert', resource_name: I18n.t('activerecord.models.project'))
      render :new, status: :unprocessable_content
    end
  end

  # GET /projects/1/edit
  def edit
    authorize @project
    setup_role_assignment_variables
  end

  # PATCH/PUT /projects/1
  def update
    authorize @project
    
    if @project.update(project_params)
      flash[:success] = I18n.t('flash.actions.update.notice', resource_name: I18n.t('activerecord.models.project'))
      redirect_to @project
    else
      setup_role_assignment_variables
      flash.now[:alert] = I18n.t('flash.actions.update.alert', resource_name: I18n.t('activerecord.models.project'))
      render :edit, status: :unprocessable_content
    end
  end

  # DELETE /projects/1
  def destroy
    authorize @project
    
    if @project.destroy
        flash[:success] = I18n.t('flash.actions.destroy.notice', resource_name: I18n.t('activerecord.models.project'))
        redirect_to projects_url
    else
        flash.now[:danger] = @project.errors.full_messages.join(', ')
        redirect_to projects_url
    end
  end

  # Select and set actions are used to set the persistent current project for the session.
  # Select action shows the list of projects to choose from.
  # Set action sets the current project for the session.
  # GET /projects/select
  def select
    @options = policy_scope(Project)
    # Add a 'No Project' option at the beginning
    @options = [OpenStruct.new(id: 'none', label: 'No Project')] + @options
  end

  # POST /projects/set
  def set
    if params[:project_id] == 'none'
      # Handle 'No Project' selection
      set_current_project(nil)
      # Clear any stored location for project to prevent redirect loops
      # clear_stored_location_for_project
      redirect_to stored_location_for_project || root_path,
                  notice: I18n.t('projects.none_selected')
    elsif @project
      # Set the project in both cookie (signed for security) and session
      set_current_project(@project)
      
      # Clear any stored location for project to prevent redirect loops
      clear_stored_location_for_project
      
      redirect_to stored_location_for_project || @project,
                  notice: I18n.t('projects.selected', code: @project.code)
    else
      # If invalid project is selected
      redirect_to select_projects_path,
                  alert: I18n.t('projects.invalid_selection')
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def get_project
      @project = Project.find(params[:id])
    end

    def set_project
      if policy_scope(Project).pluck(:id).include?(params[:project_id].to_i)
        @project = Project.find(params[:project_id])
      else
        @project = nil
      end
    end

    def ensure_html_format
      return if request.format.html?
      head :not_acceptable
    end
    
    def setup_role_assignment_variables
      @role = Role.new
      @roles = @project.roles
      @available_roles = Constants.roles.resources[:project] || []
      @users = User.all
      @resource_roles = prepare_role_assignment_data(@project)
    end
    
    # Formats role data for the view
    # @param project [Project] the project to get roles for
    # @return [Hash] formatted role data for the view
    def prepare_role_assignment_data(project)
      resource_roles = {}
      
      project.roles.includes(:users).each do |role|
        role.users.each do |user|
          resource_roles[user.id] ||= { name: user.name, roles: [] }
          resource_roles[user.id][:roles] << [role.name, role.id]
        end
      end
      
      resource_roles
    end

    # Only allow a list of trusted parameters through.
    def project_params
      params.require(:project).permit(:code, :title, :description)
    end
end
