# frozen_string_literal: true
require "helpers/controller_test_helper"
require "helpers/tagable_controller_tests"
module Instrument
  class PressureGaugesControllerTest < ActionController::TestCase
    include Devise::Test::ControllerHelpers

    include TagableControllerTests
    setup do
      @nesting = :tagable
      setup_controller_test # In test/helpers/controller_test_helper.rb or test/helpers/tagable_controller_tests

    end

    private

      # Set the expected params for a valid resource
      def create_params
        {
          measurement_type: "positive_pressure",
					pressure_unit: "bar",
					range_min: 0.0,
					range_max: 10.0,
					fluid_phase: "gas",
					process_fluid: "gas",
					accuracy_class: "grade_1_6",
					dial_size: "mm100",
					connection_type: "npt",
					connection_size: "in_1_2",
					case_material: "stainless_steel",
					wetted_material: "ss316",
					movement_type: "bourdon_tube",
					liquid_filled: true,
					fill_fluid: "glycerine",
					ip_rating: "65",
					safety_pattern: nil,
					accessories: "Snubber: Required",
					notes: nil
        }
      end

      # Set invalid resource param for tests.
      def invalid_param
        { }  # Set an invalid value for an attribute.
      end

      # Nominate an attribute to get changed during update tests.
      def update_attribute_name
        # Set one attribute name as a symbol
      end

      # Nominate a valid value to update the attribute to, observe the correct type.
      def updated_attribute_value
        "new_value"
      end
  end
end
