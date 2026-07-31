# frozen_string_literal: true

# This module provides common setup and test patterns for resource controllers.
# Include this in the controller test and all the test methods will run.
require "test_helper"
require_relative "test_setup_helpers"
module ControllerTestHelper
  extend ActiveSupport::Concern
  include TestSetupHelpers

  # Setup common to all resource controllers, where the module defines the discipline.
  # Core models use their own setup.
  # Including test classes must set up @resource and @other_resource.
  # Use setup_discipline_resources or setup_project_resources,
  # or manage special cases.
  def setup_controller_test
    setup_projects_and_users # In test/helpers/test_setup_helpers.rb
    setup_disciplines # Will default to resource discipline
    setup_accredited_users
    @request.env["devise.mapping"] = Devise.mappings[:user]
  end

  def test_setup_is_valid
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
    assert @accredited_user.valid?
    assert @accredited_user.persisted?
    assert @accredited_user.has_role?(@discipline.required_role, @discipline)
  end

  # Ensure that the including controller test creates valid in and out of scope resources
  def test_resource_setup_is_valid
    assert @resource.valid?
    assert @resource.persisted?
    assert @other_resource.valid?
    assert @other_resource.persisted?
  end

  def test_unauthenticated_users_are_redirected_to_sign_in
    get :index, params: index_params
    assert_unauthenticated
  end

  # Index Tests - Success cases
  def test_team_member_can_access_index
    sign_in_and_set_project @team_member, @project
    get :index, params: index_params
    assert_response :success
  end

  # Index Tests - Failure cases
  def test_regular_user_cannot_access_index
    sign_in_and_set_project @regular_user, @project
    get :index, params: index_params
    if :index_params.present?
      assert_conflict
    else
      assert_forbidden
    end
  end

  # Show Tests - Success cases
  def test_team_member_can_view_resource_details
    sign_in_and_set_project @team_member, @project
    get :show, params: { id: @resource.id }
    assert_response :success
  end

  # Show Tests - Failure cases - Tests the set resource method
  def test_user_cannot_view_resource_details_without_project_role
    sign_in_and_set_project @regular_user, @project
    get :show, params: { id: @resource.id }
    assert_conflict
  end

  def test_team_member_cannot_view_resource_details_when_not_in_project
    sign_in_and_set_project @team_member, @project
    get :show, params: { id: @other_resource.id }
    assert_conflict
  end

  # New Action Tests - Success cases
  def test_accredited_user_can_access_new_form
    sign_in_and_set_project @accredited_user, @project
    get :new, params: new_params
    assert_response :success
  end

  # New Action Tests - failure cases
  def test_team_member_cannot_access_new_form
    sign_in_and_set_project @team_member, @project
    get :new, params: new_params
    assert_response :forbidden
  end

  # Create Action Tests - Success Cases
  def test_accredited_user_can_create
    sign_in_and_set_project @accredited_user, @project
    assert_difference("#{resource_class}.count", 1) do
      post :create, params: new_params.merge(create_params)
    end

    # No reliable way to get the created resource...
    # created_resource = resource_class.find_by(new_params.merge(create_params)[resource_name])
    # assert_redirected_to created_resource
    assert_successful_create_flash_message
  end

  # Create Action Tests - Failure Cases
  def test_team_member_cannot_create
    sign_in_and_set_project @team_member, @project
    assert_no_difference("#{resource_class}.count") do
      post :create, params: new_params.merge(create_params)
    end
    assert_forbidden
  end

  def test_cannot_create_with_invalid_resource_params
    skip "Invalid resource param not defined" unless invalid_param.present?
    sign_in_and_set_project @accredited_user, @project

    assert_no_difference("#{resource_class}.count") do
      post :create, params: new_params.merge(create_params).deep_merge(invalid_param)
    end
    if invalid_param[resource_name].keys.any? { |key| 
          resource_class.defined_enums.key?(key.to_s) && 
          invalid_param[resource_name][key].present? && 
          !resource_class.defined_enums[key.to_s].include?(invalid_param[resource_name][key])
        }
      # Invalid enum values should raise conflict error
      assert_conflict
    # edge case to be considered: if the is an enum with a valid value, 
    # it will give odd results here. But that is a coding error...
    else
      # Regular validation errors should render form with errors
      assert_response :unprocessable_content
      assert_template :new
      assert flash.now[:alert].present?
    end
  end

  # Edit Action Tests - Success cases
  def test_accredited_user_can_access_edit_form
    sign_in_and_set_project @accredited_user, @project
    get :edit, params: { id: @resource.id }
    assert_response :success
  end

  # Edit Action Tests - Failure cases
  def test_team_member_cannot_access_edit_form
    sign_in_and_set_project @team_member, @project
    get :edit, params: { id: @resource.id }
    assert_forbidden
  end

  # Update Action Tests - Success cases
  def test_accredited_user_can_update
    sign_in_and_set_project @accredited_user, @project
    patch :update, params: update_params.deep_merge({ resource_name => { update_attribute_name => updated_attribute_value } }).merge({ id: @resource.id })
    assert_equal updated_attribute_value, @resource.reload.send(update_attribute_name)
    assert_redirected_to @resource
    assert_successful_update_flash_message
  end

  # Update Action Tests - Failure cases
  def test_team_member_cannot_update
    sign_in_and_set_project @team_member, @project
    original_value = @resource.send(update_attribute_name)
    patch :update, params: update_params.deep_merge({ resource_name => { update_attribute_name => updated_attribute_value } }).merge({ id: @resource.id })
    assert_forbidden
    assert_equal original_value, @resource.reload.send(update_attribute_name)
  end

  def test_accredited_user_cannot_update_with_invalid_params
    skip "Invalid resource param not defined" unless invalid_param.present?
    sign_in_and_set_project @accredited_user, @project
    original_value = @resource.send(update_attribute_name)
    patch :update, params: update_params.deep_merge(invalid_param).merge({ id: @resource.id })

    if invalid_param[resource_name].keys.any? { |key|
          resource_class.defined_enums.key?(key.to_s) &&
          invalid_param[resource_name][key].present? &&
          !resource_class.defined_enums[key.to_s].include?(invalid_param[resource_name][key])
        }
      # Invalid enum values should raise conflict error
      assert_conflict
    else
      # Regular validation errors should render form with errors
      assert_response :unprocessable_content
      assert_template :edit
      assert flash.now[:alert].present?
    end
    assert_equal original_value, @resource.reload.send(update_attribute_name)
  end

  # Destroy Action Tests - Success cases
  def test_admin_can_destroy
    sign_in_and_set_project @admin, @project
    assert_difference("#{resource_class}.count", -1) do
      delete :destroy, params: { id: @resource.id }
    end
    assert_redirected_to resource_index_path
    assert_successful_destroy_flash_message
  end

  # Destroy Action Tests - Failure cases
  def test_accredited_user_cannot_destroy
    sign_in_and_set_project @accredited_user, @project
    assert_no_difference("#{resource_class}.count") do
      delete :destroy, params: { id: @resource.id }
    end
    assert_forbidden
  end

  private
  
  # Helper methods

  def resource_class
   self.class.name.sub('ControllerTest', '').singularize.constantize
  end

  def resource_name
    # Convert class name to underscored symbol
    # e.g., "Electrical::Cable" -> :electrical_cable
    resource_class.model_name.param_key.to_sym
  end

  def resource_index_path
    args = @nesting ? [instance_variable_get(:"@#{@nesting}")] : []
    path_helper =
      if @nesting
        "#{@nesting}_#{resource_class.model_name.route_key}_path"
      else
        "#{resource_class.model_name.route_key}_path"
      end
      public_send(path_helper, *args)
  end

  # Including controller test can override
  def index_params
    # Handle both namespaced and non-namespaced resources
    if @nesting.in?(%i[tag document discipline project])
      # For nested routes: project_disciplines_path(@project)
      { "#{@nesting}_id": instance_variable_get(:"@#{@nesting}").id }
    else
      # For non-nested routes: no params
      {}
    end
  end

  # Including controller test can override
  def new_params
    # Handle both namespaced and non-namespaced resources
    if @nesting.in?(%i[tag document discipline project])
      # For nested routes: project_disciplines_path(@project)
      { "#{@nesting}_id": instance_variable_get(:"@#{@nesting}").id }
    else
      # For non-nested routes: no params
      {}
    end
  end

  # Allows new and create routes to be namespaced.
  def new_path
    # Handle both namespaced and non-namespaced resources
    if @nesting.in?(%i[tag document discipline project])
      # For nested routes: project_disciplines_path(@project)
      path_helper = "new_#{@nesting}_#{resource_class.model_name.param_key}_path(@#{nesting})"
      send(path_helper)
    else
      # For non-nested routes: disciplines_path
      path_helper = "#{resource_class.model_name.route_key}_path".to_sym
      send(path_helper)
    end
  end

  # Set the minimum required params for a valid resource
  def create_params
    raise NotImplementedError, "Including class must implement create_params"
  end

  # Some models have read only attributes, these need to be excluded from update tests
  # to avoid validation errors
  def update_params
    raise NotImplementedError, "Including class must implement update_params"
  end

  # Set an invalid resource param to test controller response
  def invalid_param
    raise NotImplementedError, "Including class must implement invalid_param"
  end
  
  # Nominate an attribute to get changed during update tests
  def update_attribute_name
    raise NotImplementedError, "Including class must implement update_attribute_name"
  end

  # Nominate a valid value to update the attribute to
  def updated_attribute_value
    raise NotImplementedError, "Including class must implement updated_attribute_value"
  end

  def assert_successful_create_flash_message
    resource_name = I18n.t("activerecord.models.#{resource_class.model_name.i18n_key}")
    resource_name = resource_name[:one] if resource_name.is_a?(Hash)
    expected = I18n.t('flash.create.notice',
      resource_name: resource_name)
    assert_flash_message :success, expected
  end

  def assert_successful_update_flash_message
    resource_name = I18n.t("activerecord.models.#{resource_class.model_name.i18n_key}")
    resource_name = resource_name[:one] if resource_name.is_a?(Hash)
    expected = I18n.t('flash.update.notice',
      resource_name: resource_name)
    assert_flash_message :success, expected
  end

  def assert_successful_destroy_flash_message
    resource_name = I18n.t("activerecord.models.#{resource_class.model_name.i18n_key}")
    resource_name = resource_name[:one] if resource_name.is_a?(Hash)
    expected = I18n.t('flash.destroy.notice',
      resource_name: resource_name)
    assert_flash_message :success, expected
  end
end
