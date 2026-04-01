
# This module provides common test patterns for tagable controllers.
# Include this in your controller test and all the test methods will run.
module TagableTestPatterns
  extend ActiveSupport::Concern

  # Setup common to all tagable controllers
  def setup_common_test_data
    @project = create(:project)
    set_current_project(@project)

    @resource_discipline = create(:discipline, name: resource_class.discipline, project: @project)

    @regular_user = create(:user)   # No roles

    @admin = create(:user)
    @admin.grant(:admin)

    @project_manager = create(:user)
    @project_manager.grant(:project_manager, @project)

    @team_member = create(:user)
    @team_member.grant(:team_member, @project)

    # Factory default unique tag will be "A:AA-0001"
    @assigned_tag = create(:tag, :unique_tag, discipline: @resource_discipline, 
      service: "ASSIGNED TAG", stage: 1)
    @request.env["devise.mapping"] = Devise.mappings[:user]
  end

  # Common code for all models, but values are model specific
  def setup_tags_and_resources
    # Set up a user with edit permissions on this resource.
    @accredited_team_member = create(:user)
    @accredited_team_member.grant(:team_member, @project)
    @accredited_team_member.grant(resource_class.required_role)
    # Set up an existing tag with associated resource for index, show, edit, update, destroy tests
    @assigned_tag = create(:tag, serial: 1001, discipline: @resource_discipline)
    @resource = create(resource_class.model_name.singular, tag: @assigned_tag)
    # Set up an unassigned tag for create and update tests
    @unassigned_tag = create(:tag, serial: 1002,  discipline: @resource_discipline, 
      service: "UNASSIGNED TAG", stage: 1)
    # Set a class name that is not the current resource class for testing type check
    @wrong_tagable_type = resource_class.name == "Electrical::Switchboard" ?
     "Electrical::Motor" : 
     "Electrical::Switchboard"
  end

  # Common test patterns used for all tagable controller tests
  def test_common_setup_is_valid
    assert @project.valid?
    assert @project.persisted?
    assert @resource_discipline.valid?
    assert @resource_discipline.persisted?
    assert @admin.valid?
    assert @admin.persisted?
    assert @project_manager.valid?
    assert @project_manager.persisted?
    assert @team_member.valid?
    assert @team_member.persisted?
    assert @regular_user.valid?
    assert @regular_user.persisted?
    assert @assigned_tag.valid?
    assert @assigned_tag.persisted?
  end

  # Check validity of instance variables that are required but values are set in model specific setup
  def test_model_specific_general_setup_is_valid
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
    assert_redirected_to created_resource
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
    assert_redirected_to created_resource
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
      post :create, params: params_with_existing_tag.deep_merge(tag_id: 9999)
    end
    assert_conflict
  end

  def test_cannot_create_with_already_assigned_tag
    sign_in @accredited_team_member
    assert_no_difference("#{resource_class}.count") do
      post :create, params: params_with_existing_tag.deep_merge(tag_id: @assigned_tag.id)
    end
    assert_conflict
  end

  def test_cannot_create_with_wrong_tagable_type
    sign_in @accredited_team_member
    @unassigned_tag.update(tagable_type: @wrong_tagable_type)
    assert_no_difference("#{resource_class}.count") do
      post :create, params: params_with_existing_tag.deep_merge(tag_id: @unassigned_tag.id)
    end
    assert_conflict
  end

  def test_cannot_create_with_existing_tag_and_invalid_resource_params
    skip "Invalid resource params not defined" unless invalid_resource_params.present?
    sign_in @accredited_team_member

    if invalid_resource_params.keys.any? { |key| 
          resource_class.defined_enums.key?(key.to_s) && 
          invalid_resource_params[key].present? && 
          !resource_class.defined_enums[key.to_s].include?(invalid_resource_params[key])
        }
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
    if invalid_resource_params.keys.any? { |key| 
          resource_class.defined_enums.key?(key.to_s) && 
          invalid_resource_params[key].present? && 
          !resource_class.defined_enums[key.to_s].include?(invalid_resource_params[key])
        }
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
    patch :update, params: 
      { id: @resource.id, resource_name => { update_attribute_name => updated_attribute_value } }
    assert_forbidden
    assert_equal original_value, @resource.reload.send(update_attribute_name)
  end

  def test_accredited_team_member_can_update
    sign_in @accredited_team_member
    patch :update, params: 
      { id: @resource.id, resource_name => { update_attribute_name => updated_attribute_value } }
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

  # These methods may be overridden by the including test class
  def params_with_existing_tag
    { tag_id: @unassigned_tag.id, resource_name => valid_resource_params }
  end

  # [TODO] - a more reliable way of generating a unique serial number would be a good idea.
  def params_with_new_tag
    { resource_name => { tag: { prefix: @assigned_tag.prefix,
                                discipline_id: @resource_discipline.id,
                                serial: @assigned_tag.serial + 111,
                                suffix: '',
                                service: 'Test motor',
                                stage: 1 }, **valid_resource_params } }
  end

  def params_with_invalid_tag_id
    params_with_existing_tag.merge(tag_id: 99999)
  end

  def create_params_with_assigned_tag
    { tag_id: @assigned_tag.id, resource_name => valid_resource_params }
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

  def setup_model_specific_data
    # Override in including class for model-specific setup (e.g., cable_types)
  end

  # Flash message helpers
  def assert_successful_assignment_flash_message(resource)
    expected = I18n.t('flash.tagables.assigned_to',
      tag: @unassigned_tag.full_tag,
      resource_name: resource_class.model_name.human,
      id: resource.id)
    assert_flash_message :success, expected
  end

  def assert_successful_creation_flash_message(resource, tag)
    expected = I18n.t('flash.tagables.created_and_assigned',
      tag: tag.full_tag,
      resource_name: resource_class.model_name.human,
      id: resource.id)
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
