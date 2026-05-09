module Electrical
  class HeatersController < ApplicationController
    include TagablesController

    # GET /resource or /resource.json
    def index
      index_tagable
    end

    # GET /resources/1 or /resources/1.json
    def show
      show_tagable
    end

    # GET /resources/1/edit
    def edit
      edit_tagable
    end

    # GET /resources/new
    def new
      new_tagable
    end

    # POST /resources or /resources.json
    def create
      create_tagable
    end

    # PATCH/PUT /resources/1 or /resources/1.json
    def update
      update_tagable
    end

    # DELETE /resources/1 or /resources/1.json
    def destroy
      destroy_tagable
    end

    private

      def setup_additional_form_data
        # Include setup for form variables such as select fields.
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
