# frozen_string_literal: true
require "test_helper"
require_relative "test_setup_helpers"
# This module provides common tests for tagable controllers.
# Include this in your controller test and all the test methods will run.
module TagableControllerTests
  extend ActiveSupport::Concern
  include TestSetupHelpers

  # Setup common to all tagable controllers
  def setup_common_test_data
    setup_projects_and_users
    setup_disciplines
    setup_accredited_users
    # Set up existing tags with associated resources 
    # for index, show, edit, update, destroy tests
    # # Set up an unassigned tag for new and create tests
    setup_tags
    setup_tagable_resources
    # Set a class name that is not the current resource class for testing type check
    @wrong_tagable_type = resource_class.name == "Electrical::Switchboard" ?
     "Electrical::Motor" : 
     "Electrical::Switchboard"
    @request.env["devise.mapping"] = Devise.mappings[:user]
  end

  # Common test patterns used for all tagable controller tests
  def test_common_setup_is_valid
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
    assert @accredited_user
    assert @accredited_user.persisted?
    assert @tag.valid?
    assert @tag.persisted?
    assert @unassigned_tag.valid?
    assert @unassigned_tag.persisted?
    assert @resource.valid?
    assert @resource.persisted?
    refute_equal @wrong_tagable_type, resource_class.name
  end

  def test_unauthenticated_users_are_redirected_to_sign_in
    get :index, params: { discipline_id: @discipline.id }
    assert_unauthenticated
  end

  def test_regular_user_cannot_access_index
    sign_in_and_set_project(@regular_user, @project)
    get :index, params: { discipline_id: @discipline.id }
    assert_conflict # out of scope
  end

  def test_team_member_can_access_index
    sign_in_and_set_project(@team_member, @project)
    get :index, params: { discipline_id: @discipline.id }
    assert_response :success
  end

  # Show Tests
  def test_user_cannot_view_resource_details_without_project_role
    sign_in_and_set_project(@regular_user, @project)
    get :show, params: { id: @resource.id }
    # Raises conflict due to out of scope resource before authorization check
    assert_conflict
  end

  def test_team_member_can_view_resource_details
    sign_in_and_set_project(@team_member, @project)
    get :show, params: { id: @resource.id }
    assert_response :success
  end

  # New Action Tests
  def test_team_member_cannot_access_new_form
    sign_in_and_set_project(@team_member, @project)
    get :new, params: { tag_id: @unassigned_tag.id }
    assert_response :forbidden
  end

  def test_accredited_user_can_access_new_form_for_existing_unassigned_tag
    sign_in_and_set_project(@accredited_user, @project)
    get :new, params: { tag_id: @unassigned_tag.id }
    assert_response :success
  end

  def test_accredited_user_can_access_new_form_with_no_tag
    sign_in_and_set_project(@accredited_user, @project)
    get :new, params: { discipline_id: @discipline.id }
    assert_response :success
  end

  # Create Action Tests - Success Cases
  def test_accredited_user_can_create_with_existing_unassigned_tag
    sign_in_and_set_project(@accredited_user, @project)
    assert_difference("#{resource_class}.count", 1) do
      post :create, params: params_with_existing_tag
    end

    @unassigned_tag.reload
    created_resource = @unassigned_tag.tagable
    assert_redirected_to created_resource
    assert_successful_assignment_flash_message(created_resource)
  end

  def test_accredited_user_can_create_new_resource_and_tag
    sign_in_and_set_project(@accredited_user, @project)
    before_tag_count = Tag.count
    assert_difference("#{resource_class}.count", 1) do
      post :create, params: params_with_new_tag
    end
    assert_equal Tag.count, before_tag_count + 1
    # Find the created resource and tag
    created_tag = Tag.find_by(params_with_new_tag[resource_name][:tag].merge(tagable_type: resource_class.name).except(:tagable_id))
    assert_redirected_to created_tag.tagable
    assert_successful_creation_flash_message(created_tag.tagable, created_tag)
  end

  # Create Action Tests - Failure Cases
  def test_team_member_cannot_create
    sign_in_and_set_project(@team_member, @project)
    assert_no_difference("#{resource_class}.count") do
      post :create, params: params_with_existing_tag
    end
    assert_forbidden
  end

  def test_cannot_create_with_tag_that_is_not_in_the_database
    sign_in_and_set_project(@accredited_user, @project)
    assert_no_difference("#{resource_class}.count") do
      post :create, params: params_with_existing_tag.deep_merge(tag_id: 9999)
    end
    assert_conflict
  end

  def test_cannot_create_with_already_assigned_tag
    sign_in_and_set_project(@accredited_user, @project)
    assert_no_difference("#{resource_class}.count") do
      post :create, params: params_with_existing_tag.deep_merge(tag_id: @tag.id)
    end
    assert_conflict
  end

  def test_cannot_create_with_wrong_tagable_type
    sign_in_and_set_project(@accredited_user, @project)
    @unassigned_tag.update(tagable_type: @wrong_tagable_type)
    assert_no_difference("#{resource_class}.count") do
      post :create, params: params_with_existing_tag
    end
    assert_conflict
  end

  def test_cannot_create_with_existing_tag_and_invalid_param
    skip "Invalid param not defined" unless invalid_param.present?
    sign_in_and_set_project(@accredited_user, @project)
    assert_no_difference("#{resource_class}.count") do
      post :create, params: params_with_new_tag.deep_merge(resource_name => invalid_param)
    end

    if invalid_param.keys.any? { |key| 
          resource_class.defined_enums.key?(key.to_s) && 
          invalid_param[key].present? && 
          !resource_class.defined_enums[key.to_s].include?(invalid_param[key])
        }
      # Invalid enum values should raise conflict error
      assert_conflict
    else
      # Regular validation errors should render form with errors
      assert_response :unprocessable_content
      assert_template :new
      assert flash.now[:alert].present?
    end
  end

  def test_cannot_create_both_with_invalid_new_tag
    sign_in_and_set_project(@accredited_user, @project)
    assert_no_difference("#{resource_class}.count") do
      post :create, params: params_with_new_tag.deep_merge(resource_name => { tag: { stage: nil } })
    end
    assert_response :unprocessable_content
    assert_template :new
    assert flash.now[:alert].present?
  end

  def test_cannot_create_both_with_invalid_resource
    skip "Invalid param not defined" unless invalid_param.present?
    sign_in_and_set_project(@accredited_user, @project)
    assert_no_difference("#{resource_class}.count") do
      post :create, params: params_with_new_tag.deep_merge(resource_name => invalid_param)
    end
    if invalid_param.keys.any? { |key| 
          resource_class.defined_enums.key?(key.to_s) && 
          invalid_param[key].present? && 
          !resource_class.defined_enums[key.to_s].include?(invalid_param[key])
        }
      # Invalid enum values should return conflict response
      assert_conflict
    else
      # Regular validation errors should render form with errors
      assert_response :unprocessable_content
      assert_template :new
      assert flash.now[:alert].present?
    end
  end

  # Edit Action Tests
  def test_team_member_cannot_access_edit_form
    sign_in_and_set_project(@team_member, @project)
    get :edit, params: { id: @resource.id }
    assert_forbidden
  end

  def test_accredited_user_can_access_edit_form
    sign_in_and_set_project(@accredited_user, @project)
    get :edit, params: { id: @resource.id }
    assert_response :success
  end

  # Update Action Tests - Success case
  def test_accredited_user_can_update
    sign_in_and_set_project(@accredited_user, @project)
    patch :update, params: 
      { id: @resource.id, resource_name => { update_attribute_name => updated_attribute_value } }
    assert_equal updated_attribute_value, @resource.reload.send(update_attribute_name)
    assert_redirected_to resource_path(@resource)
    assert_successful_update_flash_message
  end

  # Update Action Tests - Failure cases
  def test_team_member_cannot_update
    sign_in_and_set_project(@team_member, @project)
    original_value = @resource.send(update_attribute_name)
    patch :update, params: 
      { id: @resource.id, resource_name => { update_attribute_name => updated_attribute_value } }
    assert_forbidden
    assert_equal original_value, @resource.reload.send(update_attribute_name)
  end

  def test_accredited_user_cannot_update_with_invalid_param
    skip "Invalid param not defined" unless invalid_param.present?
    sign_in_and_set_project(@accredited_user, @project)
    original_value = @resource.send(update_attribute_name)
    patch :update, params: 
      { id: @resource.id, resource_name => { update_attribute_name => updated_attribute_value }.merge(invalid_param) }

    if invalid_param.keys.any? { |key|
          resource_class.defined_enums.key?(key.to_s) &&
          invalid_param[key].present? &&
          !resource_class.defined_enums[key.to_s].include?(invalid_param[key])
        }
      # Invalid enum values should return conflict response
      assert_conflict
    else
      # Regular validation errors should render form with errors
      assert_response :unprocessable_content
      assert_template :edit
      assert flash.now[:alert].present?
    end
    assert_equal original_value, @resource.reload.send(update_attribute_name)
  end

  # Destroy Action Tests
  def test_accredited_user_cannot_destroy
    sign_in_and_set_project(@accredited_user, @project)
    assert_no_difference("#{resource_class}.count") do
      delete :destroy, params: { id: @resource.id }
    end
    assert_forbidden
  end

  def test_admin_can_destroy
    sign_in_and_set_project(@admin, @project)
    assert_difference("#{resource_class}.count", -1) do
      delete :destroy, params: { id: @resource.id }
    end
    assert_redirected_to resource_index_path
    assert_successful_destroy_flash_message
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

    def resource_path(resource)
      # Use the underscored resource name for path helpers
      # e.g., :electrical_cable -> :electrical_cable_path
      path_helper = "#{resource.model_name.singular_route_key}_path"
      send(path_helper, resource)
    end

    def resource_index_path
      # Handle both namespaced and non-namespaced resources
      send("discipline_#{resource_name.to_s.pluralize}_path", @discipline)
    end

    def new_tag_params
      { tag: { discipline_id: @discipline.id, 
        prefix: 'TEST',
        serial: 123,
        suffix: '', 
        service: 'TEST', 
        stage: 1, 
        location: 'TEST', 
        notes: 'TEST', 
        tagable_id: nil, 
        tagable_type: nil } }
    end

    # These methods may be overridden by the including test class
    def params_with_existing_tag
      { tag_id: @unassigned_tag.id, resource_name => create_params }
    end

    # [TODO] - a more reliable way of generating a unique serial number would be a good idea.
    def params_with_new_tag
      { discipline_id: @discipline.id, resource_name => create_params.merge(new_tag_params) }
    end

    def create_params
      raise NotImplementedError, "Including class must implement create_params"
    end

    def invalid_param
      raise NotImplementedError, "Including class must implement invalid_param"
    end

    def updated_attribute_value(original_value)
      raise NotImplementedError, "Including class must implement updated_attribute_value"
    end

    def update_param
      raise NotImplementedError, "Including class must implement update_param"
    end

    def setup_model_specific_data
      # Override in including class for model-specific setup (e.g., cable_types)
    end

    # Flash message helpers
    def assert_successful_assignment_flash_message(resource)
      expected = I18n.t('flash.tagables.assigned_to',
        tag: @unassigned_tag.full_tag,
        resource_name: I18n.t("activerecord.models.#{resource_class.model_name.i18n_key}.one"),
        id: resource.id)
      assert_flash_message :success, expected
    end

    def assert_successful_creation_flash_message(resource, tag)
      expected = I18n.t('flash.tagables.created_and_assigned',
        tag: tag.full_tag,
        resource_name: I18n.t("activerecord.models.#{resource_class.model_name.i18n_key}.one"),
        id: resource.id)
      assert_flash_message :success, expected
    end

    def assert_successful_update_flash_message
      expected = I18n.t('flash.update.notice',
        resource_name: I18n.t("activerecord.models.#{resource_class.model_name.i18n_key}.one"))
      assert_flash_message :success, expected
    end

    def assert_successful_destroy_flash_message
      expected = I18n.t('flash.destroy.notice',
        resource_name: I18n.t("activerecord.models.#{resource_class.model_name.i18n_key}.one"))
      assert_flash_message :success, expected
    end
end
