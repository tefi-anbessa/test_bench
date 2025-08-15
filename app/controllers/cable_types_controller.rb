class CableTypesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_cable_type, only: %i[ show edit update destroy ]

  # GET /electrical/cable_types or /electrical/cable_types.json
  def index
    @q = CableType.ransack(params[:q])
    @pagy, @cable_types = pagy(@q.result.includes(:cables), limit: 10)
  end

  # GET /electrical/cable_types/1 or /electrical/cable_types/1.json
  def show
  end

  # GET /electrical/cable_types/new
  def new
    @cable_type = authorize CableType.new
  end

  # GET /electrical/cable_types/1/edit
  def edit
    authorize @cable_type
  end

  # POST /electrical/cable_types or /electrical/cable_types.json
  def create
    @cable_type = authorize CableType.new(cable_type_params)

    respond_to do |format|
      if @cable_type.save
        format.html { redirect_to @cable_type,
          notice: "Cable type was successfully created." }
        format.json { render :show, status: :created,
          location: @cable_type }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @cable_type.errors,
          status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /electrical/cable_types/1 or /electrical/cable_types/1.json
  def update
    authorize @cable_type
    respond_to do |format|
      if @cable_type.update(cable_type_params)
        format.html { redirect_to @cable_type,
          notice: "Cable type was successfully updated." }
        format.json { render :show, status: :ok,
          location: @cable_type }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @cable_type.errors,
          status: :unprocessable_entity }
      end
    end
  end

  # DELETE /electrical/cable_types/1 or /electrical/cable_types/1.json
  def destroy
    authorize @cable_type
    @cable_type.destroy
    respond_to do |format|
      format.html { redirect_to cable_types_path,
        status: :see_other, notice: "Cable type was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_cable_type
      @cable_type = CableType.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def cable_type_params
      params.require(:cable_type).permit(:conductor_material,
        :conductor_makeup, :csa, :neutral_csa, :earth_csa, :insulation,
        :bedding, :armour, :sheath, :bedding_od, :overall_od,
        :temperature_rating)
    end
end
