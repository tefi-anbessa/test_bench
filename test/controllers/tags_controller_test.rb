# frozen_string_literal: true
require "test_helper"
require "helpers/test_setup_helpers.rb"

class TagsControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers
  include TestSetupHelpers

  setup do
    setup_projects_and_users # in test/helpers/test_login_helpers.rb
    setup_disciplines(name: "Electrical", required_role: :designer)
    setup_accredited_users(:designer)
    setup_model_specific_data
  end

  def setup_model_specific_data
    # Add another standard discipline
    @discipline_j = @project.disciplines.find_by(name: "Instrument")
    # Set up instances of tag
    @accredited_user_j = create(:user)
    @accredited_user_j.grant(:designer, @discipline_j)
    @tag = create(:tag, discipline: @discipline)
    @tag_j = create(:tag, discipline: @discipline_j)
  end

  test "setup_is_valid" do
    assert @project.valid?
    assert @project.persisted?
    assert @discipline.valid?
    assert @discipline.persisted?
    assert @discipline_j.valid?
    assert @discipline_j.persisted?
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
    assert @accredited_user_j.valid?
    assert @accredited_user_j.persisted?
    assert @tag.valid?
    assert @tag.persisted?
    assert @tag_j.valid?
    assert @tag_j.persisted?
  end

  test "unauthenticated users are redirected to sign in" do
    get :index
    assert_unauthenticated
  end

  test "regular user cannot access index" do
    sign_in_and_set_project @regular_user, @project
    get :index
    assert_forbidden
  end

  test "team member can access index" do
    sign_in_and_set_project @team_member, @project
    get :index
    assert_response :success
    assert assigns(:swatch)
  end

  # Show Tests
  test "user cannot view tag details without project role" do
    sign_in_and_set_project @regular_user, @project
    get :show, params: { id: @tag.id }
    assert_forbidden
  end

  test "team member can view tag details" do
    sign_in_and_set_project @team_member, @project
    get :show, params: { id: @tag.id }
    assert_response :success
    assert assigns(:swatch)
    assert_equal @tag, assigns(:tag)
  end

  # New Action Tests
  test "team member cannot access new form without any discipline required role" do
    sign_in_and_set_project @team_member, @project
    get :new
    assert_response :forbidden
  end

  test "accredited team member can access new form" do
    sign_in_and_set_project @accredited_user, @project
    get :new
    assert_response :success
  end

  private

  # Helper methods

  def resource_class
   self.class.name.sub('ControllerTest', '').singularize.constantize
  end

    # Set the minimum required params for a valid resource
    def valid_params
      { tag: {
        prefix: "T",
        serial: 1111,
        stage: 1,
        discipline_id: @discipline.id,
        service: 'Test service'
      }}
    end

    # Set invalid resource params for tests
    def invalid_params
      { prefix: "22" }
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
