require "test_helper"
class SwatchesControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers

  setup do
    @other_user = create(:user)   # No roles

    @admin = create(:user)
    @admin.grant(:admin)

    @app_owner = create(:user)
    @app_owner.grant(:app_owner)

    # Set up an instance of swatch
    @swatch = create(:swatch, name: "controller_test")

    @request.env["devise.mapping"] = Devise.mappings[:user]
  end

  # Set the minimum required params for a valid resource
  def valid_resource_params
    {
      name: "valid_controller_test",
      bg: "#000000",
      text: "#FFFFFF",
      form_bg: "#FFFFFF",
      form_field: "#FFFFFF",
      card_bg: "#FFFFFF",
      card_header_bg: '#aaaaaa',
      card_border: '#222222',
      badge_bg: '#FF0000',
      badge_text: '#00FF00',
      link_text: '#000077',
      link_hover: '#000099'
    }
  end

  test "setup is valid" do
    assert @admin.valid?
    assert @admin.persisted?
    assert @other_user.valid?
    assert @other_user.persisted?
    assert @swatch.valid?
    assert @swatch.persisted?
  end

  test "unauthenticated users are redirected to sign in" do
    get :index
    assert_unauthenticated
  end

  test "other user can access index" do
    sign_in @other_user
    get :index
    assert_response :success
  end

# Show Tests

  test "other user can view resource details" do
    sign_in @other_user
    get :show, params: { id: @swatch.id }
    assert_response :success
  end

  # New Action Tests
  test "other user cannot access new form" do
    sign_in @other_user
    get :new
    assert_response :forbidden
  end

  test "admin can access new form" do
    sign_in @admin
    get :new
    assert_response :success
  end

  # Create Action Tests - Success Cases
    test "admin can create" do
      sign_in @admin
      assert_difference("Swatch.count", 1) do
        post :create, params: { swatch: valid_resource_params }
      end

      created_resource = Swatch.last
      assert_redirected_to created_resource
      assert_equal I18n.t("flash.create.notice", 
        resource_name: I18n.t("activerecord.models.swatch.one")), flash[:success]
  end

  # Create Action Tests - Failure Cases
  test "other user cannot create" do
    sign_in @other_user
    assert_no_difference("Swatch.count") do
      post :create, params: { swatch: valid_resource_params }
    end
    assert_forbidden
  end

  # Edit Action Tests
  test "other user cannot access edit form" do
    sign_in @other_user
    get :edit, params: { id: @swatch.id }
    assert_forbidden
  end

  test "admin can access edit form" do
    sign_in @admin
    get :edit, params: { id: @swatch.id }
    assert_response :success
  end

  # Update Action Tests
  test "other user cannot update" do
    sign_in @other_user
    original_value = @swatch.send(update_attribute_name)
    patch :update, params: 
      { id: @swatch.id, swatch: { update_attribute_name => updated_attribute_value } }
    assert_forbidden
    assert_equal original_value, @swatch.reload.send(update_attribute_name)
  end

  test "admin can update" do
    sign_in @admin
    patch :update, params: 
      { id: @swatch.id, swatch: { update_attribute_name => updated_attribute_value } }
    assert_equal updated_attribute_value, @swatch.reload.send(update_attribute_name)
    assert_redirected_to @swatch
    assert_equal I18n.t("flash.update.notice", resource_name: I18n.t("activerecord.models.swatch.one")), flash[:success]
  end

  # Destroy Action Tests
  test "admin cannot destroy" do
    sign_in @admin
    assert_no_difference("Swatch.count") do
      delete :destroy, params: { id: @swatch.id }
    end
    assert_forbidden
  end

  test "app owner can destroy" do
    sign_in @app_owner
    assert_difference("Swatch.count", -1) do
      delete :destroy, params: { id: @swatch.id }
    end
    assert_redirected_to swatches_path
    assert_equal I18n.t("flash.destroy.notice", resource_name: I18n.t("activerecord.models.swatch.one")), flash[:success]
  end

  private

    # Set invalid resource params for tests
    def invalid_resource_params
      { name: '' }  # Set invalid value for an attribute
    end

    # Nominate an attribute to get changed during update tests
    def update_attribute_name
      :bg
    end

    # Nominate a valid value to update the attribute to
    def updated_attribute_value
      '#000000'
    end

  # Helper methods
end