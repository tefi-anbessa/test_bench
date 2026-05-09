# frozen_string_literal: true
require "test_helper"
require "helpers/controller_test_helper"

class DocTypesControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers
include ControllerTestHelper

  setup do
    # Cannot use standard setup because DocType class module has no matching discipline
    setup_projects_and_users
    setup_disciplines(name: "Electrical", required_role: :designer)
    setup_accredited_users(:document_controller)
    setup_model_specific_data
  end

  def setup_model_specific_data
    # Set up in and out of scope instances of doc_type
    @resource = create(:doc_type, discipline: @discipline)
    @other_resource = create(:doc_type, discipline: @other_discipline)
  end

  private

    # Required for nested routes
    def new_nesting_params
      { discipline_id: @discipline.id }
    end

    # Required for nested routes
    def index_nesting_params
      new_nesting_params
    end

    # Set the expected params for a valid create
    def create_params
      { doc_type: 
        {
        code: 'SCH', 
        name: 'Schematic',
        description: "Electrical schematic diagram"
        }
    }
    end

    # Set the expected params for a valid update
    def update_params
      create_params
    end

    # Set invalid resource params for tests
    def invalid_param
      { doc_type: { code: "1234567" } }  # Exceeds maximum length
    end

    # Nominate an attribute to get changed during update tests
    def update_attribute_name
      :code
    end

    # Nominate a valid value to update the attribute to
    def updated_attribute_value
      "NEW"
    end
end
