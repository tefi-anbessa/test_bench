require "test_helper"
require_relative "../../helpers/tagable_test_patterns"
module Electrical
  class SocketCctsControllerTest < ActionController::TestCase
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
      # Setup for model functions unrelated to tags
    end

    def params_with_existing_tag
      {
        tag_id: @unassigned_tag.id,
        electrical_socket_cct: {
          socket_type: "10A",
          quantity: 1
        }
      }
    end

    def params_with_new_tag
      {
        electrical_socket_cct: {
          socket_type: "10A",
          quantity: 1,
          tag: {
            discipline_id: @resource_discipline.id,
            prefix: 'ES',
            serial: 2002,
            suffix: '',
            service: 'Test socket cct',
            stage: 1
          }
        }
      }
    end

    # Set the minimum required params for a valid resource
    def valid_resource_params
      {
        socket_type: "10A",
        quantity: 1
      }
    end

    # Set invalid resource params for tests
    def invalid_resource_params
      { socket_type: 999 }  # Invalid socket type (enum only allows 0-7)
    end

    # Nominate an attribute to get changed during update tests
    def update_params
      { id: @resource.id, electrical_socket_cct: { quantity: 2 } }
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