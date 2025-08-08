class MotorsController < ApplicationController
  before_action :set_motor, only: %i[ show edit update destroy ]

  # GET /motors or /motors.json
  def index
    @motors = Motor.all
  end

  # GET /motors/1 or /motors/1.json
  def show
  end

  # GET /motors/new
  def new
    @motor = Motor.new
  end

  # GET /motors/1/edit
  def edit
  end

  # POST /motors or /motors.json
  def create
    @motor = Motor.new(motor_params)

    respond_to do |format|
      if @motor.save
        format.html { redirect_to @motor, notice: "Motor was successfully created." }
        format.json { render :show, status: :created, location: @motor }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @motor.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /motors/1 or /motors/1.json
  def update
    respond_to do |format|
      if @motor.update(motor_params)
        format.html { redirect_to @motor, notice: "Motor was successfully updated." }
        format.json { render :show, status: :ok, location: @motor }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @motor.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /motors/1 or /motors/1.json
  def destroy
    @motor.destroy

    respond_to do |format|
      format.html { redirect_to motors_path, status: :see_other, notice: "Motor was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_motor
      @motor = Motor.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def motor_params
      params.require(:motor).permit(:motor_type, :frame_size, :poles, :ingress_protection, :speed_rated)
    end
end
