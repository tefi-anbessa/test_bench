
# This module provides common test patterns for tagable controllers
# Include this in your controller test and call the test methods you need
module TagableTestPatterns
  extend ActiveSupport::Concern

  # Setup common to all tagable controllers
  def setup_common_test_data
    @project = create(:project)
    set_current_project(@project)

    @regular_user = create(:user)   # No roles

    @admin = create(:user)
    @admin.grant(:admin)

    @project_manager = create(:user)
    @project_manager.grant(:project_manager, @project)

    @team_member = create(:user)
    @team_member.grant(:team_member, @project)

    # Factory default unique tag will be "A:AA-0001"
    @gp_tag = create(:tag, :unique_tag, project: @project, discipline: @resource_discipline)
    @request.env["devise.mapping"] = Devise.mappings[:user]
  end

  # Common test patterns that work for all tagable controllers

  def test_common_setup_is_valid
    assert @project.valid?
    assert @project.persisted?
    assert @admin.valid?
    assert @admin.persisted?
    assert @project_manager.valid?
    assert @project_manager.persisted?
    assert @team_member.valid?
    assert @team_member.persisted?
    assert @regular_user.valid?
    assert @regular_user.persisted?
    assert @gp_tag.valid?
    assert @gp_tag.persisted?
  end

  # Check validity of instance variables that are required but values are set in model specific setup
  def test_model_specific_general_setup_is_valid
    assert @resource_discipline.valid?
    assert @resource_discipline.persisted?
    assert @accredited_team_member
    assert @accredited_team_member.persisted?
    assert @assigned_tag.valid?
    assert @assigned_tag.persisted?
    assert @unassigned_tag.valid?
    assert @unassigned_tag.persisted?
    assert @resource.valid?
    assert @resource.persisted?
    refute_equal @wrong_tagable_type, resource_class.name
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
    get :new, params: { tag_id: @unassigned_tag.id }
    assert_response :forbidden
  end

  def test_accredited_team_member_can_access_new_form_for_existing_unassigned_tag
    sign_in @accredited_team_member
    get :new, params: { tag_id: @unassigned_tag.id }
    assert_response :success
  end

  def test_accredited_team_member_can_access_new_form_with_no_tag
    sign_in @accredited_team_member
    get :new
    assert_response :success
  end

  # Create Action Tests - Success Cases
  def test_accredited_team_member_can_create_with_existing_unassigned_tag
    sign_in @accredited_team_member
    assert_difference("#{resource_class}.count", 1) do
      post :create, params: params_with_existing_tag
    end

    @unassigned_tag.reload
    created_resource = @unassigned_tag.tagable
    assert_redirected_to resource_path(created_resource)
    assert_successful_assignment_flash_message(created_resource)
  end

  def test_accredited_team_member_can_create_new_resource_and_tag
    sign_in @accredited_team_member
    # [TODO] add check of tag count as well
    assert_difference("#{resource_class}.count", 1) do
      post :create, params: params_with_new_tag
    end

    # Find the created resource and tag
    created_tag = Tag.find_by(params_with_new_tag[resource_name][:tag])
    created_resource = created_tag.tagable
    assert_redirected_to resource_path(created_resource)
    assert_successful_creation_flash_message(created_resource, created_tag)
  end

  # Create Action Tests - Failure Cases
  def test_team_member_cannot_create
    sign_in @team_member
    assert_no_difference("#{resource_class}.count") do
      post :create, params: params_with_existing_tag
    end
    assert_forbidden
  end

  def test_cannot_create_with_tag_that_is_not_in_the_database
    sign_in @accredited_team_member
    assert_no_difference("#{resource_class}.count") do
      post :create, params: params_with_existing_tag.merge(tag_id: 99)
    end
    assert_conflict
  end

  def test_cannot_create_with_already_assigned_tag
    sign_in @accredited_team_member
    assert_no_difference("#{resource_class}.count") do
      post :create, params: params_with_existing_tag.merge(tag_id: @assigned_tag.id)
    end
    assert_conflict
  end

  def test_cannot_create_with_wrong_tagable_type
    sign_in @accredited_team_member
    @unassigned_tag.update(tagable_type: wrong_tagable_type)
    assert_no_difference("#{resource_class}.count") do
      post :create, params: params_with_existing_tag.merge(tag_id: @unassigned_tag.id)
    end
    assert_conflict
  end

  def test_cannot_create_with_existing_tag_and_invalid_resource_params
    skip "Invalid resource params not defined" unless invalid_resource_params.present?
    sign_in @accredited_team_member

    if invalid_resource_params.keys.any? { |key| resource_class.defined_enums.key?(key.to_s) }
      # Invalid enum values should raise conflict error
        assert_no_difference("#{resource_class}.count") do
          post :create, params: params_with_new_tag.deep_merge(resource_name => invalid_resource_params)
        end
        assert_conflict
    else
      # Regular validation errors should render form with errors
      assert_no_difference("#{resource_class}.count") do
        post :create, params: params_with_existing_tag.deep_merge(resource_name => invalid_resource_params)
      end
      assert_response :unprocessable_content
      assert_template :new
      assert flash.now[:alert].present?
    end
  end

  def test_cannot_create_both_with_invalid_new_tag
    sign_in @accredited_team_member
    assert_no_difference("#{resource_class}.count") do
      post :create, params: params_with_new_tag.deep_merge(resource_name => { tag: { stage: nil } })
    end
    assert_response :unprocessable_content
    assert_template :new
    assert flash.now[:alert].present?
  end

  def test_cannot_create_both_with_invalid_resource
    skip "Invalid resource params not defined" unless invalid_resource_params.present?
    sign_in @accredited_team_member

    if invalid_resource_params.keys.any? { |key| resource_class.defined_enums.key?(key.to_s) }
      # Invalid enum values should return conflict response
      assert_no_difference("#{resource_class}.count") do
        post :create, params: params_with_new_tag.deep_merge(resource_name => invalid_resource_params)
      end
      assert_conflict
    else
      # Regular validation errors should render form with errors
      assert_no_difference("#{resource_class}.count") do
        post :create, params: params_with_new_tag.deep_merge(resource_name => invalid_resource_params)
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
    patch :update, params: update_params(original_value)
    assert_forbidden
  end

  def test_accredited_team_member_can_update
    sign_in @accredited_team_member
    patch :update, params: update_params(updated_attribute_value)
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
    # Extract the controller name from the test class name
    test_class_name = self.class.name
    resource_name = test_class_name.gsub('ControllerTest', '')
    resource_name.classify.constantize
  end

  def resource_name
    resource_class.to_s.underscore.to_sym
  end

  def resource_path(resource)
    send("#{resource_name}_path", resource)
  end

  def resource_index_path
    # Use resource name to construct the index path
    send("#{resource_name}s_path")
  end

  # These methods must be implemented by the including test class
  def params_with_existing_tag
    raise NotImplementedError, "Including class must implement params_with_existing_tag"
  end

  def params_with_new_tag
    raise NotImplementedError, "Including class must implement params_with_new_tag"
  end

  def params_with_invalid_tag_id
    params_with_existing_tag.merge(tag_id: 99999)
  end

  def create_params_with_assigned_tag
    { tag_id: @assigned_tag.id, resource_name => valid_resource_params }
  end

  def wrong_tagable_type
    # Return a different tagable type for testing
    (resource_class.to_s == "Motor") ? "Switchboard" : "Motor"
  end

  def valid_resource_params
    raise NotImplementedError, "Including class must implement valid_resource_params"
  end

  def updated_attribute_value(original_value)
    raise NotImplementedError, "Including class must implement updated_attribute_value"
  end

  def update_params(new_value)
    { id: @resource.id, resource_name => { update_attribute_name => new_value } }
  end

  def setup_model_specific_data
    # Override in including class for model-specific setup (e.g., cable_types)
  end

  def setup_tags_and_resources
    # Override in including class to create tags and resources with specific attributes
  end

  # Flash message helpers
  def assert_successful_assignment_flash_message(resource)
    expected = I18n.t('flash.tagables.assigned_to',
      tag: @unassigned_tag.full_tag,
      resource_name: resource_class.model_name.human,
      id: resource.id)
    assert_equal expected, flash[:success]
  end

  def assert_successful_creation_flash_message(resource, tag)
    expected = I18n.t('flash.tagables.created_and_assigned',
      tag: tag.full_tag,
      resource_name: resource_class.model_name.human,
      id: resource.id)
    assert_equal expected, flash[:success]
  end

  def assert_successful_update_flash_message
    expected = I18n.t('flash.actions.update.notice',
      resource_name: resource_class.model_name.human)
    assert_equal expected, flash[:success]
  end

  def assert_successful_destroy_flash_message
    expected = I18n.t('flash.actions.destroy.notice',
      resource_name: resource_class.model_name.human)
    assert_equal expected, flash[:success]
  end
end
