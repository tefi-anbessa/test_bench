require "test_helper"

class SwitchboardsControllerTest < ActionController::TestCase
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
    
    @request.env["devise.mapping"] = Devise.mappings[:user]
  end

  test "Setup is valid" do
    assert @project.valid?
    assert @admin.valid?
    assert @project_manager.valid?
    assert @team_member.valid?
    assert @electrical_designer.valid?
    assert @regular_user.valid?
    assert @discipline.valid?
    assert @swbd_tag.valid?
    assert @another_swbd_tag.valid?
    assert @switchboard.valid?
    assert @project.persisted?
    assert @admin.persisted?
    assert @project_manager.persisted?
    assert @team_member.persisted?
    assert @electrical_designer.persisted?
    assert @regular_user.persisted?
    assert @discipline.persisted?
    assert @swbd_tag.persisted?
    assert @another_swbd_tag.persisted?
    assert @switchboard.persisted?
  end

  # Index action tests
  test "unauthenticated users should be redirected to sign in" do
    get :index 
    assert_redirected_to new_user_session_url
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
  test "user cannot view switchboard details without a project role" do
    sign_in @regular_user
    get :show, params: { id: @switchboard.id }
    assert_response :forbidden
  end

  test "team member can view project switchboard details" do
    sign_in @team_member
    get :show, params: { id: @switchboard.id }
    assert_response :success
  end

  # New action tests
  test "team member cannot access new switchboard form" do
    sign_in @team_member
    get :new, params: { tag_id: @another_swbd_tag.id }
    assert_response :forbidden
  end

  test "electrical designer can access new switchboard form for existing unassigned tag" do
    sign_in @electrical_designer
    get :new, params: { tag_id: @another_swbd_tag.id }
    assert_response :success
  end

  test "electrical designer can access new switchboard form with no tag" do
    sign_in @electrical_designer
    get :new
    assert_response :success
  end

  # Create action tests
  # Success tests
  test "electrical designer can create switchboard" do
    sign_in @electrical_designer
    assert_difference('Switchboard.count', 1) do
      post :create, params: {
        tag_id: @another_swbd_tag.id,
        switchboard: {
          location: 'Location 3'
        }
      }
    end
    assert_redirected_to switchboard_path(Switchboard.last)
    expected = I18n.t('flash.actions.create.notice', resource_name: Switchboard.model_name.human)
    assert_equal expected, flash[:success]
  end

  # Create action tests
  # Fail to create
  test "team member cannot create switchboard" do
    sign_in @team_member
    assert_difference('Switchboard.count', 0) do
      post :create, params: {
        tag_id: @another_swbd_tag.id,
        switchboard: {
          location: 'Location 3'
        }
      }
    end
    assert_forbidden
  end

  test "electrical designer cannot create switchboard on tag already taken" do
    sign_in @electrical_designer
    assert_difference('Switchboard.count', 0) do
      post :create, params: {
        tag_id: @swbd_tag.id,
        switchboard: {
          location: 'Location 3'
        }
      }
    end
    assert_conflict
  end

  # Edit action tests
  test "team member cannot access edit switchboard form" do
    sign_in @team_member
    get :edit, params: { id: @switchboard.id }
    assert_forbidden
  end

  test "electrical designer can access edit switchboard form" do
    sign_in @electrical_designer
    get :edit, params: { id: @switchboard.id }
    assert_response :success
  end

  # Update action tests
  test "team member cannot update switchboard" do
    sign_in @team_member
    patch :update, params: { 
      id: @switchboard.id,
      switchboard: { location: 'Location 2' }
    }
    assert_forbidden
  end

  test "electrical designer can update switchboard" do
    sign_in @electrical_designer
    patch :update, params: { 
      id: @switchboard.id,
      switchboard: { location: 'Location 2' }
    }
    assert_equal 'Location 2', @switchboard.reload.location
    assert_redirected_to switchboard_path(@switchboard)
    expected = I18n.t('flash.actions.update.notice', resource_name: Switchboard.model_name.human)
    assert_equal expected, flash[:success]
  end

  # No validations on switchboards: no failing test for update.


  # Destroy action tests
  test "electrical designer cannot destroy switchboard" do
    sign_in @electrical_designer
    assert_no_difference('Switchboard.count') do
      delete :destroy, params: { id: @switchboard.id }
    end
    assert_forbidden
  end

  test "admin can destroy switchboard" do
    sign_in @admin
    assert_difference('Switchboard.count', -1) do
      delete :destroy, params: { id: @switchboard.id }
    end
    assert_redirected_to switchboards_path
    expected = I18n.t('flash.actions.destroy.notice', resource_name: Switchboard.model_name.human)
    assert_equal expected, flash[:success]
  end
end
