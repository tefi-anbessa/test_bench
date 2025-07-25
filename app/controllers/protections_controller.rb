class ProtectionsController < ApplicationController
  before_action :set_protection, only: %i[ show edit update destroy ]

  # GET /electrical/protections or /electrical/protections.json
  def index
    @protections = Protection.all
  end

  # GET /electrical/protections/1 or /electrical/protections/1.json
  def show
  end

  # GET /electrical/protections/new
  def new
    @protection = Protection.new
  end

  # GET /electrical/protections/1/edit
  def edit
  end

  # POST /electrical/protections or /electrical/protections.json
  def create
    @protection = Protection.new(protection_params)

    respond_to do |format|
      if @protection.save
        format.html { redirect_to @protection, notice: "Protection was successfully created." }
        format.json { render :show, status: :created, location: @protection }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @protection.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /electrical/protections/1 or /electrical/protections/1.json
  def update
    respond_to do |format|
      if @protection.update(protection_params)
        format.html { redirect_to @protection, notice: "Protection was successfully updated." }
        format.json { render :show, status: :ok, location: @protection }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @protection.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /electrical/protections/1 or /electrical/protections/1.json
  def destroy
    @protection.destroy

    respond_to do |format|
      format.html { redirect_to protections_path, status: :see_other, notice: "Protection was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_protection
      @protection = Protection.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def protection_params
      params.require(:protection).permit(:load_id, :device, :poles, :curve, :rating, :elcb, :notes)
    end
end
