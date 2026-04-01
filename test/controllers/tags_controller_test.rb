# frozen_string_literal: true
require "test_helper"
require_relative "../helpers/resource_controller_test_helper"

class TagsControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers
  include ResourceControllerTestHelper

  setup do
    setup_common_test_data
    setup_model_specific_data
  end

  def setup_model_specific_data
    # Delete the discipline created by the helper and override with a standard discipline
    @resource_discipline&.destroy
    @resource_discipline = create(:discipline, label: "E", name: "Electrical", project: @project)
    # Set up an instance of tag
    @resource = create(:tag, discipline: @resource_discipline)
  end

  private

    # Set the minimum required params for a valid resource
    def valid_resource_params
      { tag: {
        prefix: "T",
        serial: 1111,
        stage: 1,
        discipline_id: @resource_discipline.id,
        service: 'Test service'
      }}
    end

    # Set invalid resource params for tests
    def invalid_resource_params
      { prefix: "22" }
    end

    # Nominate an attribute to get changed during update tests
    def update_attribute_name
      :service
    end

    # Nominate a valid value to update the attribute to
    def updated_attribute_value
      "Update service"
    end
end
