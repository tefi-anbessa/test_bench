require "test_helper"
require "helpers/tagable_test_patterns"
module Electrical
  class HeatersControllerTest < ActionController::TestCase
    include TagableTestPatterns
    include Devise::Test::ControllerHelpers

    setup do
      setup_common_test_data
      setup_model_specific_data
      setup_tags_and_resources
    end

    def setup_model_specific_data
      # Setup for model functions unrelated to tags
    end

    # Set the minimum required params for a valid resource
    def valid_resource_params
      {
        heater_type: 'cast_in',
        application: 'annealing_heat_treating'
      }
    end

    # Set invalid resource params for tests
    def invalid_resource_params
      { heater_type: 'invalid' }  # Set invalid value for an attribute
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