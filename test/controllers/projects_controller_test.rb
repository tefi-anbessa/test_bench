require "test_helper"

class ProjectsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @project = projects(:ab)
    @user = users(:valid)
    @owner = users(:owner)
  end

  test "no access if not signed in" do
    get projects_url
    assert_redirected_to new_user_session_url
    assert_not flash.empty?
  end

  test "should get index" do
    sign_in @user
    get projects_url
    assert_response :success
  end

  test "should get new" do
    sign_in users(:owner)
    get new_project_url
    assert_response :success
  end

  test "should create project" do
    sign_in users(:owner)
    assert_difference("Project.count") do
      post projects_url, params: { project: { code: @project.code.succ, description: @project.description, title: @project.title } }
    end

    assert_redirected_to project_url(Project.last)
  end

  test "should show project" do
    sign_in @user
    get project_url(@project)
    assert_response :success
  end

  test "should get edit" do
    sign_in users(:owner)
    get edit_project_url(@project)
    assert_response :success
  end

  test "should update project" do
    sign_in users(:owner)
    patch project_url(@project), params: { project: { code: @project.code, description: @project.description, title: @project.title } }
    assert_redirected_to project_url(@project)
  end

  test "should destroy project" do
    sign_in users(:owner)
    assert_difference("Project.count", -1) do
      delete project_url(@project)
    end

    assert_redirected_to projects_url
  end

  test "should set current project from cookie" do
    sign_in @user
    assert_redirected_to select_projects_url
  end
end
