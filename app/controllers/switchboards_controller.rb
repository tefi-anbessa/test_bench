class SwitchboardsController < ApplicationController
  before_action :set_tag, only: %i[ new create ]
  before_action :set_switchboard, only: %i[ show edit update destroy ]

  # GET /switchboards or /switchboards.json
  def index
    @switchboards = Switchboard.all
  end

  # GET /switchboards/1 or /switchboards/1.json
  def show
  end

  # GET /switchboards/new
  def new
    @switchboard = @tag.build_tagable()
  end

  # GET /switchboards/1/edit
  def edit
  end

  # POST /switchboards or /switchboards.json
  def create
    @switchboard = Switchboard.new(switchboard_params)

    respond_to do |format|
      if @switchboard.save
        format.html { redirect_to @switchboard,
          notice: "Switchboard was successfully created." }
        format.json { render :show, status: :created, location: @switchboard }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @switchboard.errors,
          status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /switchboards/1 or /switchboards/1.json
  def update
    respond_to do |format|
      if @switchboard.update(switchboard_params)
        format.html { redirect_to @switchboard,
          notice: "Switchboard was successfully updated." }
        format.json { render :show, status: :ok, location: @switchboard }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @switchboard.errors,
          status: :unprocessable_entity }
      end
    end
  end

  # DELETE /switchboards/1 or /switchboards/1.json
  def destroy
    @switchboard.destroy

    respond_to do |format|
      format.html { redirect_to switchboards_path, status: :see_other,
        notice: "Switchboard was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_tag
      @tag = Tag.find(params[:tag_id])
    end

    def set_switchboard
      @switchboard = Switchboard.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def switchboard_params
      params.require(:switchboard).permit(:location, :ingress_protection, 
        :busbar_rating, :busbar_fault_rating, :busbar_fault_duration, 
        :cable_entry, :incomer_protection, :incomer_metering, 
        :neutral_bar_connections, :earth_bar_connections)
    end
end
