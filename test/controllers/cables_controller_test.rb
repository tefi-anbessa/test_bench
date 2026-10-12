# frozen_string_literal: true
require "test_helper"
require "helpers/tagable_controller_tests"
class CablesControllerTest < ActionController::TestCase
  include TagableControllerTests
  include Devise::Test::ControllerHelpers
  tests TagablesController

  def tagable_type
    "Cable"
  end

  # Cable is bare/core - shared by more than one discipline's module - so
  # it has no module of its own to derive a discipline name from. Test it
  # under Electrical, same as before the move.
  def discipline_name_for_tagable_tests
    "Electrical"
  end

  setup do
    setup_tagables_controller_test
    setup_model_specific_data
  end

  def setup_model_specific_data
    @cable_type = create(:electrical_cable_type, discipline: @discipline)
  end

  # Set the expected params for a valid resource create
  def create_params
    {
      cable_type_id: @cable_type.id,
      cable_type_type: "Electrical::CableType",
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
      { cable_type_id: nil }
  end

  def update_attribute_name
    :route_length
  end

  # Nominate a value to update the attribute to
  def updated_attribute_value
    15.0
  end
end
