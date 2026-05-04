# frozen_string_literal: true
require "test_helper"
require "helpers/controller_test_helper"
class TagsControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers
  include ControllerTestHelper

  setup do
    setup_projects_and_users # In test/helpers/test_login_helpers.rb
    setup_disciplines(name: "Electrical", required_role: :designer) 
    setup_accredited_users(:designer)
    setup_discipline_resources
    @request.env["devise.mapping"] = Devise.mappings[:user]
  end

  test "Local_setup_is_valid" do
    assert @project.valid?
    assert @project.persisted?
    assert @discipline.valid?
    assert @discipline.persisted?
    assert @admin.valid?
    assert @admin.persisted?
    assert @project_manager.valid?
    assert @project_manager.persisted?
    assert @team_member.valid?
    assert @team_member.persisted?
    assert @regular_user.valid?
    assert @regular_user.persisted?
    assert @accredited_user.valid?
    assert @accredited_user.persisted?
  end

  test "Local_regular user cannot access index" do
    sign_in_and_set_project @regular_user, @project
    get :index, params: index_nesting_params
    assert_forbidden
  end

  test "Local_team member can access index" do
    sign_in_and_set_project @team_member, @project
    get :index
    assert_response :success
    assert assigns(:swatch)
  end

  # Show Tests
  test "Local_user cannot view tag details without project role" do
    sign_in_and_set_project @regular_user, @project
    get :show, params: { id: @tag.id }
    assert_forbidden
  end

  test "Local_team member can view tag details" do
    sign_in_and_set_project @team_member, @project
    get :show, params: { id: @tag.id }
    assert_response :success
    assert assigns(:swatch)
    assert_equal @tag, assigns(:tag)
  end

  # New Action Tests
  test "Local_team member cannot access new form without any discipline required role" do
    sign_in_and_set_project @team_member, @project
    get :new
    assert_response :forbidden
  end

  test "Local_accredited team member can access new form" do
    sign_in_and_set_project @accredited_user, @project
    get :new
    assert_response :success
  end

  private

  # Helper methods

    # Required for nested routes
    def new_nesting_params
      { discipline_id: @discipline.id }
    end

    # Required for nested routes
    def index_nesting_params
      { discipline_id: @discipline.id }
    end

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
