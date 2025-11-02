require "test_helper"

class TagsControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers

  setup do
    @project = create(:project)
    set_current_project(@project)
    @discipline = create(:discipline, :elec, project: @project)
    @tag = create(:tag,  discipline: @discipline)

    # Set up users
    @admin = create(:user)
    @regular_user = create(:user)
    @project_manager = create(:user)
    @team_member = create(:user)
    
    # Add global admin role
    @admin.grant(:admin)

    # Add project-specific team member roles
    @project_manager.grant(:project_manager, @project)
    @team_member.grant(:team_member, @project)
  end

  # Authentication tests
  test "unauthenticated users should be redirected to sign in" do
    get :index
    assert_unauthenticated
  end

  # Index tests
  test "users without team role on current project are forbidden to access tag index" do
    sign_in @regular_user
    get :index
    assert_forbidden
  end

  test "team members on current project can view tag index" do
    sign_in @team_member
    get :index
    assert_response :success
    assert_not_nil assigns(:tags)
  end
end
