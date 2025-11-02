class SwitchboardsController < ApplicationController
  include TagablesController
  
  before_action :set_switchboard, only: %i[show edit update destroy]

  # GET /switchboards or /switchboards.json
  def index
    index_tagable
  end

  # GET /switchboards/1 or /switchboards/1.json
  def show
    authorize @switchboard
  end

  # GET /switchboards/new
  def new
    new_tagable
  end

  # POST /switchboards or /switchboards.json
  def create
    create_tagable
  end

  # GET /switchboards/1/edit
  def edit
    edit_tagable
  end

  # PATCH/PUT /switchboards/1 or /switchboards/1.json
  def update
    update_tagable
  end

  # DELETE /switchboards/1 or /switchboards/1.json
  def destroy
    destroy_tagable
  end

  private

  # Switchboard-specific configuration
  def tag_prefix
    "EX"  # Electrical Switchboard
  end

  def discipline_code
    "E"  # Electrical
  end

  def setup_additional_form_data
    @circuits = @switchboard.persisted? ? @switchboard.circuits.count : 0
    @voltage_ratings = Switchboard.voltage_ratings
    @ip_1 = Constants.electrical.ingress_protection.first_digit.to_h
    @ip_2 = Constants.electrical.ingress_protection.second_digit.to_h
  end

  def after_create_hook(switchboard)
    circuits_count = params.dig(:switchboard, :circuits).presence || params[:circuits].presence
    update_circuits(switchboard, circuits_count.to_i) if circuits_count
  end

  def after_update_hook(switchboard)
    circuits_count = params.dig(:switchboard, :circuits).presence || params[:circuits].presence
    update_circuits(switchboard, circuits_count.to_i) if circuits_count
  end

  # Updates the number of circuits for the switchboard
  def update_circuits(switchboard, desired_count = nil)
    return unless desired_count && desired_count > 0

    current_count = switchboard.circuits.count
    count = desired_count - current_count
    if count > 0
      authorize switchboard.circuits.build(), :create?
      
      count.times do |i|
        switchboard.circuits.create(serial: current_count + i + 1)
      end
      resource_name = Circuit.model_name.human(count: count)
      flash[:success] << t("flash.assigned", count: count, resource_name: resource_name)
    elsif count < 0
      authorize switchboard.circuits.build(), :destroy?
      switchboard.circuits
                 .order(serial: :desc)
                 .limit(current_count - desired_count)
                 .destroy_all
      resource_name = Circuit.model_name.human(count: count*-1)
      flash[:success] << t("flash.destroyed", count: count*-1, resource_name: resource_name)
    end
  end

  def set_switchboard
    @switchboard = Switchboard.find(params[:id])
  end

  # Only allow a list of trusted parameters through.
    def switchboard_params
      params.require(:switchboard).permit(:ingress_protection, :voltage_rating,
        :busbar_rating, :busbar_fault_rating, :busbar_fault_duration, 
        :cable_entry, :incomer_protection, :metering, 
        :neutral_bar_connections, :earth_bar_connections, :notes,
        tag: [
          :id, :project_id, :discipline_id, :prefix, :serial, 
          :suffix, :service, :stage, :notes, :tagable_type
        ])
    end
end
