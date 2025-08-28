require "test_helper"

class UsersControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers

  setup do
    @user = create(:user)
    @admin = create(:user, :admin)
    @app_owner = create(:user, :app_owner)
  end

  test "should not get any action if not authenticated" do
    get :index
    assert_unauthenticated
  end

  # Index action tests
  test "should not get index for signed in users" do
    sign_in @user
    get :index
    assert_response :forbidden
  end

  test "should get index for admin" do
    sign_in @admin
    get :index
    assert_response :success
  end

  test "should show search results" do
    sign_in @admin
    test_user = create(:user, name: 'TestUser', email: 'test@example.com')
    
    get :index, params: { q: { name_or_email_cont: 'test' } }
    assert_response :success
  end

  # Show action tests
  test "should not show user profile to guest users" do
    get :show, params: { id: @user.id }
    assert_redirected_to new_user_session_path
  end

  test "should show own user profile to signed in users" do
    sign_in @user
    get :show, params: { id: @user.id }
    assert_response :success
  end
end
