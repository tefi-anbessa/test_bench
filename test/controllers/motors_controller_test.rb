require "test_helper"

class MotorsControllerTest < ActionController::TestCase
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
    @motor_tag = create(:tag, prefix: 'EX', serial: 1001, project: @project, discipline: @discipline)
    @unassigned_motor_tag = create(:tag, prefix: 'EX', serial: 1002, project: @project, 
        discipline: @discipline)
    
    # Create motor with the motor tag
    @motor = create(:motor, tag: @motor_tag)
    
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
    assert @motor_tag.valid?
    assert @unassigned_motor_tag.valid?
    assert @motor.valid?
    assert @project.persisted?
    assert @admin.persisted?
    assert @project_manager.persisted?
    assert @team_member.persisted?
    assert @electrical_designer.persisted?
    assert @regular_user.persisted?
    assert @discipline.persisted?
    assert @motor_tag.persisted?
    assert @unassigned_motor_tag.persisted?
    assert @motor.persisted?
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
  test "user cannot view motor details without a project role" do
    sign_in @regular_user
    get :show, params: { id: @motor.id }
    assert_response :forbidden
  end

  test "team member can view project motor details" do
    sign_in @team_member
    get :show, params: { id: @motor.id }
    assert_response :success
  end

  # New action tests
  test "team member cannot access new motor form" do
    sign_in @team_member
    get :new, params: { tag_id: @unassigned_motor_tag.id }
    assert_response :forbidden
  end

  test "electrical designer can access new motor form for existing unassigned tag" do
    sign_in @electrical_designer
    get :new, params: { tag_id: @unassigned_motor_tag.id }
    assert_response :success
  end

  test "electrical designer can access new motor form with no tag" do
    sign_in @electrical_designer
    get :new
    assert_response :success
  end

  # Create action tests
  # Success tests
  test "electrical designer can create motor with existing unallocated tag" do
    sign_in @electrical_designer
    assert_difference('Motor.count', 1) do
      post :create, params: {
        tag_id: @unassigned_motor_tag.id,
        motor: {
          motor_type: :induction,
          frame_size: '132',
          poles: 4,
          ingress_protection: 'IP55',
          speed_rated: 1500.0
        }
      }
    end
    @unassigned_motor_tag.reload
    motor = @unassigned_motor_tag.tagable
    assert_redirected_to motor_path(motor)
    # Flash message confirms success
    expected = I18n.t('flash.tagables.assigned_to', 
      tag: @unassigned_motor_tag.full_tag, resource_name: Motor.model_name.human, id: motor.id)
    assert_equal expected, flash[:success]
  end

  test "electrical designer can create new motor and tag in a single request" do
    sign_in @electrical_designer
    assert_difference('Motor.count', 1) do
      post :create, params: {
        motor: {
          motor_type: :induction,
          frame_size: '132',
          poles: 4,
          ingress_protection: 'IP55',
          speed_rated: 1500.0,
          tag: {
            project_id: @project.id,
            discipline_id: @discipline.id,
            prefix: 'KM',
            serial: 2002,
            suffix: '',
            service: 'Test motor',
            stage: 1
          }
        }
      }
    end
    motor_tag = Tag.find_by(prefix: 'KM', serial: 2002)
    motor = motor_tag.tagable
    assert_redirected_to motor_path(motor)
    # Flash message confirms success
    expected = I18n.t('flash.tagables.created_and_assigned', 
      tag: motor_tag.full_tag, resource_name: Motor.model_name.human, id: motor.id)
    assert_equal expected, flash[:success]
  end

  # Create action tests
  # Fail to create
  test "team member cannot create motor" do
    sign_in @team_member
    assert_no_difference('Motor.count') do
      post :create, params: {
        tag_id: @unassigned_motor_tag.id,
        motor: {
          motor_type: :induction,
          frame_size: '132',
          poles: 4,
          ingress_protection: 'IP55',
          speed_rated: 1500.0
        } 
      }
    end
    assert_forbidden
  end

  test "electrical designer cannot create motor with tag that is not in the database" do
    sign_in @electrical_designer
    assert_no_difference('Motor.count') do
      post :create, params: {
        tag_id: 99,
        motor: {
          motor_type: :induction,
          frame_size: '132',
          poles: 4,
          ingress_protection: 'IP55',
          speed_rated: 1500.0
        }
      }
    end
    assert_conflict
  end

  test "electrical designer cannot create motor on tag already taken" do
    sign_in @electrical_designer
    assert_no_difference('Motor.count') do
      post :create, params: {
        tag_id: @motor_tag.id,
        motor: {
          motor_type: :induction,
          frame_size: '132',
          poles: 4,
          ingress_protection: 'IP55',
          speed_rated: 1500.0
        }
      }
    end
    assert_conflict
  end

  test "electrical designer cannot create motor with tag that is already classified as other than motor" do
    sign_in @electrical_designer
    @motor_tag.update(tagable_type: "Switchboard")
    assert_no_difference('Motor.count') do
      post :create, params: {
        tag_id: @motor_tag.id,
        motor: {
          motor_type: :induction,
          frame_size: '132',
          poles: 4,
          ingress_protection: 'IP55',
          speed_rated: 1500.0
        }
      }
    end
    assert_conflict
  end

  # Edit action tests
  test "team member cannot access edit motor form" do
    sign_in @team_member
    get :edit, params: { id: @motor.id }
    assert_forbidden
  end

  test "electrical designer can access edit motor form" do
    sign_in @electrical_designer
    get :edit, params: { id: @motor.id }
    assert_response :success
  end

  # Update action tests
  test "team member cannot update motor" do
    sign_in @team_member
    patch :update, params: { 
      id: @motor.id,
      motor: { poles: 6 }
    }
    assert_forbidden
  end

  test "electrical designer can update motor" do
    sign_in @electrical_designer
    patch :update, params: { 
      id: @motor.id,
      motor: { poles: 6 }
    }
    assert_equal 6, @motor.reload.poles
    assert_redirected_to motor_path(@motor)
    expected = I18n.t('flash.actions.update.notice', resource_name: Motor.model_name.human)
    assert_equal expected, flash[:success]
  end

  # No validations on motors: no failing test for update.


  # Destroy action tests
  test "electrical designer cannot destroy motor" do
    sign_in @electrical_designer
    assert_no_difference('Motor.count') do
      delete :destroy, params: { id: @motor.id }
    end
    assert_forbidden
  end

  test "admin can destroy motor" do
    sign_in @admin
    assert_difference('Motor.count', -1) do
      delete :destroy, params: { id: @motor.id }
    end
    assert_redirected_to motors_path
    expected = I18n.t('flash.actions.destroy.notice', resource_name: Motor.model_name.human)
    assert_equal expected, flash[:success]
  end
end
