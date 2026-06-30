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
    # Give accredited user the required role just to pass the setup test.
    @accredited_user.grant(:designer, @discipline)
    setup_discipline_resources
    setup_model_specific_data
  end

  def setup_model_specific_data
    # Working ok with standard discipline resource setup.
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

    # Doc types index permissions are anomalous: only accredited users can access.
    
    undef test_team_member_can_access_index
      # Index Tests - Success cases
    def test_team_member_can_access_index
      sign_in_and_set_project @accredited_user, @project
      get :index, params: index_nesting_params
      assert_response :success
    end
end
