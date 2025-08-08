class SocketCctsController < ApplicationController
  before_action :set_socket_cct, only: %i[ show edit update destroy ]

  # GET /socket_ccts or /socket_ccts.json
  def index
    @socket_ccts = SocketCct.all
  end

  # GET /socket_ccts/1 or /socket_ccts/1.json
  def show
  end

  # GET /socket_ccts/new
  def new
    @socket_cct = SocketCct.new
  end

  # GET /socket_ccts/1/edit
  def edit
  end

  # POST /socket_ccts or /socket_ccts.json
  def create
    @socket_cct = SocketCct.new(socket_cct_params)

    respond_to do |format|
      if @socket_cct.save
        format.html { redirect_to @socket_cct, notice: "Socket cct was successfully created." }
        format.json { render :show, status: :created, location: @socket_cct }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @socket_cct.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /socket_ccts/1 or /socket_ccts/1.json
  def update
    respond_to do |format|
      if @socket_cct.update(socket_cct_params)
        format.html { redirect_to @socket_cct, notice: "Socket cct was successfully updated." }
        format.json { render :show, status: :ok, location: @socket_cct }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @socket_cct.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /socket_ccts/1 or /socket_ccts/1.json
  def destroy
    @socket_cct.destroy

    respond_to do |format|
      format.html { redirect_to socket_ccts_path, status: :see_other, notice: "Socket cct was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_socket_cct
      @socket_cct = SocketCct.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def socket_cct_params
      params.require(:socket_cct).permit(:socket_type, :quantity)
    end
end
