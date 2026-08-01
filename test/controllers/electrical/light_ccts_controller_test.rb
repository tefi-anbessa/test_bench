# frozen_string_literal: true
require "test_helper"
require "helpers/tagable_controller_tests"
module Electrical
  class LightCctsControllerTest < ActionController::TestCase
    include TagableControllerTests
    include Devise::Test::ControllerHelpers

    setup do
      setup_controller_test
      setup_model_specific_data
    end

    def setup_model_specific_data
    end

    # Set the minimum required params for a valid resource
    def create_params
      {
        light_fitting_type: :general,
        quantity: 2,
        notes: "Test light circuit"
      }
    end

    # Set invalid resource params for tests
    def invalid_param
      { quantity: 0 }  # Invalid quantity
    end

    # Nominate an attribute to get changed during update tests
    def update_attribute_name
      :quantity
    end

    # Nominate a value to update the attribute to
    def updated_attribute_value
      5
    end
  end
end