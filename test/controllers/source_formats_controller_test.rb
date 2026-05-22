# frozen_string_literal: true
require "test_helper"
require "helpers/test_setup_helpers.rb"
class SourceFormatsControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers
  include TestSetupHelpers

  setup do
    setup_projects_and_users
    setup_disciplines(name: "Electrical")
    set_current_project(@project)

    # Set up a user with edit permissions on this resource.
    @accredited_team_member = create(:user)
    @accredited_team_member.grant(:team_member, @project)
    @accredited_team_member.grant(SourceFormat.required_role)

    # Set up an instance of source_format
    @source_format = create(:source_format)

    @request.env["devise.mapping"] = Devise.mappings[:user]
  end

  test "setup is valid" do
    assert @project.valid?
    assert @project.persisted?
    assert @discipline.valid?
    assert @discipline.persisted?
    assert @admin.valid?
    assert @admin.persisted?
    assert @project_manager.valid?
    assert @project_manager.persisted?
    assert @team_member.valid?
    assert @team_member.persisted?
    assert @regular_user.valid?
    assert @regular_user.persisted?
    assert @accredited_team_member
    assert @accredited_team_member.persisted?
    assert @source_format.valid?
    assert @source_format.persisted?
  end

  test "unauthenticated users are redirected to sign in" do
    get :index, params: index_nesting_params
    assert_unauthenticated
  end

  test "any user can access index" do
    sign_in @regular_user
    get :index, params: index_nesting_params
    assert_response :success
  end

  test "team member can access index" do
    sign_in @team_member
    get :index, params: index_nesting_params
    assert_response :success
  end

# Show Tests
  test "any user can view resource details" do
    sign_in @regular_user
    get :show, params: { id: @source_format.id }
    assert_response :success
  end

  test "team member can view resource details" do
    sign_in @team_member
    get :show, params: { id: @source_format.id }
    assert_response :success
  end

  # New Action Tests
  test "team member cannot access new form" do
    sign_in @team_member
    get :new, params: new_nesting_params
    assert_response :forbidden
  end

  test "admin can access new form" do
    sign_in @admin
    get :new, params: new_nesting_params
    assert_response :success
  end

  # Create Action Tests - Success Cases
    test "admin can create" do
      sign_in @admin
      assert_difference("SourceFormat.count", 1) do
      post :create, params: new_nesting_params.merge(create_params)
      end

      created_resource = SourceFormat.last
      assert_redirected_to created_resource
      assert_equal I18n.t("flash.create.notice", 
        resource_name: I18n.t("activerecord.models.source_format.one")), 
        flash[:success]
  end

  # Create Action Tests - Failure Cases
  test "team member cannot create" do
    sign_in @team_member
    assert_no_difference("SourceFormat.count") do
      post :create, params: { source_format: create_params }
    end
    assert_forbidden
  end

  # Edit Action Tests
  test "team member cannot access edit form" do
    sign_in @team_member
    get :edit, params: { id: @source_format.id }
    assert_forbidden
  end

  test "admin can access edit form" do
    sign_in @admin
    get :edit, params: { id: @source_format.id }
    assert_response :success
  end

  # Update Action Tests
  test "team member cannot update" do
    sign_in @team_member
    original_value = @source_format.send(update_attribute_name)
    patch :update, params: 
      { id: @source_format.id, source_format: { update_attribute_name => updated_attribute_value } }
    assert_forbidden
    assert_equal original_value, @source_format.reload.send(update_attribute_name)
  end

  test "admin can update" do
    sign_in @admin
    patch :update, params: 
      { id: @source_format.id, source_format: { update_attribute_name => updated_attribute_value } }
    assert_equal updated_attribute_value, @source_format.reload.send(update_attribute_name)
    assert_redirected_to @source_format
    assert_equal I18n.t("flash.update.notice",
      resource_name: I18n.t("activerecord.models.source_format.one")),
      flash[:success]
  end

  # Destroy Action Tests
  test "accredited team member cannot destroy" do
    sign_in @accredited_team_member
    assert_no_difference("SourceFormat.count") do
      delete :destroy, params: { id: @source_format.id }
    end
    assert_forbidden
  end

  test "admin can destroy" do
    sign_in @admin
    assert_difference("SourceFormat.count", -1) do
      delete :destroy, params: { id: @source_format.id }
    end
    assert_redirected_to source_formats_path
    assert_equal I18n.t("flash.destroy.notice", 
      resource_name: I18n.t("activerecord.models.source_format.one")), 
      flash[:success]
  end

  private

    # Required for nested routes
    def new_nesting_params
      {  }
    end

    # Required for nested routes
    def index_nesting_params
      new_nesting_params
    end

    # Set the minimum required params for a valid resource
    def create_params
      { source_format: {
        vendor: 'Test Vendor',
        title: 'Test Title',
        file_extension: '.pdf',
        revision: '1.0',
        notes: 'Test notes'
        }
      }
    end

    def update_params
      create_params
    end

    # Set invalid resource params for tests
    def invalid_resource_param
      { title: "a"*21 }  # Exceeds length validation
    end

    # Nominate an attribute to get changed during update tests
    def update_attribute_name
      :revision
    end

    # Nominate a valid value to update the attribute to
    def updated_attribute_value
      "2.0"
    end

  # Helper methods
    def assert_successful_creation_flash_message(resource = @resource)
      assert_equal I18n.t("flash.create.notice", resource: I18n.t("activerecord.models.source_format.one")), flash[:notice]
    end

end
