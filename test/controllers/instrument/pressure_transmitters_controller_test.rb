# frozen_string_literal: true
require "test_helper"
require "helpers/tagable_controller_tests"
module Instrument
  class PressureTransmittersControllerTest < ActionController::TestCase
    include TagableControllerTests
    include Devise::Test::ControllerHelpers
    tests TagablesController

    def tagable_type
      "Instrument::PressureTransmitter"
    end

    setup do
      setup_tagables_controller_test
    end

    private

      # Set the expected params for a valid resource
      def create_params
        {
          measurement_type: "positive_pressure",
					pressure_unit: "bar",
					range_min: 0.0,
					range_max: 10.0,
					signal: "ma_4_20",
					communication: "hart",
					fluid_phase: "liquid",
					process_fluid: "water",
					accuracy_class: "grade_1_6",
					connection_type: "npt",
					connection_size: "in_1_2",
					case_material: "stainless_steel",
					wetted_material: "ss316",
					movement_type: "bourdon_tube",
					ip_rating: "65",
					accessories: "Diaphram seal: Required",
					notes: nil
        }
      end

      # Set invalid resource param for tests.
      def invalid_param
        { signal: "ma_0_20" }  # Set an invalid value for an attribute.
      end

      # Nominate an attribute to get changed during update tests.
      def update_attribute_name
        # Set one attribute name as a symbol
        :ip_rating
      end

      # Nominate a valid value to update the attribute to, observe the correct type.
      def updated_attribute_value
        "66"
      end
  end
end
