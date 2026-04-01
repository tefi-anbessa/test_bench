# frozen_string_literal: true

# This module provides common setup and test patterns for resource controllers.
# Include this in your controller test and all the test methods will run.
require "test_helper"
require "helpers/test_login_helpers.rb"
module ResourceControllerTestHelper
  extend ActiveSupport::Concern
  include TestLoginHelpers

  # Setup common to all resource controllers
  def setup_controller_test
    setup_projects_and_users # In test/helpers/test_login_helpers.rb
    set_current_project(@project)

    @request.env["devise.mapping"] = Devise.mappings[:user]
  end

  def test_setup_is_valid
    if resource_class.respond_to?(:required_role)
      assert resource_class.required_role.present?
    end
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
    assert @accredited_team_member.valid?
    assert @accredited_team_member.persisted?
  end

  # Ensure that the including controller test creates valid in and out of scope resources
  def test_resource_setup_is_valid
    assert @resource.valid?
    assert @resource.persisted?
    assert @other_resource.valid?
    assert @other_resource.persisted?
  end

  def test_unauthenticated_users_are_redirected_to_sign_in
    get :index
    assert_unauthenticated
  end

  def test_regular_user_cannot_access_index
    sign_in @regular_user
    get :index
    assert_forbidden
  end

  def test_team_member_can_access_index
    sign_in @team_member
    get :index
    assert_response :success
  end

  # Show Tests
  def test_user_cannot_view_resource_details_without_project_role
    sign_in @regular_user
    get :show, params: { id: @resource.id }
    assert_forbidden
  end

  def test_team_member_can_view_resource_details
    sign_in @team_member
    get :show, params: { id: @resource.id }
    assert_response :success
  end

  # New Action Tests
  def test_team_member_cannot_access_new_form
    sign_in @team_member
    get :new
    assert_response :forbidden
  end

  def test_accredited_team_member_can_access_new_form
    sign_in @accredited_team_member
    get :new
    assert_response :success
  end

  # Create Action Tests - Failure Cases
  def test_team_member_cannot_create
    sign_in @team_member
    assert_no_difference("#{resource_class}.count") do
      post :create, params: { resource_name => valid_create_params }
    end
    assert_forbidden
  end

  # Create Action Tests - Success Cases
  def test_accredited_team_member_can_create
    sign_in @accredited_team_member
    assert_difference("#{resource_class}.count", 1) do
      post :create, params: { resource_name => valid_create_params }
    end

    created_resource = resource_class.last
    assert_redirected_to created_resource
    assert_successful_create_flash_message
  end

  def test_cannot_create_with_invalid_resource_params
    skip "Invalid resource params not defined" unless invalid_resource_params.present?
    sign_in @accredited_team_member

    if invalid_resource_params.keys.any? { |key| 
          resource_class.defined_enums.key?(key.to_s) && 
          invalid_resource_params[key].present? && 
          !resource_class.defined_enums[key.to_s].include?(invalid_resource_params[key])
        }
      # Invalid enum values should raise conflict error
      assert_no_difference("#{resource_class}.count") do
        post :create, params: { resource_name => valid_create_params.deep_merge(invalid_resource_params) }
      end
      assert_conflict
    else
      # Regular validation errors should render form with errors
      assert_no_difference("#{resource_class}.count") do
        post :create, params: { resource_name => valid_create_params.deep_merge(invalid_resource_params) }
      end
      assert_response :unprocessable_content
      assert_template :new
      assert flash.now[:alert].present?
    end
  end

  # Edit Action Tests
  def test_team_member_cannot_access_edit_form
    sign_in @team_member
    get :edit, params: { id: @resource.id }
    assert_forbidden
  end

  def test_accredited_team_member_can_access_edit_form
    sign_in @accredited_team_member
    get :edit, params: { id: @resource.id }
    assert_response :success
  end

  # Update Action Tests
  def test_team_member_cannot_update
    sign_in @team_member
    original_value = @resource.send(update_attribute_name)
    patch :update, params: 
      { id: @resource.id, resource_name => valid_update_params.merge(update_attribute_name => updated_attribute_value) }
    assert_forbidden
    assert_equal original_value, @resource.reload.send(update_attribute_name)
  end

  def test_accredited_team_member_can_update
    sign_in @accredited_team_member
    patch :update, params: 
      { id: @resource.id, resource_name => valid_update_params.merge( update_attribute_name => updated_attribute_value ) }
    assert_equal updated_attribute_value, @resource.reload.send(update_attribute_name)
    assert_redirected_to resource_path(@resource)
    assert_successful_update_flash_message
  end

  # Destroy Action Tests
  def test_accredited_team_member_cannot_destroy
    sign_in @accredited_team_member
    assert_no_difference("#{resource_class}.count") do
      delete :destroy, params: { id: @resource.id }
    end
    assert_forbidden
  end

  def test_admin_can_destroy
    sign_in @admin
    assert_difference("#{resource_class}.count", -1) do
      delete :destroy, params: { id: @resource.id }
    end
    assert_redirected_to resource_index_path
    assert_successful_destroy_flash_message
  end

  # Helper methods

  def resource_class
   self.class.name.sub('ControllerTest', '').singularize.constantize
  end

  def resource_name
    # Convert class name to underscored symbol
    # e.g., "Electrical::Cable" -> :electrical_cable
    resource_class.model_name.param_key.to_sym
  end

  def resource_path(resource)
    # Use the underscored resource name for path helpers
    # e.g., :electrical_cable -> :electrical_cable_path
    path_helper = "#{resource.model_name.singular_route_key}_path"
    send(path_helper, resource)
  end

  def resource_index_path
    # Handle both namespaced and non-namespaced resources
    path_helper = "#{resource_name.to_s.pluralize}_path".to_sym
    send(path_helper)
  end

  # [TODO] - a more reliable way of generating a unique serial number would be a good idea.
  def params_with_new_tag
    { resource_name => { tag: { prefix: @assigned_tag.prefix,
                                discipline_id: @discipline.id,
                                serial: @assigned_tag.serial + 111,
                                suffix: '',
                                service: 'Test motor',
                                stage: 1 }, **valid_resource_params } }
  end

  def valid_resource_params
    raise NotImplementedError, "Including class must implement valid_resource_params"
  end

  def updated_attribute_value(original_value)
    raise NotImplementedError, "Including class must implement updated_attribute_value"
  end

  def update_params
    raise NotImplementedError, "Including class must implement update_params"
  end

  def assert_successful_create_flash_message
    expected = I18n.t('flash.create.notice',
      resource_name: resource_class.model_name.human)
    assert_flash_message :success, expected
  end

  def assert_successful_update_flash_message
    expected = I18n.t('flash.update.notice',
      resource_name: resource_class.model_name.human)
    assert_flash_message :success, expected
  end

  def assert_successful_destroy_flash_message
    expected = I18n.t('flash.destroy.notice',
      resource_name: resource_class.model_name.human)
    assert_flash_message :success, expected
  end
end
