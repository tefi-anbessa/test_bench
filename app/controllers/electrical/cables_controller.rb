module Electrical
  class CablesController < ApplicationController
    include TagablesController
    
    before_action :set_cable, only: %i[show edit update destroy]

    # GET electrical/cables or /electrical/cables.json
    def index
      index_tagable
    end

    # GET electrical/cables/1 or /electrical/cables/1.json
    def show
      authorize @cable
    end

    # GET electrical/cables/new
    def new
      new_tagable
    end

    # POST electrical/cables or /electrical/cables.json
    def create
      create_tagable
    end

    # GET electrical/cables/1/edit
    def edit
      edit_tagable
    end

    # PATCH/PUT electrical/cables/1 or /electrical/cables/1.json
    def update
      update_tagable
    end

    # DELETE electrical/cables/1 or /electrical/cables/1.json
    def destroy
      destroy_tagable
    end

    private
    
      def set_cable
        @cable = Electrical::Cable.find(params[:id])
      end

      # Cable-specific configuration
      def tag_prefix
        "EC"  # Electrical Cable
      end

      def discipline_code
        "E"  # Electrical
      end

      def setup_additional_form_data
        # Only set cable attributes if cable exists (prevents errors during validation failures)
        if @cable.present?
          @cable.from_type ||= Constants.electrical.connect_options.first
          @cable.to_type ||= Constants.electrical.connect_options.last
        end

        @cable_types = policy_scope(Electrical::CableType)
        @cable_type_options = @cable_types.map { |ct| ["#{ct.id}: #{ct.code}", ct.id] }

        # Dynamically build options for all models in constants
        # @id_options is used for the select dropdowns in the cable form for from and to selection
        @id_options = Constants.electrical.connect_options.each_with_object({}) do |model_name, options|
          model_class = model_name.constantize

          # Safe policy_scope call with fallback
          begin
            scope = policy_scope(model_class)
            options[model_name] = (scope || []).map { |record| [record.label, record.id] }
          rescue => e
            # Fallback to empty array if policy_scope fails
            Rails.logger.warn "Failed to get policy_scope for #{model_name}: #{e.message}"
            options[model_name] = []
          end
        end

        # For Stimulus - translated option names
        @connect_options = Constants.electrical.connect_options.map do |option|
          [t("activerecord.models.#{option.underscore}"), option]
        end
      end

      # Only allow a list of trusted parameters through.
      def cable_params
        params.require(:electrical_cable).permit(:electrical_cable_type_id,
          :route_length, :vertical_allowance, :termination_allowance,
          :start_mark, :end_mark, :from_id, :from_type, :to_id, :to_type, :notes,
          tag: [
            :id, :project_id, :discipline_id, :prefix, :serial,
            :suffix, :service, :stage, :notes, :tagable_type
          ])
      end
  end
end