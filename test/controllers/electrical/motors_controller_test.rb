# frozen_string_literal: true
require "test_helper"
require "helpers/tagable_controller_tests"
module Electrical
  class MotorsControllerTest < ActionController::TestCase
    include TagableControllerTests
    include Devise::Test::ControllerHelpers

    setup do
      setup_common_test_data
      setup_model_specific_data
    end

    def setup_model_specific_data
      # Setup for model functions unrelated to tags
    end

    # Set the minimum required params for a valid resource
    def create_params
      {
        motor_type: :induction,
        frame_size: '132',
        poles: 2,
        ingress_protection: 'IP54',
        speed_rated: 1750.0,
        notes: 'Test motor'
      }
    end

    # Set invalid resource params for tests
    def invalid_param
      { motor_type: 999 }  # Invalid motor type (enum only allows 0-7)
    end

    # Nominate an attribute to get changed during update tests
    def update_attribute_name
      :speed_rated
    end

    # Nominate a valid value to update the attribute to
    def updated_attribute_value
      1800.0
    end
  end
end