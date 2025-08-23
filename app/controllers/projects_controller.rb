class ProjectsController < ApplicationController
  include PageSizeable
  
  before_action :get_project, only: %i[ show edit update destroy ]
  before_action :set_project, only: %i[ set ]
  before_action :authenticate_user!

  # GET /projects or /projects.json
  def index
    @q = policy_scope(Project).ransack(params[:q])
    @pagy, @projects = pagy_with_page_size(@q.result.ordered)
  end

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
      cookies.delete(:project_id)
      session.delete(:project_id)
      clear_stored_location_for_project
      
      redirect_to stored_location_for_project || root_path,
                  notice: I18n.t('projects.none_selected')
    elsif @project
      # Set the project in both cookie (signed for security) and session
      cookies.signed[:project_id] = { value: @project.id, expires: 1.year.from_now }
      session[:project_id] = @project.id
      
      # Clear any stored location for project to prevent redirect loops
      clear_stored_location_for_project
      
      redirect_to stored_location_for_project || @project,
                  notice: I18n.t('projects.selected', code: @project.code)
    else
      # If no valid project is selected
      redirect_to select_projects_path,
                  alert: I18n.t('projects.invalid_selection')
    end
  end

  # GET /projects/1 or /projects/1.json
  def show
    @project = Project.find(params[:id])
    authorize @project
    
    respond_to do |format|
      format.html
      format.json { render json: @project }
    end
  rescue Pundit::NotAuthorizedError => e
    respond_to do |format|
      format.html do
        flash[:alert] = I18n.t('pundit.unauthorized')
        redirect_to root_path
      end
      format.json { head :forbidden }
    end
  end

  # GET /projects/new
  def new
    @project = Project.new
    authorize @project
    @roles = Constants.roles.resources[:project] || []
    @users = User.all
    
    respond_to do |format|
      format.html
      format.json { head :forbidden }
    end
  rescue Pundit::NotAuthorizedError
    respond_to do |format|
      format.html do
        flash[:alert] = I18n.t('pundit.unauthorized')
        redirect_to root_path
      end
      format.json { head :forbidden }
    end
  end

  # GET /projects/1/edit
  def edit
    authorize @project
    @role = Role.new
    @roles = Constants.roles.resources[:project] || []
    @users = User.all
    
    respond_to do |format|
      format.html
      format.json { head :forbidden }
    end
  rescue Pundit::NotAuthorizedError
    respond_to do |format|
      format.html do
        flash[:alert] = I18n.t('pundit.unauthorized')
        redirect_to root_path
      end
      format.json { head :forbidden }
    end
  end

  # POST /projects or /projects.json
  def create
    @project = Project.new(project_params)
    authorize @project

    respond_to do |format|
      if @project.save
        format.html do 
          flash[:success] = I18n.t('flash.actions.create.notice', resource_name: I18n.t('activerecord.models.project'))
          redirect_to @project
        end
        format.json { render json: @project, status: :created, location: @project }
      else
        format.html do
          flash.now[:alert] = I18n.t('flash.actions.create.alert', resource_name: I18n.t('activerecord.models.project'))
          render :new, status: :unprocessable_entity
        end
        format.json { render json: @project.errors, status: :unprocessable_entity }
      end
    end
  rescue Pundit::NotAuthorizedError
    respond_to do |format|
      format.html do
        flash[:alert] = I18n.t('pundit.unauthorized')
        redirect_to root_path
      end
      format.json { head :forbidden }
    end
  end

  # PATCH/PUT /projects/1 or /projects/1.json
  def update
    authorize @project
    
    respond_to do |format|
      if @project.update(project_params)
        format.html do
          flash[:success] = I18n.t('flash.actions.update.notice', resource_name: I18n.t('activerecord.models.project'))
          redirect_to @project
        end
        format.json { render :show, status: :ok, location: @project }
      else
        format.html do
          flash.now[:alert] = I18n.t('flash.actions.update.alert', resource_name: I18n.t('activerecord.models.project'))
          render :edit, status: :unprocessable_entity 
        end
        format.json { render json: @project.errors, status: :unprocessable_entity }
      end
    end
  rescue Pundit::NotAuthorizedError => e
    respond_to do |format|
      format.html do
        flash[:alert] = I18n.t('pundit.unauthorized')
        redirect_to root_path
      end
      format.json { head :forbidden }
    end
  end

  # DELETE /projects/1 or /projects/1.json
  def destroy
    authorize @project
    
    respond_to do |format|
      if @project.destroy
        format.html { redirect_to projects_url, notice: I18n.t('flash.actions.destroy.notice', resource_name: I18n.t('activerecord.models.project')) }
        format.json { head :no_content }
      else
        format.html do
          flash[:alert] = I18n.t('flash.actions.destroy.alert', resource_name: I18n.t('activerecord.models.project'))
          redirect_to @project
        end
        format.json { render json: { error: I18n.t('flash.actions.destroy.alert', resource_name: I18n.t('activerecord.models.project')) }, status: :unprocessable_entity }
      end
    end
  rescue Pundit::NotAuthorizedError
    respond_to do |format|
      format.html do
        flash[:alert] = I18n.t('pundit.unauthorized')
        redirect_to root_path
      end
      format.json { head :forbidden }
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

    # Only allow a list of trusted parameters through.
    def project_params
      params.require(:project).permit(:code, :title, :description)
    end
end
