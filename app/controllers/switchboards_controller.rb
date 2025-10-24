class SwitchboardsController < ApplicationController
  include TagablesController
  
  before_action :set_switchboard, only: %i[show edit update destroy]

  # GET /switchboards or /switchboards.json
  def index
    abstracted_index
  end

  # GET /switchboards/1 or /switchboards/1.json
  def show
    authorize @switchboard
  end

  # GET /switchboards/new
  def new
    abstracted_new
  end

  # POST /switchboards or /switchboards.json
  def create
    create_tagable
  end

  # GET /switchboards/1/edit
  def edit
    abstracted_edit
  end

  # PATCH/PUT /switchboards/1 or /switchboards/1.json
  def update
    update_tagable
  end

  # DELETE /switchboards/1 or /switchboards/1.json
  def destroy
    abstracted_destroy
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

  def after_create_hook
    update_circuits if params[:circuits].present?
  end

  def after_update_hook
    update_circuits if params[:circuits].present?
  end

  # Updates the number of circuits for the switchboard
  def update_circuits(desired_count = nil)
    desired_count ||= params.dig(:switchboard, :circuits).presence || params[:circuits].presence
    return unless desired_count

    desired_count = desired_count.to_i
    current_count = @switchboard.circuits.count

    if desired_count > current_count
      authorize Circuit, :create?
      (desired_count - current_count).times do |i|
        @switchboard.circuits.create(serial: current_count + i + 1)
      end
    elsif desired_count < current_count
      authorize Circuit, :destroy?
      @switchboard.circuits
                 .order(serial: :desc)
                 .limit(current_count - desired_count)
                 .destroy_all
    end
  end

  def set_switchboard
    @switchboard = Switchboard.find(params[:id])
  end

  # Only allow a list of trusted parameters through.
  def switchboard_params
    params.require(:switchboard).permit(:location, :ingress_protection, :voltage_rating,
      :busbar_rating, :busbar_fault_rating, :busbar_fault_duration,
      :cable_entry, :incomer_protection, :metering,
      :neutral_bar_connections, :earth_bar_connections, :notes,
      tag: [
        :id, :project_id, :discipline_id, :prefix, :serial,
        :suffix, :service, :stage, :notes, :tagable_type
      ])
  end
end
