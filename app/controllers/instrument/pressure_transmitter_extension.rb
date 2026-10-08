# frozen_string_literal: true
module Instrument
  module PressureTransmitterExtension

    private

      def setup_additional_form_data
        # Add any model specific form data here.
      end

      def after_create_hook(pressure_transmitter)
        # Add any model specific after create hook logic here.
      end

      def after_update_hook(pressure_transmitter)
        # Add any model specific after update hook logic here.
      end

      # Only allow a list of trusted parameters through.
      def tagable_params
        params.require(:instrument_pressure_transmitter)
        .permit(:measurement_type, :pressure_unit, :range_min, :range_max, :signal, :communication, 
                :fluid_phase, :process_fluid, :accuracy_class, :connection_type, :connection_size, 
                :case_material, :wetted_material, :movement_type, :ingress_protection, :accessories, :notes)
      end
  end
end
