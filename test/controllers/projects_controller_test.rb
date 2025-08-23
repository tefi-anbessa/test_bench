require "test_helper"

class ProjectsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @app_owner = create(:user)
    @app_owner.add_role(:app_owner)
    
    @admin = create(:user)
    @admin.add_role(:admin)
    
    @project_owner = create(:user)
    @project = create(:project)
    @project_owner.add_role(:project_owner, @project)
    
    @team_member = create(:user)
    @team_member.add_role(:team_member, @project)
    
    @regular_user = create(:user)
    
    # Set the current project for all tests that need it
    set_current_project(@project) if defined?(set_current_project)
  end

  # Unauthenticated users
  test "unauthenticated users should be redirected to sign in" do
    get projects_url
    assert_redirected_to new_user_session_url
  end

  # Index action tests
  test "should get index for any authenticated user" do
    sign_in @regular_user
    get projects_url
    assert_response :success
  end

  test "app owner can see all projects" do
    sign_in @app_owner
    get projects_url
    assert_response :success
  end

  test "admin can see all projects" do
    sign_in @admin
    get projects_url
    assert_response :success
  end

  test "project owner can see their projects" do
    sign_in @project_owner
    get projects_url
    assert_response :success
  end

  test "team member can see their projects" do
    sign_in @team_member
    get projects_url
    assert_response :success
  end

  # Show action tests
  test "app owner can view any project" do
    sign_in @app_owner
    get project_url(@project)
    assert_response :success
  end

  test "admin can view any project" do
    sign_in @admin
    get project_url(@project)
    assert_response :success
  end

  test "project owner can view their project" do
    sign_in @project_owner
    get project_url(@project)
    assert_response :success
  end

  test "team member can view their project" do
    sign_in @team_member
    get project_url(@project)
    assert_response :success
  end

  test "regular user cannot view projects they don't have access to" do
    sign_in @regular_user
    get project_url(@project), as: :json
    assert_response :forbidden
  end

  # New action tests
  test "only app owner can access new project form" do
    sign_in @app_owner
    get new_project_url
    assert_response :success
  end

  test "admin cannot access new project form" do
    sign_in @admin
    get new_project_url
    assert_redirected_to root_path
  end

  test "project owner cannot access new project form" do
    sign_in @project_owner
    get new_project_url
    assert_redirected_to root_path
  end

  # Create action tests
  test "app owner can create project" do
    sign_in @app_owner
    assert_difference('Project.count') do
      post projects_url, params: { 
        project: { 
          code: 'ZZ', 
          title: 'New Project', 
          description: 'A new test project' 
        },
        format: :html
      }
    end
    assert_redirected_to project_url(Project.last)
  end
  
  test "app owner can create project via JSON" do
    sign_in @app_owner
    assert_difference('Project.count') do
      post projects_url, params: { 
        project: { 
          code: 'ZZ', 
          title: 'New Project', 
          description: 'A new test project' 
        },
        format: :json
      }, as: :json
    end
    assert_response :created
    assert_match /New Project/, response.body
  end

  test "admin cannot create project" do
    sign_in @admin
    assert_no_difference('Project.count') do
      post projects_url, params: { 
        project: { 
          code: 'ZZ', 
          title: 'New Project', 
          description: 'A new test project' 
        },
        format: :html
      }
    end
    assert_redirected_to root_path
  end
  
  test "admin cannot create project via JSON" do
    sign_in @admin
    assert_no_difference('Project.count') do
      post projects_url, params: { 
        project: { 
          code: 'ZZ', 
          title: 'New Project', 
          description: 'A new test project' 
        }
      }, as: :json
    end
    assert_response :forbidden
  end

  # Edit action tests
  test "app owner can edit any project" do
    sign_in @app_owner
    get edit_project_url(@project)
    assert_response :success
  end

  test "admin can edit any project" do
    sign_in @admin
    get edit_project_url(@project)
    assert_response :success
  end

  test "project owner can edit their project" do
    sign_in @project_owner
    get edit_project_url(@project)
    assert_response :success
  end

  test "team member cannot edit project" do
    sign_in @team_member
    get edit_project_url(@project), as: :json
    assert_response :forbidden
  end

  # Update action tests
  test "app owner can update any project" do
    sign_in @app_owner
    patch project_url(@project), params: { 
      project: { 
        title: 'Updated Title',
        description: 'Updated description'
      },
      format: :html
    }
    assert_redirected_to project_url(@project)
    assert_equal 'Updated Title', @project.reload.title
  end

  test "admin can update any project" do
    sign_in @admin
    patch project_url(@project), params: { 
      project: { 
        title: 'Admin Updated Title',
        description: 'Updated by admin'
      },
      format: :html
    }
    assert_redirected_to project_url(@project)
    assert_equal 'Admin Updated Title', @project.reload.title
  end

  test "project owner can update their project" do
    sign_in @project_owner
    patch project_url(@project), params: { 
      project: { 
        title: 'Owner Updated Title',
        description: 'Updated by owner'
      },
      format: :html
    }
    assert_redirected_to project_url(@project)
    assert_equal 'Owner Updated Title', @project.reload.title
  end

  test "team member cannot update project" do
    sign_in @team_member
    original_title = @project.title
    patch project_url(@project), params: { 
      project: { 
        title: 'Should Not Update',
        description: 'Unauthorized update'
      },
      format: :json
    }, as: :json
    assert_response :forbidden
    assert_equal original_title, @project.reload.title
  end

  # Destroy action tests
  test "app owner can destroy project" do
    sign_in @app_owner
    assert_difference('Project.count', -1) do
      delete project_url(@project)
    end
    assert_redirected_to projects_url
  end
  
  test "app owner can destroy project via JSON" do
    sign_in @app_owner
    assert_difference('Project.count', -1) do
      delete project_url(@project), params: { format: :json }, as: :json
    end
    assert_response :no_content
  end

  test "admin cannot destroy project" do
    sign_in @admin
    assert_no_difference('Project.count') do
      delete project_url(@project)
    end
    assert_redirected_to root_path
  end
  
  test "admin cannot destroy project via JSON" do
    sign_in @admin
    assert_no_difference('Project.count') do
      delete project_url(@project), params: { format: :json }, as: :json
    end
    assert_response :forbidden
  end

  test "project owner cannot destroy project" do
    sign_in @project_owner
    assert_no_difference('Project.count') do
      delete project_url(@project)
    end
    assert_redirected_to root_path
  end
  
  test "project owner cannot destroy project via JSON" do
    sign_in @project_owner
    assert_no_difference('Project.count') do
      delete project_url(@project), params: { format: :json }, as: :json
    end
    assert_response :forbidden
  end
end
