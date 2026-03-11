module Electrical
  class MotorsController < ApplicationController
    include TagablesController

    # GET /motors or /motors.json
    def index
      index_tagable
    end

    # GET /motors/1 or /motors/1.json
    def show
      show_tagable
    end

    # GET /motors/1/edit
    def edit
      edit_tagable
    end

    # GET /motors/new
    def new
      new_tagable
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
      destroy_tagable
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
      @voltage_ratings = Constants.electrical.voltage_ratings
      @ip_1 = Constants.electrical.ingress_protection.first_digit.to_h
      @ip_2 = Constants.electrical.ingress_protection.second_digit.to_h
    end

    # Only allow a list of trusted parameters through.
    def resource_params
      params.require(:electrical_motor).permit(:motor_type, :frame_size, :poles, :ingress_protection, :speed_rated,
        :notes, :submit,
        tag: [
          :id, :project_id, :discipline_id, :prefix, :serial,
          :suffix, :service, :stage, :notes, :tagable_type
        ])
    end
  end
end
