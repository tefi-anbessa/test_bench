class ProjectsController < ApplicationController
  include PageSizeable
  include RolesHelper
  
  before_action :get_project, only: %i[ show edit update destroy ]
  before_action :set_project, only: %i[ set ]
  before_action :authenticate_user!
  before_action :ensure_html_format, except: [:show] # or any actions where you want to allow

  # GET /projects or /projects.json
  def index
    @q = policy_scope(Project).ransack(params[:q])
    @pagy, @projects = pagy(@q.result.ordered, limit: 20)
    authorize @projects
  end

  # GET /projects/1 or /projects/1.json
  def show
    @project = Project.includes(:disciplines).find(params[:id])
    @q = @project.disciplines.ransack(params[:q])
    @pagy, @disciplines = pagy(@q.result, items: 10)
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
      flash[:success] = I18n.t('flash.create.notice', resource_name: I18n.t('activerecord.models.project'))
      redirect_to @project
    else
      flash.now[:alert] = I18n.t('flash.create.alert', resource_name: I18n.t('activerecord.models.project'))
      render :new, status: :unprocessable_content
    end
  end

  # GET /projects/1/edit
  def edit
    authorize @project
    
    # Set up role assignment form if user has permission
    if policy(@project).edit?
      setup_role_assignment(@project)
      @role_return_path = project_path(@project)
    end
    
    respond_to do |format|
      format.html
      format.json { render json: @project }
    end
  end

  # PATCH/PUT /projects/1
  def update
    authorize @project
    
    if @project.update(project_params)
      flash[:success] = I18n.t('flash.update.notice', resource_name: I18n.t('activerecord.models.project'))
      redirect_to @project
    else
      setup_role_assignment(@project)
      flash.now[:alert] = I18n.t('flash.update.alert', resource_name: I18n.t('activerecord.models.project'))
      render :edit, status: :unprocessable_content
    end
  end

  # DELETE /projects/1
  def destroy
    authorize @project
    
    if @project.destroy
        flash[:success] = I18n.t('flash.destroy.notice', resource_name: I18n.t('activerecord.models.project'))
        redirect_to projects_url
    else
        flash.now[:danger] = I18n.t('flash.destroy.alert', resource_name: I18n.t('activerecord.models.project'))
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
      redirect_to stored_location_for_project || projects_path,
                  notice: I18n.t('projects.none_selected')
    elsif @project
      # Set the project in both cookie (signed for security) and session
      set_current_project(@project)
      saved_path = stored_location_for_project
      # Clear any stored location for project to prevent redirect loops
      clear_stored_location_for_project
      flash[:success] = I18n.t('projects.selected', code: @project.code)
      redirect_to saved_path || projects_path
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
    
    # Only allow a list of trusted parameters through.
    def project_params
      params.require(:project).permit(:code, :title, :description, :submit)
    end
end
