require "test_helper"

class ProjectsControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers

  setup do
    # Project default swatch must be present
    @swatch= create(:swatch, name: "app_theme")
    @project = create(:project, swatch: @swatch)

    @app_owner = create(:user)
    @app_owner.add_role(:app_owner)

    @admin = create(:user)
    @admin.add_role(:admin)

    @project_manager = create(:user)
    @project_manager.add_role(:project_manager, @project)

    @team_member = create(:user)
    @team_member.add_role(:team_member, @project)

    @regular_user = create(:user)

    # Set the current project for all tests that need it
    set_current_project(@project) if defined?(set_current_project)
    @request.env["devise.mapping"] = Devise.mappings[:user]
  end

  # Index action tests
  test "unauthenticated users should be redirected to sign in" do
    get :index 
    assert_unauthenticated
  end

  test "should get index for any authenticated user" do
    sign_in @regular_user
    get :index
    assert_response :success
  end

  # Show action tests
  test "user cannot view project details without a project role" do
    sign_in @regular_user
    get :show, params: { id: @project.id }
    assert_response :conflict
  end

  test "team member can view their project details" do
    sign_in @team_member
    get :show, params: { id: @project.id }
    assert_response :success
  end

  # New action tests
  test "admin can access new project form" do
    sign_in @admin
    get :new
    assert_response :success
  end

  test "only app owner can access new project form" do
    sign_in @app_owner
    get :new
    assert_response :success
  end

  test "cannot access new project form via JSON" do
    sign_in @app_owner
    get :new, format: :json
    assert_response :not_acceptable
  end

  # Create action tests
  test "admin can create project" do
    sign_in @admin
    assert_difference('Project.count', 1) do
      post :create, params: {
        project: {
          code: 'ZZ',
          title: 'New Project',
          description: 'A new test project'
        }
      }
    end
    assert_redirected_to project_url(Project.last)
  end

  test "only app owner can create project" do
    sign_in @app_owner
    assert_difference('Project.count') do
      post :create, params: {
        project: {
          code: 'ZZ',
          title: 'New Project',
          description: 'A new test project'
        }
      }
    end
    assert_redirected_to project_url(Project.last)
    assert_equal I18n.t('flash.create.notice', resource_name: I18n.t('activerecord.models.project')), flash[:success]
  end

  test "cannot create project via JSON" do
    sign_in @app_owner
    assert_no_difference('Project.count') do
      post :create, params: {
        project: {
          code: 'ZZ',
          title: 'New Project',
          description: 'A new test project'
        },
        format: :json
      }, as: :json
    end
    assert_response :not_acceptable
  end

  test "shows error flash when project creation fails" do
    sign_in @app_owner
    assert_no_difference('Project.count') do
      post :create, params: {
        project: {
          code: '',  # Invalid: code can't be blank
          title: '', # Invalid: title can't be blank
          description: ''
        }
      }
    end
    assert_template :new
    assert_equal I18n.t('flash.create.alert', resource_name: I18n.t('activerecord.models.project')), flash[:alert]
  end

  # Edit action tests
  test "team member cannot edit project" do
    sign_in @team_member
    get :edit, params: { id: @project.id }
    assert_forbidden
  end

  test "cannot access edit form via JSON" do
    sign_in @project_manager
    get :edit, params: { id: @project.id, format: :json }
    assert_response :not_acceptable
  end

  test "project manager can edit their project" do
    sign_in @project_manager
    get :edit, params: { id: @project.id }
    assert_response :success
  end

  # Update action tests
  test "team member cannot update project" do
    sign_in @team_member
    original_title = @project.title
    patch :update, params: {
      id: @project.id,
      project: {
        title: 'Should Not Update',
        description: 'Unauthorized update'
      }
    }
    assert_forbidden
    assert_equal original_title, @project.reload.title
  end

  test "cannot update project via JSON" do
    sign_in @project_manager
    patch :update, params: {
      id: @project.id,
      project: {
        title: 'Should Not Update',
        description: 'Unauthorized update'
      },
      format: :json
    }, as: :json
    assert_response :not_acceptable
  end
  
  test "shows error flash when project update fails" do
    sign_in @project_manager
    original_title = @project.title
    patch :update, params: {
      id: @project.id,
      project: {
        title: '',  # Invalid: title can't be blank
        description: 'Should not update with blank title'
      }
    }
    assert_template :edit
    assert_equal original_title, @project.reload.title
    assert_equal I18n.t('flash.update.alert', resource_name: I18n.t('activerecord.models.project')), flash[:alert]
  end

  test "project owner can update their project" do
    sign_in @project_manager
    patch :update, params: {
      id: @project.id,
      project: {
        title: 'Owner Updated Title',
        description: 'Updated by owner'
      }
    }
    assert_redirected_to project_url(@project)
    assert_equal 'Owner Updated Title', @project.reload.title
    assert_equal I18n.t('flash.actions.update.notice', resource_name: I18n.t('activerecord.models.project')), flash[:success]
  end

  # Destroy action tests
  test "even admin cannot destroy project" do
    sign_in @admin
    assert_no_difference('Project.count') do
      delete :destroy, params: { id: @project.id }
    end
    assert_forbidden
  end

  test "app owner cannot destroy project via JSON" do
    sign_in @app_owner
    assert_no_difference('Project.count') do
      delete :destroy, params: { id: @project.id, format: :json }, as: :json
    end
    assert_response :not_acceptable
  end

  test "app owner can destroy project" do
    sign_in @app_owner
    assert_difference('Project.count', -1) do
      delete :destroy, params: { id: @project.id }
    end
    assert_redirected_to projects_url
    assert_equal I18n.t('flash.destroy.notice', resource_name: I18n.t('activerecord.models.project')), flash[:success]
  end

  # Select action tests
  test "team member can call select" do
    sign_in @team_member
    get :select
    assert_response :success
    assert_not_nil assigns(:options)
    assert_equal assigns(:options).count, 2
  end

  test "ordinary user can call select but won't have any selections available" do
    sign_in @regular_user
    get :select
    assert_response :success
    assert_not_nil assigns(:options)
    assert_equal 1, assigns(:options).count
  end

  test "team member can call set with valid project" do
    sign_in @team_member
    post :set, params: { project_id: @project.id }
    assert_redirected_to project_url(@project)
    assert_equal @project.id, cookies.signed["project_id_user_#{@team_member.id}"]
    assert_equal @project.id, session[:project_id]
  end

  # Set action tests
  test "regular user can call set with no project" do
    sign_in @regular_user
    post :set, params: { project_id: 'none' }
    assert_nil session[:project_id]
    assert_redirected_to projects_url
  end

  test "regular user can call set with invalid project" do
    sign_in @regular_user
    @new_project = create(:project)
    post :set, params: { project_id: @new_project.id }
    assert_redirected_to select_projects_path
  end

end
