# frozen_string_literal: true
require "test_helper"
require "helpers/controller_test_helper"
class TagsControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers
  include ControllerTestHelper

  setup do
    @nesting = :discipline
    setup_projects_and_users # In test/helpers/test_login_helpers.rb
    setup_disciplines(name: "Electrical", required_role: :designer) 
    setup_accredited_users(:designer)
    setup_discipline_resources
    @request.env["devise.mapping"] = Devise.mappings[:user]
  end

  private

    # Set the minimum required params for a valid resource
    def create_params
      { discipline_id: @discipline.id,
        tag: {
          prefix: "T",
          serial: 1111,
          suffix: "",
          stage: 1,
          service: 'Test service',
          location: "Test location",
          notes: "Test notes"
        }
    }
    end

    def update_params
      create_params
    end

    # Set invalid resource params for tests
    def invalid_param
      { tag: { prefix: "22" } }
    end

    # Nominate an attribute to get changed during update tests
    def update_attribute_name
      :service
    end

    # Nominate a valid value to update the attribute to
    def updated_attribute_value
      "Updated service"
    end
end
