require "test_helper"

class RolesControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers
  setup do
    @role = roles(:resource_instance_role)
    @user = users(:valid)
    @user.grant :admin
  end

  test "no access if not signed in" do
    get roles_url
    assert_redirected_to new_user_session_url
    assert_not flash.empty?
  end

  test "should get index" do
    sign_in @user
    get roles_url
    assert_response :success
  end

  test "should get new" do
    sign_in @user
    get new_role_url
    assert_response :success
  end

  test "should create global role" do
    sign_in @user
    assert_difference("Role.count") do
      post roles_url, params: { role: { user_id: @user.id,
                                        name: :owner,
                                        resource_type: "",
                                        resource_id: ""} }
    end
    assert_not flash.empty?
    assert_redirected_to roles_url
  end

  test "should create resource role" do
    sign_in @user
    assert_difference("Role.count") do
      post roles_url, params: { role: { user_id: @user.id,
                                        name: :owner,
                                        resource_type: projects(:aa).class,
                                        resource_id: ""} }
    end
    assert_not flash.empty?
    assert_redirected_to roles_url
  end

  test "should create resource instance role" do
    sign_in @user
    assert_difference("Role.count") do
      post roles_url, params: { role: { user_id: @user.id,
                                        name: :owner,
                                        resource_type: projects(:aa).class,
                                        resource_id: projects(:aa).id} }
    end
    assert_not flash.empty?
#    assert_redirected_to edit_project_url(projects(:aa))
  end

  test "should destroy global role" do
    sign_in @user
    assert_difference("Role.count", -1) do
      delete user_role_url(users(:valid), roles(:global_role))
    end
  end

  test "should destroy resource role" do
    sign_in @user
    assert_difference("Role.count", -1) do
      delete user_role_url(users(:valid), roles(:resource_role))
    end
  end

  test "should destroy resource instance role" do
    sign_in @user
    assert_difference("Role.count", -1) do
      delete user_role_url(users(:valid), roles(:resource_instance_role))
    end
  end
=begin

    assert_redirected_to roles_url
  end
=end
end
