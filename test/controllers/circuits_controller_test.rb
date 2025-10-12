require 'test_helper'

class CircuitsControllerTest < ActionController::TestCase
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
    
    # Create circuit for the switchboard 
    @circuit = create(:circuit, switchboard: @switchboard)
    
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
    assert_unauthorized
  end

  test "should get index for user with role on current project" do
    sign_in @team_member
    get :index
    assert_response :success
  end

  # Show action tests
  test "user cannot view circuit details without a project role" do
    sign_in @regular_user
    get :show, params: { id: @circuit.id }
    assert_unauthorized
  end

  test "team member can view project circuit details" do
    sign_in @team_member
    get :show, params: { id: @circuit.id }
    assert_response :success
  end

  # New action tests
  test "team member cannot access new circuit form" do
    sign_in @team_member
    get :new, params: { switchboard_id: @switchboard.id }
    assert_unauthorized
  end

  test "electrical designer can access new circuit form for existing switchboard" do
    sign_in @electrical_designer
    get :new, params: { switchboard_id: @switchboard.id }
    assert_response :success
  end

  # Create action tests
  # Fail to create
  test "team member cannot create circuit" do
    sign_in @team_member
    assert_difference('Circuit.count', 0) do
      post :create, params: {
        switchboard_id: @switchboard.id,
        circuit: {
          serial: 1
        }
      }
    end
    assert_unauthorized
  end

  test "electrical designer can create circuit" do
    sign_in @electrical_designer
    assert_difference('Circuit.count', 1) do
      post :create, params: {
        switchboard_id: @switchboard.id,
        circuit: {
          serial: 2
        }
      }
    end
    assert_redirected_to circuit_url(Circuit.last)
  end

  # Edit action tests
  test "team member cannot access edit circuit form" do
    sign_in @team_member
    get :edit, params: { id: @circuit.id }
    assert_unauthorized
  end

  test "electrical designer can access edit circuit form" do
    sign_in @electrical_designer
    get :edit, params: { id: @circuit.id }
    assert_response :success
  end

  # Update action tests
  test "team member cannot update circuit" do
    sign_in @team_member
    patch :update, params: { 
      id: @circuit.id,
      circuit: { serial: 3 }
    }
    assert_unauthorized
  end

  test "electrical designer can update circuit" do
    sign_in @electrical_designer
    patch :update, params: { 
      id: @circuit.id,
      circuit: { serial: 3 }
    }
    assert_equal 3, @circuit.reload.serial
    assert_redirected_to circuit_path(@circuit)
    expected = I18n.t('flash.actions.update.notice', resource_name: Circuit.model_name.human)
    assert_equal expected, flash[:success]
  end

  # Destroy action tests
  test "electrical designer cannot destroy circuit" do
    sign_in @electrical_designer
    assert_no_difference('Circuit.count') do
      delete :destroy, params: { id: @circuit.id }
    end
    assert_unauthorized
  end

  test "admin can destroy circuit" do
    sign_in @admin
    assert_difference('Circuit.count', -1) do
      delete :destroy, params: { id: @circuit.id }
    end
    assert_redirected_to circuits_path
    expected = I18n.t('flash.actions.destroy.notice', resource_name: Circuit.model_name.human)
    assert_equal expected, flash[:success]
  end
end
