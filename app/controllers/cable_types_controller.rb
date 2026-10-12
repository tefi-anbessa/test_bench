class CableTypesController < ApplicationController
  before_action :authenticate_user!
  before_action :require_project!, only: [:new, :create, :edit, :update]
  before_action :set_discipline, only: [:index, :new, :create]
  before_action :set_cable_type, only: [:show, :edit, :update, :destroy]
  before_action :set_swatch, only: [:index, :show]

  # GET /cable_types or /cable_types.json
  def index
    authorize CableType
    @q = @scope.ransack(params[:q])
    @pagy, @cable_types = pagy(@q.result.includes(:cables, :detail, discipline: :project))
    # One cable_type per discipline present on this page is enough to
    # compute permissions for every row of that discipline - see
    # ApplicationController#permissions_by_group.
    probes = @cable_types.group_by(&:discipline_id).except(nil).transform_values(&:first)
    @permissions = permissions_by_group(probes)
  end

  # GET /cable_types/1 or /cable_types/1.json
  def show
    authorize @cable_type
    @neighbours = Navigator.new(scope: @scope, record: @cable_type).neighbours
  end

  # GET /cable_types/new
  def new
    @cable_type = @discipline.cable_types.build
    build_detail
    authorize @cable_type
    setup_form
  end

  # POST /cable_types or /cable_types.json
  def create
    @cable_type = @discipline.cable_types.build
    build_detail
    begin
      @cable_type.assign_attributes(cable_type_params)
    rescue ArgumentError => _
      # Handle invalid enum values as a conflict
      raise ApplicationController::ConflictError, :invalid_enum
    end
    authorize @cable_type
    if @cable_type.save
      flash[:success] = t('flash.create.notice', resource_name: t("activerecord.models.cable_type.one"))
      redirect_to @cable_type
    else
      flash[:alert] = t('flash.create.alert', resource_name: t("activerecord.models.cable_type.one").downcase)
      setup_form
      render :new, status: :unprocessable_content
    end
  end

  # GET /cable_types/1/edit
  def edit
    authorize @cable_type
    setup_form
  end

  # PATCH/PUT /cable_types/1 or /cable_types/1.json
  def update
    authorize @cable_type
    begin
      @cable_type.assign_attributes(cable_type_params)
    rescue ArgumentError => _
      # Handle invalid enum values as a conflict
      raise ApplicationController::ConflictError, :invalid_enum
    end
    if @cable_type.save
      flash[:success] = t('flash.update.notice', resource_name: t("activerecord.models.cable_type.one"))
      redirect_to @cable_type
    else
      flash[:alert] = t('flash.update.alert', resource_name: t("activerecord.models.cable_type.one").downcase)
      setup_form
      render :edit, status: :unprocessable_entity
    end
  end

  # DELETE /cable_types/1 or /cable_types/1.json
  def destroy
    authorize @cable_type
    if @cable_type.destroy
      flash[:success] = t('flash.destroy.notice', resource_name: t("activerecord.models.cable_type.one"))
      redirect_to discipline_cable_types_path(@discipline), status: :see_other
    else
      flash[:alert] = t('flash.destroy.alert', resource_name: t("activerecord.models.cable_type.one").downcase)
      redirect_to discipline_cable_types_path(@discipline), status: :see_other
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.

    def set_discipline
      if params[:discipline_id].present?
        @discipline = policy_scope(Discipline).find_by(id: params[:discipline_id])
        raise ApplicationController::ConflictError, :out_of_scope if @discipline.nil?
        @scope = policy_scope(CableType).where(discipline_id: @discipline.id)
      elsif params[:project_id].present?
        @discipline = nil
        @project = policy_scope(Project).find_by(id: params[:project_id])
        raise ApplicationController::ConflictError, :out_of_scope if @project.nil?
        @scope = policy_scope(CableType).where(discipline_id: @project.disciplines.pluck(:id))
      end
    end

    def set_cable_type
      @cable_type = policy_scope(CableType).find_by(id: params[:id])
      raise ApplicationController::ConflictError, :out_of_scope if @cable_type.nil?
      @discipline = @cable_type.discipline
      @scope = policy_scope(CableType).where(discipline_id: @discipline.id).joins(discipline: :project)
    end

    def set_swatch
      @swatch = @discipline&.swatch || @project&.swatch || Swatch.find_by(name: "app_theme")
    end

    def setup_form
      @csa_select = Constants.cable.conductor_csa
      set_swatch
    end

    # A cable type's detail subtype is fixed by its discipline, not chosen
    # on the form - build the right concrete type up front so the nested
    # detail_attributes in cable_type_params have something to apply to.
    def build_detail
      detail_class = @discipline.cable_type_detail_class
      raise ApplicationController::ConflictError, :out_of_scope if detail_class.nil?
      @cable_type.detail = detail_class.new
    end

    # Only allow a list of trusted parameters through. detail_attributes
    # is the union of every discipline's own detail fields - only the
    # ones belonging to this cable type's actual detail_type are ever
    # meaningfully submitted, since the form only renders those.
    def cable_type_params
      params.require(:cable_type).permit(
        :primary_role, :conductor_material, :groups, :construction, :csa,
        :insulation, :bedding, :armour, :sheath, :bedding_od, :overall_od,
        :temperature_rating, :voltage_rating, :fire_protection,
        :environment_protection, :applicable_standard, :notes,
        detail_attributes: [:neutral_csa, :earth_csa, :individual_screen, :overall_screen, :twist_pitch]
      )
    end
end
