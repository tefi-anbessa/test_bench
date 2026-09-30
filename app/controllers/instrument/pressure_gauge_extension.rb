# frozen_string_literal: true
module Instrument
  module PressureGaugeExtension

    private

      def setup_additional_form_data
        # Add any model specific form data here
      end

      def after_create_hook(pressure_gauge)
        # Add any model specific after create hook logic here
      end

      def after_update_hook(pressure_gauge)
        # Add any model specific after update hook logic here
      end

      def tagable_params
        params.require(:instrument_pressure_gauge)
        .permit(:measurement_type, :pressure_unit, :range_min, :range_max, :fluid_phase, :process_fluid, :accuracy_class, :dial_size, :connection_type, :connection_size, :case_material, :wetted_material, :movement_type, :liquid_filled, :fill_fluid, :ip_rating, :safety_pattern, :accessories, :notes)
      end
  end
end