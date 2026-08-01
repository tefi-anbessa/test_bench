# frozen_string_literal: true

require "test_helper"
require "helpers/tagable_controller_tests"
module Electrical
  class HeatersControllerTest < ActionController::TestCase
    include TagableControllerTests
    include Devise::Test::ControllerHelpers

    setup do
      setup_controller_test
      setup_model_specific_data
    end

    def setup_model_specific_data
      # Setup for model functions unrelated to tags
    end

    # Set the expected params for a valid resource create
    def create_params
      {
        heater_type: 'cast_in',
        application: 'annealing_heat_treating',
        ingress_protection: 'IP54',
        sheath_temperature_max: 450.0,
        power_density_min: 50.0,
        power_density_max: 200.0,
        sheath_material: 'stainless_steel',
        insulation_material: 'fluoropolymer'
      }
    end

    # Set invalid resource params for tests
    def invalid_param
      { insulation_material: 'magnesia' }  # Set invalid value for an attribute AI concocted!!!
    end

    # Nominate an attribute to get changed during update tests
    def update_attribute_name
      :sheath_temperature_max
    end

    # Nominate a valid value to update the attribute to
    def updated_attribute_value
      400.0
    end
  end
end