module Electrical
  class HeatersController < ApplicationController
    include TagablesController

    # GET /resource or /resource.json
    def index
      index_resource
    end

    # GET /resources/1 or /resources/1.json
    def show
      show_resource
    end

    # GET /resources/1/edit
    def edit
      edit_resource
    end

    # GET /resources/new
    def new
      new_resource
    end

    # POST /resources or /resources.json
    def create
      create_resource
    end

    # PATCH/PUT /resources/1 or /resources/1.json
    def update
      update_resource
    end

    # DELETE /resources/1 or /resources/1.json
    def destroy
      destroy_resource
    end

    private

      def setup_additional_form_data
        @ip_1 = Constants.electrical.ingress_protection.first_digit.to_h
        @ip_2 = Constants.electrical.ingress_protection.second_digit.to_h
      end

      def after_create_hook(resource)
        # Include any additional requirements for creating related entities here.
      end

      def after_update_hook(resource)
        # Include any additional requirements for updating related entities here.
      end

      # Only allow a list of trusted parameters through.
      def resource_params
        params.require(:electrical_heater)
        .permit(:heater_type, :application, :ingress_protection, :sheath_temperature_max, 
                :power_density_min, :power_density_max, :sheath_material, :insulation_material,
                :notes,
          tag: [
            :discipline_id, :prefix, :serial,
            :suffix, :service, :stage, :notes, :tagable_type
          ])
      end
  end
end
