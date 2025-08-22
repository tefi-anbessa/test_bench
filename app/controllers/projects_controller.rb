class ProjectsController < ApplicationController
  before_action :get_project, only: %i[ show edit update destroy ]
  before_action :set_project, only: %i[ set ]
  before_action :authenticate_user!

  # GET /projects or /projects.json
  def index
    @q = policy_scope(Project).ransack(params[:q])
    # debugger
    @pagy, @projects = pagy(@q.result, limit: 10)
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
                  notice: 'No project is currently selected' #TODO: internationalize
    elsif @project
      # Set the project in both cookie (signed for security) and session
      cookies.signed[:project_id] = { value: @project.id, expires: 1.year.from_now }
      session[:project_id] = @project.id
      
      # Clear any stored location for project to prevent redirect loops
      clear_stored_location_for_project
      
      redirect_to stored_location_for_project || @project,
                  notice: "Project '#{@project.code}' is now selected" #TODO: internationalize
    else
      # If no valid project is selected
      redirect_to select_projects_path,
                  alert: 'Please select a valid project to continue' #TODO: internationalize
    end
  end

  # GET /projects/1 or /projects/1.json
  def show
  end

  # GET /projects/new
  def new
    @project = authorize Project.new
  end

  # GET /projects/1/edit
  def edit
    @role = Role.new
    @roles = Constants.role.name
    @users = User.all
  end

  # POST /projects or /projects.json
  def create
    @project = authorize Project.new(project_params)

    respond_to do |format|
      if @project.save
        flash[:success] = "Project was successfully created." #TODO: internationalize
        redirect_to @project
      else
        flash[:alert] = "Unable to create project" #TODO: internationalize
        render :new, status: :unprocessable_entity 
      end
    end
  end

  # PATCH/PUT /projects/1 or /projects/1.json
  def update
    respond_to do |format|
      if @project.update(project_params)
        format.html { redirect_to @project, notice: "Project was successfully updated." } #TODO: internationalize
        format.json { render :show, status: :ok, location: @project }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @project.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /projects/1 or /projects/1.json
  def destroy
    @project.destroy
    flash[:success] = "Project was successfully destroyed." #TODO: internationalize
    redirect_to projects_url
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
