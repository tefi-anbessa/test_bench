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
  test "should get index for signed in users" do
    sign_in @user
    get :index
    assert_response :success
  end

  # Show action tests
  test "should show own user profile to signed in users" do
    sign_in @user
    get :show, params: { id: @user.id }
    assert_response :success
  end
end
