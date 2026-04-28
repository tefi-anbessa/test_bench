# frozen_string_literal: true
require "test_helper"
require "helpers/tagable_controller_tests"
module Electrical
  class SocketCctsControllerTest < ActionController::TestCase
    include TagableControllerTests
    include Devise::Test::ControllerHelpers

    setup do
      setup_common_test_data
      setup_model_specific_data
    end

    def setup_model_specific_data
      # Setup for model functions unrelated to tags
    end

    # Set the expected params for a valid resource
    def valid_resource_params
      {
        socket_type: "10A",
        quantity: 1,
        notes: "Test"
      }
    end

    # Set invalid resource params for tests
    def invalid_resource_param
      { socket_type: 'new' }  # Invalid socket type 
    end

    # Nominate an attribute to get changed during update tests
    def update_attribute_name
      :quantity
    end

    # Nominate a value to update the attribute to
    def updated_attribute_value
      2
    end
  end
end