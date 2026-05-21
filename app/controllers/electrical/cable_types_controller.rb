module Electrical
  class CableTypesController < ApplicationController
    before_action :authenticate_user!
    before_action :require_project!, only: [:new, :create, :edit, :update]
    before_action :set_discipline, only: [:index, :new, :create]
    before_action :set_cable_type, only: [:show, :edit, :update, :destroy]
    before_action :set_swatch, only: [:index, :show]

    # GET /electrical/cable_types or /electrical/cable_types.json
    def index
      @q = @discipline.electrical_cable_types.ransack(params[:q])
      @pagy, @cable_types = pagy(@q.result.includes(:electrical_cables), limit: 10)
      authorize CableType
    end

    # GET /electrical/cable_types/1 or /electrical/cable_types/1.json
    def show
      authorize @cable_type
    end

    # GET /electrical/cable_types/new
    def new
      @cable_type =  @discipline.electrical_cable_types.build()
      authorize @cable_type
      setup_form
    end

    # POST /electrical/cable_types or /electrical/cable_types.json
    def create
      begin
        @cable_type = @discipline.electrical_cable_types.build(cable_type_params)
      rescue ArgumentError => _
        # Handle invalid enum values as a conflict
        raise ApplicationController::ConflictError, :invalid_enum
      end
      authorize @cable_type
      if @cable_type.save
        flash[:success] = t('flash.create.notice', resource_name: t("activerecord.models.electrical.cable_type.one"))
        redirect_to @cable_type
      else
        flash[:alert] = t('flash.create.alert', resource_name: t("activerecord.models.electrical.cable_type.one").downcase)
        setup_form
        render :new, status: :unprocessable_content
      end
    end

    # GET /electrical/cable_types/1/edit
    def edit
      authorize @cable_type
      setup_form
    end

    # PATCH/PUT /electrical/cable_types/1 or /electrical/cable_types/1.json
    def update
      authorize @cable_type
      begin
        @cable_type.assign_attributes(cable_type_params)
      rescue ArgumentError => _
        # Handle invalid enum values as a conflict
        raise ApplicationController::ConflictError, :invalid_enum
      end
      if @cable_type.save
        flash[:success] = t('flash.update.notice', resource_name: t("activerecord.models.electrical.cable_type.one"))
        redirect_to @cable_type
      else
        flash[:alert] = t('flash.update.alert', resource_name: t("activerecord.models.electrical.cable_type.one").downcase)
        setup_form
        render :edit, status: :unprocessable_entity
      end
    end

    # DELETE /electrical/cable_types/1 or /electrical/cable_types/1.json
    def destroy
      authorize @cable_type
      if @cable_type.destroy
        flash[:success] = t('flash.destroy.notice', resource_name: t("activerecord.models.electrical.cable_type.one"))
        redirect_to discipline_electrical_cable_types_path(@discipline), status: :see_other
      else
        flash[:alert] = t('flash.destroy.alert', resource_name: t("activerecord.models.electrical.cable_type.one").downcase)
        redirect_to discipline_electrical_cable_types_path(@discipline), status: :see_other
      end
    end

    private
      # Use callbacks to share common setup or constraints between actions.
      def set_discipline
        @discipline = policy_scope(Discipline).find_by(id: params[:discipline_id])
        raise ApplicationController::ConflictError, :out_of_scope if @discipline.nil?
      end

      def set_cable_type
        @cable_type = policy_scope(Electrical::CableType).find_by(id: params[:id])
        raise ApplicationController::ConflictError, :out_of_scope if @cable_type.nil?
        @discipline = @cable_type.discipline
      end

      def set_swatch
        @swatch = @discipline&.swatch || @discipline&.project.swatch || Electrical::CableType.swatch || Swatch.find-by(name: "app_theme")
      end

      def setup_form
        @csa_select = Constants.electrical.conductor_csa
        set_swatch
      end

      # Only allow a list of trusted parameters through.
      def cable_type_params
        params.require(:electrical_cable_type).permit(
          :conductor_material, :groups, :construction, :csa, :neutral_csa, :earth_csa,
          :insulation, :bedding, :armour, :sheath, :bedding_od, :overall_od,
          :temperature_rating, :voltage_rating, :notes
        )
      end
  end
end