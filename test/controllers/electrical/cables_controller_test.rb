# frozen_string_literal: true
require "test_helper"
require "helpers/tagable_controller_tests"
module Electrical
  class CablesControllerTest < ActionController::TestCase
    include TagableControllerTests
    include Devise::Test::ControllerHelpers

    setup do
      setup_controller_test
      setup_model_specific_data
    end

    def setup_model_specific_data
      @cable_type = create(:electrical_cable_type, discipline: @discipline)
    end

    # Set the expected params for a valid resource create
    def create_params
      { 
        electrical_cable_type_id: @cable_type.id,
        route_length: 10.0,
        vertical_allowance: 5.0,
        termination_allowance: 5.0,
        start_mark: 1,
        end_mark: 21,
        notes: 'Test cable'
      }
    end

    # Set invalid resource params for tests
    def invalid_param
        { electrical_cable_type_id: nil }
    end

    def update_attribute_name
      :route_length
    end

    # Nominate a value to update the attribute to
    def updated_attribute_value
      15.0
    end
  end
end