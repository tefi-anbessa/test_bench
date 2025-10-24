class MotorsController < ApplicationController
  include TagablesController
  before_action :set_motor, only: %i[ show edit update destroy ]

  # GET /motors or /motors.json
  def index
    abstracted_index
  end

  # GET /motors/1 or /motors/1.json
  def show
    authorize @motor
  end

  # GET /motors/1/edit
  def edit
    abstracted_edit
  end

  # GET /motors/new
  def new
    abstracted_new
  end

  # POST /motors or /motors.json
  def create
    create_tagable
  end

  # PATCH/PUT /motors/1 or /motors/1.json
  def update
    update_tagable
  end

  # DELETE /motors/1 or /motors/1.json
  def destroy
    abstracted_destroy
  end

  private

  # Motor-specific configuration
  def tag_prefix
    "EM"  # Electrical Motor
  end

  def discipline_code
    "E"  # Electrical
  end

  def setup_additional_form_data
    @voltage_ratings = Switchboard.voltage_ratings
    @ip_1 = Constants.electrical.ingress_protection.first_digit.to_h
    @ip_2 = Constants.electrical.ingress_protection.second_digit.to_h
  end

  # Use callbacks to share common setup or constraints between actions.
  def set_motor
    @motor = Motor.find(params[:id])
  end

  # Only allow a list of trusted parameters through.
  def motor_params
    params.require(:motor).permit(:motor_type, :frame_size, :poles, :ingress_protection, :speed_rated,
      :notes,
      tag: [
        :id, :project_id, :discipline_id, :prefix, :serial,
        :suffix, :service, :stage, :notes, :tagable_type
      ])
  end
end

