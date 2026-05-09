module Electrical
  class LightCctsController < ApplicationController
    include TagablesController

    # GET /light_ccts or /light_ccts.json
    def index
      index_tagable
    end

    # GET /light_ccts/1 or /light_ccts/1.json
    def show
      show_tagable
    end

    # GET /light_ccts/1/edit
    def edit
      edit_tagable
    end

    # GET /light_ccts/new
    def new
      new_tagable
    end

    # POST /light_ccts or /light_ccts.json
    def create
      create_tagable
    end

    # PATCH/PUT /light_ccts/1 or /light_ccts/1.json
    def update
      update_tagable
    end

    # DELETE /light_ccts/1 or /light_ccts/1.json
    def destroy
      destroy_tagable
    end

    private

    # Light circuit-specific configuration
    def tag_prefix
      "EL"  # Electrical Lighting
    end

    def discipline_code
      "E"  # Electrical
    end

    def setup_additional_form_data
      # Light circuits don't need additional form data
    end

    # Only allow a list of trusted parameters through.
    def resource_params
      params.require(:electrical_light_cct).permit(:light_fitting_type, :quantity, :notes,
        tag: [
          :discipline_id, :prefix, :serial,
          :suffix, :service, :stage, :notes, :tagable_type
        ])
    end
  end
end