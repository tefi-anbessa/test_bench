require "test_helper"

class UsersControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers

  setup do
    # UsersController always sets @swatch from the app_theme swatch (users
    # have no project/discipline of their own to theme from) - this must
    # exist for any view in this controller to render.
    create(:swatch, name: "app_theme")
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

  # Edit action tests
  test "should get edit for own profile" do
    sign_in @user
    get :edit, params: { id: @user.id }
    assert_response :success
  end

  test "should not get edit for another user's profile" do
    sign_in @user
    get :edit, params: { id: @admin.id }
    assert_forbidden
  end

  test "admin should get edit for another user's profile" do
    sign_in @admin
    get :edit, params: { id: @user.id }
    assert_response :success
  end

  # Update action tests
  test "should update own profile fields" do
    sign_in @user
    patch :update, params: { id: @user.id, user: { job_title: "Design Engineer", time_zone: "UTC" } }
    assert_redirected_to user_path(@user)
    assert_equal "Design Engineer", @user.reload.job_title
  end

  test "should not update another user's profile" do
    @admin.update!(job_title: "Original title")
    sign_in @user
    patch :update, params: { id: @admin.id, user: { job_title: "Hacked" } }
    assert_forbidden
    assert_equal "Original title", @admin.reload.job_title
  end

  test "update sets the locale cookie when preferred_locale changes" do
    sign_in @user
    patch :update, params: { id: @user.id, user: { preferred_locale: "km" } }
    assert_equal "km", cookies[:locale]
  end

  test "update can attach an avatar" do
    sign_in @user
    avatar = fixture_file_upload(Rails.root.join("app/assets/images/HAL9000.jpg"), "image/jpeg")
    patch :update, params: { id: @user.id, user: { avatar: avatar } }
    assert @user.reload.avatar.attached?
  end
end
