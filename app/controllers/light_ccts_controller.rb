class LightCctsController < ApplicationController
  before_action :set_light_cct, only: %i[ show edit update destroy ]

  # GET /light_ccts or /light_ccts.json
  def index
    @light_ccts = LightCct.all
  end

  # GET /light_ccts/1 or /light_ccts/1.json
  def show
  end

  # GET /light_ccts/new
  def new
    @light_cct = LightCct.new
  end

  # GET /light_ccts/1/edit
  def edit
  end

  # POST /light_ccts or /light_ccts.json
  def create
    @light_cct = LightCct.new(light_cct_params)

    respond_to do |format|
      if @light_cct.save
        format.html { redirect_to @light_cct, notice: "Light cct was successfully created." }
        format.json { render :show, status: :created, location: @light_cct }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @light_cct.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /light_ccts/1 or /light_ccts/1.json
  def update
    respond_to do |format|
      if @light_cct.update(light_cct_params)
        format.html { redirect_to @light_cct, notice: "Light cct was successfully updated." }
        format.json { render :show, status: :ok, location: @light_cct }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @light_cct.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /light_ccts/1 or /light_ccts/1.json
  def destroy
    @light_cct.destroy

    respond_to do |format|
      format.html { redirect_to light_ccts_path, status: :see_other, notice: "Light cct was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_light_cct
      @light_cct = LightCct.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def light_cct_params
      params.require(:light_cct).permit(:light_fitting_type, :quantity, :notes)
    end
end
