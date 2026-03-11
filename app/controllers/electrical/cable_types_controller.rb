module Electrical
  class CableTypesController < ApplicationController
    before_action :authenticate_user!
    before_action :set_cable_type, only: %i[show edit update destroy]
    before_action :set_project, only: %i[index new create]

    # GET /electrical/cable_types or /electrical/cable_types.json
    def index 
      if @project
        @q = policy_scope(@project.electrical_cable_types).ransack(params[:q])
      else
        @q = policy_scope(Electrical::CableType).ransack(params[:q])
      end
      @pagy, @cable_types = pagy(@q.result.includes(:electrical_cables), limit: 10)
      authorize @cable_types
    end

    # GET /electrical/cable_types/1 or /electrical/cable_types/1.json
    def show
      authorize @cable_type
    end

    # GET /electrical/cable_types/new
    def new
      if @project
        @cable_type =  @project.electrical_cable_types.new
      else
        @cable_type =  Electrical::CableType.new
      end
      authorize @cable_type
      setup_form
    end

    # POST /electrical/cable_types or /electrical/cable_types.json
    def create
      if @project
        @cable_type = @project.electrical_cable_types.new(cable_type_params)
      else
        @cable_type = Electrical::CableType.new(cable_type_params)
      end
      authorize @cable_type
      if @cable_type.save
        flash[:success] = t('flash.create.notice', resource_name: @cable_type.model_name.human)
        redirect_to @cable_type
      else
        flash[:alert] = t('flash.create.alert', resource_name: @cable_type.model_name.human)
        render :new, status: :unprocessable_entity
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
      if @cable_type.update(cable_type_params)
        flash[:success] = I18n.t('flash.update.notice', resource_name: @cable_type.model_name.human)
        redirect_to @cable_type
      else
        flash[:alert] = I18n.t('flash.update.alert', resource_name: @cable_type.model_name.human.downcase)
        render :edit, status: :unprocessable_entity
      end
    end

    # DELETE /electrical/cable_types/1 or /electrical/cable_types/1.json
    def destroy
      authorize @cable_type
      project = @cable_type.project
      if @cable_type.destroy
        flash[:success] = t('flash.destroy.notice', resource_name: @cable_type.model_name.human)
        redirect_to project_electrical_cable_types_path(project), status: :see_other
      else
        flash[:alert] = t('flash.destroy.alert', resource_name: @cable_type.model_name.human)
        redirect_to project_electrical_cable_types_path(project), status: :see_other
      end
    end

    private
      # Use callbacks to share common setup or constraints between actions.
      def set_cable_type
        @cable_type = Electrical::CableType.find(params[:id])
      end

      def set_project
        if params[:project_id].present?
          @project = Project.find(params[:project_id])
        else
          @project = current_project
        end
      end

      def setup_form
        @projects = policy_scope(Project)
        @conductor_select = Electrical::CableType.conductor_materials
        @csa_select = Constants.electrical.conductor_csa
        @insulation_select = Electrical::CableType.insulations
        @armour_select = Electrical::CableType.armours
        @temperature_select = Electrical::CableType.temperature_ratings
        @voltage_select = Electrical::CableType.voltage_ratings
      end

      # Only allow a list of trusted parameters through.
      def cable_type_params
        params.require(:electrical_cable_type).permit(
          :conductor_material, :cores, :csa, :neutral_csa, :earth_csa, 
          :insulation, :bedding, :armour, :sheath, :bedding_od, :overall_od,
          :temperature_rating, :voltage_rating, :project_id, :notes, :submit
        )
      end
  end
end