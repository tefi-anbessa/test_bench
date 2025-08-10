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
    @project = Project.new
  end

  # POST /projects/1/set
  def set

    if session[:project] = @project.id
      @current_project = @project
      redirect_to @project
    else
      flash[:warning] = "Invalid project selected"
      redirect_to select_projects_path
    end
  end

  # GET /projects/1 or /projects/1.json
  def show
  end

  # GET /projects/new
  def new
    @project = Project.new
  end

  # GET /projects/1/edit
  def edit
    @role = Role.new
    @roles = Constants.role.name
    @users = User.all
  end

  # POST /projects or /projects.json
  def create
    @project = Project.new(project_params)

    respond_to do |format|
      if @project.save
        format.html { redirect_to @project, notice: "Project was successfully created." }
        format.json { render :show, status: :created, location: @project }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @project.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /projects/1 or /projects/1.json
  def update
    respond_to do |format|
      if @project.update(project_params)
        format.html { redirect_to @project, notice: "Project was successfully updated." }
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

    respond_to do |format|
      format.html { redirect_to projects_path, status: :see_other, notice: "Project was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def get_project
      @project = Project.find(params[:id])
    end

    def set_project
      @project = Project.find(params[:project_id])
    end

    # Only allow a list of trusted parameters through.
    def project_params
      params.require(:project).permit(:code, :title, :description)
    end
end
