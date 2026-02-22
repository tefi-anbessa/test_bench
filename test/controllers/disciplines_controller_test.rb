require "test_helper"

class DisciplinesControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers

  setup do
    @request.env["devise.mapping"] = Devise.mappings[:user]

    @project = create(:project)
    set_current_project(@project)
    @swatch = create(:swatch)
    @discipline = create(:discipline, project: @project, swatch: @swatch)

    @app_owner = create(:user)
    @app_owner.grant(:app_owner)

    @admin = create(:user)
    @admin.grant(:admin)

    @project_manager = create(:user)
    @project_manager.grant(:project_manager, @project)

    @team_member = create(:user)
    @team_member.grant(:team_member, @project)

    @regular_user = create(:user)

  end

  # Index action tests
  test "unauthenticated users should be redirected to sign in" do
    get :index, params: { project_id: @project.id }
    assert_unauthenticated
  end

  test "regular user cannot access index" do
    sign_in @regular_user
    get :index, params: { project_id: @project.id }
    assert_forbidden
  end

  test "should get index for any user with project role" do
    sign_in @team_member
    get :index, params: { project_id: @project.id }
    assert_response :success
  end

  # Show action tests
  test "user cannot view discipline details without a project role" do
    sign_in @regular_user
    get :show, params: { id: @discipline.id }
    assert_response :forbidden
  end

  test "team member can view discipline details" do
    sign_in @team_member
    get :show, params: { id: @discipline.id }
    assert_response :success
  end

  # New action tests
  test "team member cannot access new discipline form" do
    sign_in @team_member
    get :new, params: { project_id: @project.id }
    assert_response :forbidden
  end

  test "project manager can access new discipline form" do
    sign_in @project_manager
    get :new, params: { project_id: @project.id }
    assert_response :success
  end

  # Create action tests
  test "project manager can create discipline" do
    sign_in @project_manager
    assert_difference('Discipline.count', 1) do
      post :create, params: { 
        project_id: @project.id,
        discipline: {
          name: 'Piping',
          label: 'P',
          module_name: 'Piping',
          prefix_schema: "name: default",
          swatch_id: @swatch.id
        }
      }
    end
    assert_redirected_to discipline_url(Discipline.last)
  end

  test "shows error flash when discipline creation fails" do
    sign_in @project_manager
    assert_no_difference('Discipline.count') do
      post :create, params: { project_id: @project.id,
        discipline: {
        label: 'a'*6,  # Invalid: label max length is 5
        name: 'Process',
        prefix_schema: {"name": "default"},
        module_name: 'Process'
      }
    }
    end
    assert_template :new
    assert_equal I18n.t('flash.create.alert', resource_name: I18n.t('activerecord.models.discipline')), 
                  flash[:alert]
  end

  # Edit action tests
  test "team member cannot access edit form" do
    sign_in @team_member
    get :edit, params: { id: @discipline.id }
    assert_forbidden
  end

  test "project manager can edit their discipline" do
    sign_in @project_manager
    get :edit, params: { id: @discipline.id }
    assert_response :success
  end

  # Update action tests
  test "team member cannot update discipline" do
    sign_in @team_member
    original_name = @discipline.name
    patch :update, params: {
      id: @discipline.id,
      discipline: {
        name: 'Should Not Update'
      }
    }
    assert_forbidden
    assert_equal original_name, @discipline.reload.name
  end
  
  test "shows error flash when project update fails" do
    sign_in @project_manager
    original_name = @discipline.name
    patch :update, params: {
      id: @discipline.id,
      discipline: {
        label: 'a'*6  # Invalid: label max length is 5
      }
    }
    assert_template :edit
    assert_equal original_name, @discipline.reload.name
    assert_equal I18n.t('flash.update.alert', resource_name: I18n.t('activerecord.models.discipline')), flash[:alert]
  end

  test "project manager can update discipline on their project" do
    sign_in @project_manager
    patch :update, params: {
      id: @discipline.id,
      discipline: {
        name: 'Owner Updated Title'
      }
    }
    assert_redirected_to discipline_url(@discipline)
    assert_equal 'Owner Updated Title', @discipline.reload.name
    assert_equal I18n.t('flash.actions.update.notice', resource_name: I18n.t('activerecord.models.discipline')), flash[:success]
  end

  # Destroy action tests
  test "project manager cannot destroy discipline" do
    sign_in @project_manager
    assert_no_difference('Discipline.count') do
      delete :destroy, params: { id: @discipline.id }
    end
    assert_forbidden
  end

  test "admin can destroy discipline" do
    sign_in @admin
    assert_difference('Discipline.count', -1) do
      delete :destroy, params: { id: @discipline.id }
    end
    assert_redirected_to project_disciplines_url(@discipline.project)
    assert_equal I18n.t('flash.destroy.notice', resource_name: I18n.t('activerecord.models.discipline')), 
                  flash[:success]
  end

end
