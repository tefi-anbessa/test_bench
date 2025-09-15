class CablesController < ApplicationController
  before_action :set_cable, only: %i[ show edit update destroy ]

  # GET /cables or /cables.json
  def index
    @cables = Cable.all.select{ |cable| !cable.tag.nil? }
    @orphans = Cable.all.select{ |cable| cable.tag.nil? }
    @link_errors = Tag.cables.select{ |tag| tag.cable.nil? }
    @link_incomplete = @link_errors.select{ |tag| tag.tagable_id.nil? }
    @link_broken = @link_errors.select{ |tag| !tag.tagable_id.nil? }
    @q = Cable.ransack(params[:q])
    @pagy, @sorted_cables = pagy(@q.result, limit: 10)
  end

  # GET /cables/1 or /cables/1.json
  def show
  end

  # GET /cables/new
  def new
    @cable = Cable.new
  end

  # GET /cables/1/edit
  def edit
  end

  # POST /cables or /cables.json
  def create
    @cable = Cable.new(cable_params)

    respond_to do |format|
      if @cable.save
        format.html { redirect_to @cable, notice: "Cable was successfully created." }
        format.json { render :show, status: :created, location: @cable }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @cable.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /cables/1 or /cables/1.json
  def update
    respond_to do |format|
      if @cable.update(cable_params)
        format.html { redirect_to @cable, notice: "Cable was successfully updated." }
        format.json { render :show, status: :ok, location: @cable }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @cable.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /cables/1 or /cables/1.json
  def destroy
    @cable.destroy

    respond_to do |format|
      format.html { redirect_to cables_path, status: :see_other, notice: "Cable was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_cable
      @cable = Cable.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def cable_params
      params.require(:cable).permit(:cable_type_id, :circuit_id, :load_id, 
        :route_length, :vertical_allowance, :termination_allowance,
        :start_mark, :end_mark)
    end
end
