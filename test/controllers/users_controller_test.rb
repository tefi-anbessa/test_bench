require "test_helper"

class UsersControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @user = create(:user)
    @admin = create(:user, :admin)
    @app_owner = create(:user, :app_owner)
  end

  # Show action tests
  test "should show user to signed in users" do
    sign_in @user
    get user_url(@user)
    assert_response :success
  end

  test "should not show user profile to guest users" do
    get user_path(@user)
    assert_redirected_to new_user_session_path
  end

  # Index action tests
  test "should get index for admin" do
    sign_in @admin
    get users_url
    assert_response :success
  end

  test "should get index for app_owner" do
    sign_in @app_owner
    get users_url
    assert_response :success
  end

  test "should show search results" do
    sign_in @admin
    test_user = create(:user, name: 'TestUser', email: 'test@example.com')
    
    get users_url, params: { q: { name_or_email_cont: 'test' } }
    assert_response :success
  end

  # Authorization tests
  test "app owner should have access to users index" do
    sign_in @app_owner
    get users_url
    assert_response :success
  end

  test "regular user can access users index" do
    sign_in @user
    get users_url
    assert_response :success
  end
end
