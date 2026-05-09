class DisciplinesController < ApplicationController
  include RolesHelper
  before_action :authenticate_user!
  before_action :require_project!, only: %i[ new create edit update]
  before_action :set_project, only: %i[ index new create ]
  before_action :set_discipline, only: %i[ show edit update destroy schema ]
  before_action :setup_discipline_users, only: %i[ show ]
  before_action :validate_required_role, only: %i[ create update ]

  # GET /disciplines or /disciplines.json
  def index
    @q = policy_scope(Discipline).ransack(params[:q])
    @pagy, @disciplines = pagy(@q.result, limit: 20)
    @discipline = @project.disciplines.build()
    authorize @discipline
    @swatch = Swatch.find_by(name: 'app_theme')
  end

  # GET /disciplines/1 or /disciplines/1.json
  def show
    authorize @discipline
  end

  # GET /disciplines/new
  def new
    @discipline = @project.disciplines.build()
    authorize @discipline
    # Set default theme for new discipline
    @swatch = Swatch.find_by(name: 'app_theme')
    setup_form
  end

  # POST /disciplines
  def create
    @discipline = @project.disciplines.build(discipline_params)
    authorize @discipline
    if @discipline.save
      flash[:success] = I18n.t('flash.create.notice', resource_name: I18n.t('activerecord.models.discipline'))
      redirect_to @discipline
    else
      setup_form
      flash.now[:alert] = I18n.t('flash.create.alert', resource_name: I18n.t('activerecord.models.discipline'))
      render :new, status: :unprocessable_content
    end
  end

  # GET /disciplines/1/edit
  def edit
    authorize @discipline
    setup_form
    
    # Set up role assignment form if user has permission
    if policy(@discipline).edit?
      setup_role_assignment(@discipline)
      @role_return_path = discipline_path(@discipline)
    end
  end

  # PATCH/PUT /disciplines/1
  def update
    @discipline.assign_attributes(discipline_params.except(:copy_from_standard))
    authorize @discipline
    
    if @discipline.save
      flash[:success] = I18n.t('flash.update.notice', resource_name: I18n.t('activerecord.models.discipline'))
      redirect_to @discipline
    else
      setup_form
      flash.now[:alert] = I18n.t('flash.update.alert', resource_name: I18n.t('activerecord.models.discipline'))
      render :edit, status: :unprocessable_content
    end
  end

  # DELETE /disciplines/1
  def destroy
    authorize @discipline
    
    if @discipline.destroy
        flash[:success] = I18n.t('flash.destroy.notice', resource_name: I18n.t('activerecord.models.discipline'))
        redirect_to project_disciplines_url(@project)
    else
        flash.now[:alert] = I18n.t('flash.destroy.alert', resource_name: I18n.t('activerecord.models.discipline'))
        redirect_back_or_to project_disciplines_url(@project)
    end
  end

  # GET /discipline/1/schema
  def schema
    return render json: {} unless @discipline.present?
    respond_to do |format|
      format.json { render json: @discipline.schema_for_form }
      format.any { render json: @discipline.schema_for_form }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_project
      unless params[:project_id].to_i == current_project.id
        raise ApplicationController::ConflictError, 
          :out_of_scope
      end
      @project = current_project
    end

    def set_discipline
      @discipline = policy_scope(Discipline).find_by(id: params[:id])
      raise ApplicationController::ConflictError, :out_of_scope if @discipline.nil?
      @project = @discipline.project
      @swatch = @discipline.swatch
    end

    def setup_form
      set_prefix_schema_selection
      @swatch = @discipline.swatch || Swatch.find_by(name: 'app_theme')
      @swatches = policy_scope(Swatch)
    end

    def set_prefix_schema_selection
      if @discipline.prefix_schema.present?
        @prefix_schema_selection = 
          Constants.prefix_schemata.key?(@discipline.prefix_schema['name'].to_sym) ? 
          @discipline.prefix_schema['name'] : 
          'custom'
      else
        @prefix_schema_selection = ''
      end
      @prefix_schema_options = ['custom'] + Constants.prefix_schemata.keys
      @default_prefix_schema_name = @discipline.persisted? ? 
        @discipline.default_prefix_schema_name : 
        t("activerecord.attributes.discipline.default_prefix_schema_name")
      @prefix_schema_types = Constants.prefix_parser_keys
    end
    
    def process_prefix_schema
      return unless discipline_params[:prefix_schema].present?
      @discipline.prefix_schema = discipline_params[:prefix_schema]
    end

    def handle_schema_error(e)
      @discipline.errors.add(:prefix_schema, I18n.t('errors.messages.invalid'))
    end

    def set_swatches
      @swatches = policy_scope(Swatch)
    end

    def validate_required_role
      required_role = params.dig(:discipline, :required_role)
      return if required_role.blank?
      
      unless Role.valid_role?(required_role, "Discipline")
        raise ApplicationController::ConflictError, "Invalid role: #{required_role}"
      end
    end
    
    # Sets up users with roles on this discipline for the show view
    def setup_discipline_users
      @users = User.joins(:roles)
                   .where(roles: { resource_type: 'Discipline', resource_id: @discipline.id })
                   .select('users.*, roles.name as role_name, roles.resource_type, roles.resource_id')
                   .distinct
                   .order(:name)
    end

    # Only allow a list of trusted parameters through.
    def discipline_params
      params.require(:discipline).permit(
        :label, :name, :required_role,
        :sort_order, :notes, :project_id, :swatch_id,
        :prefix_schema
      )
    end
end

