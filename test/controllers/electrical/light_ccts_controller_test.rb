require "test_helper"
require_relative "../../helpers/tagable_test_patterns"
module Electrical
  class LightCctsControllerTest < ActionController::TestCase
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
      @wrong_tagable_type = "Electrical::Motor"
    end

    def params_with_existing_tag
      {
        tag_id: @unassigned_tag.id,
        electrical_light_cct: {
          light_fitting_type: :general,
          quantity: 2,
          notes: "Test light circuit"
        }
      }
    end

    def params_with_new_tag
      {
        electrical_light_cct: {
          light_fitting_type: :general,
          quantity: 2,
          tag: {
            discipline_id: @resource_discipline.id,
            prefix: 'EL',
            serial: 2002,
            suffix: '',
            service: 'PARAMS WITH NEW TAG',
            stage: 1
          }
        }
      }
    end

    # Set the minimum required params for a valid resource
    def valid_resource_params
      {
        light_fitting_type: :general,
        quantity: 2
      }
    end

    # Set invalid resource params for tests
    def invalid_resource_params
      { light_fitting_type: :invalid_type }  # Invalid enum value
    end

    # Nominate an attribute to get changed during update tests
    def update_params
      { id: @resource.id, electrical_light_cct: { quantity: 5 } }
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