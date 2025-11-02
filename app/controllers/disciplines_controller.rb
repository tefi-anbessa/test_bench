class DisciplinesController < ApplicationController
  include RolesHelper
  before_action :authenticate_user!
  before_action :set_project, only: %i[ index new create ]
  before_action :set_discipline, only: %i[ show edit update destroy ]

  # GET /disciplines or /disciplines.json
  def index
    @q = policy_scope(Discipline).ransack(params[:q])
    @pagy, @disciplines = pagy(@q.result, limit: 20)
    @discipline = @project.disciplines.build()
    authorize @discipline
  end

  # GET /disciplines/1 or /disciplines/1.json
  def show
    authorize @discipline
    
    respond_to do |format|
      format.html
      format.json { render json: @discipline }
    end

  end

  # GET /disciplines/new
  def new
    @discipline = @project.disciplines.build()
    authorize @discipline
  end

  # POST /disciplines
  def create
    @discipline = @project.disciplines.build(discipline_params)
    authorize @discipline

    if @discipline.save
      flash[:success] = I18n.t('flash.actions.create.notice', resource_name: I18n.t('activerecord.models.discipline'))
      redirect_to @discipline
    else
      flash.now[:alert] = I18n.t('flash.actions.create.alert', resource_name: I18n.t('activerecord.models.discipline'))
      render :new, status: :unprocessable_content
    end
  end

  # GET /disciplines/1/edit
  def edit
    authorize @discipline
    
    respond_to do |format|
      format.html
      format.json { render json: @discipline }
    end
  end

  # PATCH/PUT /disciplines/1
  def update
    authorize @discipline
    
    if @discipline.update(discipline_params)
      flash[:success] = I18n.t('flash.actions.update.notice', resource_name: I18n.t('activerecord.models.discipline'))
      redirect_to @discipline
    else
      flash.now[:alert] = I18n.t('flash.actions.update.alert', resource_name: I18n.t('activerecord.models.discipline'))
      render :edit, status: :unprocessable_content
    end
  end

  # DELETE /disciplines/1
  def destroy
    authorize @discipline
    
    if @discipline.destroy
        flash[:success] = I18n.t('flash.actions.destroy.notice', resource_name: I18n.t('activerecord.models.discipline'))
        redirect_to project_disciplines_url(@project)
    else
        flash.now[:danger] = @discipline.errors.full_messages.join(', ')
        redirect_to project_disciplines_url(@project)
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_project
      @project = Project.find(params[:project_id])
    end

    def set_discipline
      @discipline = Discipline.find(params[:id])
      @project = @discipline.project
    end
    
    # Only allow a list of trusted parameters through.
    def discipline_params
      params.require(:discipline).permit(:code, :label, :name, :prefix_schema, :module_name, 
        :sort_order, :notes, :project_id)
    end
end
