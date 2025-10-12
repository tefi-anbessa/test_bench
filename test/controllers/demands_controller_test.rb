require "test_helper"

class DemandsControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers

  setup do

    @project = create(:project)
    # Set the current project for all tests that need it
    set_current_project(@project) if defined?(set_current_project)

    @admin = create(:user)
    @admin.grant(:admin)

    @project_manager = create(:user)
    @project_manager.grant(:project_manager, @project) # Project manager role

    @team_member = create(:user)
    @team_member.grant(:team_member, @project) # Project team member role

    @electrical_designer = create(:user)
    @electrical_designer.grant(:electrical_designer) # Global electrical designer role
    @electrical_designer.grant(:team_member, @project) # Project team member role

    @regular_user = create(:user)   # No roles

    @discipline = create(:discipline, code: 'E', name: 'Electrical')
    
    # Create tags
    @swbd_tag = create(:tag, prefix: 'EX', serial: 1001, project: @project, discipline: @discipline)
    @another_swbd_tag = create(:tag, prefix: 'EX', serial: 1002, project: @project, discipline: @discipline)
    
    # Create switchboard with the switchboard tag
    @switchboard = create(:switchboard, tag: @swbd_tag, location: 'Location 1')
    @demand = create(:demand, demandable: @switchboard)
    
    @request.env["devise.mapping"] = Devise.mappings[:user]
  end

  # Index action tests
  test "unauthenticated users should be redirected to sign in" do
    get :index 
    assert_unauthenticated 
  end

  test "regular user cannot get index" do
    sign_in @regular_user
    get :index
    assert_response :forbidden
  end

  test "should get index for user with role on current project" do
    sign_in @team_member
    get :index
    assert_response :success
  end

  # Show action tests
  test "user cannot view demand details without a project role" do
    sign_in @regular_user
    get :show, params: { id: @demand.id }
    assert_response :forbidden
  end

end