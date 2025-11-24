require "test_helper"
require_relative "../../helpers/tagable_test_patterns"

module Electrical
  class CablesControllerTest < ActionController::TestCase
    include TagableTestPatterns
    include Devise::Test::ControllerHelpers

    setup do
      # Set the discipline applicable to the resource, required before setup_common_test_data
      @resource_discipline_code = :elec
      setup_common_test_data
      setup_model_specific_data
      setup_tags_and_resources
    end

    def setup_model_specific_data
      # Every model sets a string of the wrong type for testing the type check
      @wrong_tagable_type = "Electrical::Switchboard"
      @cable_type = create(:electrical_cable_type, project: @project)
    end

    def params_with_existing_tag
      {
        tag_id: @unassigned_tag.id,
        electrical_cable: {
          electrical_cable_type_id: @cable_type.id,
          route_length: 10.0,
          vertical_allowance: 5.0,
          termination_allowance: 5.0,
          start_mark: 1,
          end_mark: 2
        }
      }
    end

    def params_with_new_tag
      {
        electrical_cable: {
          electrical_cable_type_id: @cable_type.id,
          route_length: 10.0,
          vertical_allowance: 5.0,
          termination_allowance: 5.0,
          start_mark: 1,
          end_mark: 2,
          tag: {
            discipline_id: @resource_discipline.id,
            prefix: 'EC',
            serial: 2001,
            suffix: '',
            service: 'One-shot cable',
            stage: 1
          }
        }
      }
    end

    # Set the minimum required params for a valid resource
    def valid_resource_params
      { electrical_cable_type_id: @cable_type.id }
    end

    # Set invalid resource params for tests
    def invalid_resource_params
        { electrical_cable_type_id: nil }
    end

    # Nominate an attribute to get changed during update tests
    def update_params
      { id: @resource.id, electrical_cable: { route_length: 15.0 } }
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