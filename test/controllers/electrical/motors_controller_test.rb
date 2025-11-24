require "test_helper"
require_relative "../../helpers/tagable_test_patterns"
module Electrical
  class MotorsControllerTest < ActionController::TestCase
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
    end

    def params_with_existing_tag
      {
        tag_id: @unassigned_tag.id,
        electrical_motor: {
          motor_type: :induction,
          frame_size: '132',
          poles: 4,
          ingress_protection: 'IP55',
          speed_rated: 1500.0
        }
      }
    end

    def params_with_new_tag
      {
        electrical_motor: {
          motor_type: :induction,
          frame_size: '132',
          poles: 4,
          ingress_protection: 'IP55',
          speed_rated: 1500.0,
          tag: {
            discipline_id: @resource_discipline.id,
            prefix: 'KM',
            serial: 2002,
            suffix: '',
            service: 'Test motor',
            stage: 1
          }
        }
      }
    end

    # Set the minimum required params for a valid resource
    def valid_resource_params
      {
        motor_type: :induction,
        frame_size: '132',
        poles: 4,
        ingress_protection: 'IP55',
        speed_rated: 1500.0
      }
    end

    # Set invalid resource params for tests
    def invalid_resource_params
      { motor_type: 999 }  # Invalid motor type (enum only allows 0-7)
    end

    # Nominate an attribute to get changed during update tests
    def update_params
      { id: @resource.id, electrical_motor: { speed_rated: 1800.0 } }
    end

    # Nominate an attribute to get changed during update tests
    def update_attribute_name
      :speed_rated
    end

    # Nominate a value to update the attribute to
    def updated_attribute_value
      1800.0
    end
  end
end