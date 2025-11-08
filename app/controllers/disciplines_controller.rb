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
    process_prefix_schema

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
    process_prefix_schema
    @discipline.assign_attributes(discipline_params)
    authorize @discipline
    process_prefix_schema
    
    if @discipline.save
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
    
    def process_prefix_schema
      return unless params[:discipline][:prefix_schema].present? || 
                    params[:discipline][:use_standard_schema] == 'true'

      if params[:discipline][:use_standard_schema] == 'true'
        @discipline.prefix_schema = {
      'name' => params[:discipline][:schema],
      'standard' => true
        }
      else
        begin
          custom_schema = JSON.parse(params[:discipline][:prefix_schema])
          schema_name = custom_schema['name']
      
          # Ensure we have a valid schema name
          unless schema_name.present?
            @discipline.errors.add(:prefix_schema, I18n.t('errors.messages.blank'))
            return
          end
      
          # Prevent custom schemas from using standard schema names
          if Constants.prefix_schemata.key?(schema_name.to_sym)
            @discipline.errors.add(:prefix_schema, I18n.t('errors.messages.reserved'))
            return
          end

          @discipline.prefix_schema = {
            'name' => schema_name,
            'type' => params[:discipline][:schema_type],
            'standard' => false,
            'schema' => custom_schema
          }
        rescue JSON::ParserError
          @discipline.errors.add(:prefix_schema, I18n.t('errors.messages.invalid'))
        end
      end
    end

    # Only allow a list of trusted parameters through.
    def discipline_params
      params.require(:discipline).permit(
        :code, :label, :name, :module_name, 
        :sort_order, :notes, :project_id,
        :use_standard_schema,
        :schema_type,
        :custom_schema_name,
        prefix_schema: { 
          name: {}, 
          type: {}, 
          standard: {}, 
          schema: {} 
        }
      )
    end
end
