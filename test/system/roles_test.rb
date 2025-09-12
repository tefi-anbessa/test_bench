require "application_system_test_case"

class RolesTest < ApplicationSystemTestCase
  include Devise::Test::IntegrationHelpers
    
  # Use JavaScript driver for tests that need it
  driven_by :selenium, using: :headless_chrome, screen_size: [1400, 1400]
  
  # [TODO: clean up this setup. It is copied from another resource. Project and current project are irrelevant to roles.]
  setup do
    # Create a project first to avoid reference issues
    @project = create(:project, code: 'AA', title: 'Test Project')
    
    # Create admin user with admin role using factory
    @admin = create(:user, :admin)
    
    # Create project owner user with project_owner role on the project
    @project_owner = create(:user)
    @project_owner.add_role(:project_owner, @project)
    
    # Create team member user with team_member role on the project
    @team_member = create(:user)
    @team_member.add_role(:team_member, @project)
    
    # Create regular user with no role on the project
    @regular_user = create(:user)
    
    # Ensure routes are loaded
    Rails.application.reload_routes_unless_loaded
  end

# Index view tests for global and resource wide roles
  test "regular user cannot access roles index" do
    sign_in @regular_user
    visit roles_path
    # Check for the specific error message in the rendered page
    assert_text 'not allowed to RolePolicy#index?'
    sign_out @regular_user
  end

  test "admin can view roles index" do
    sign_in @admin
    visit roles_path
    assert_selector "h2", text: I18n.t('roles.index.header')
    assert_selector "table tbody tr"
    sign_out @admin
  end
  
  test "admin cannot grant restricted role" do
    sign_in @admin
    visit roles_path
    
    # Select user
    select @team_member.name, from: 'role_user_id'
    select I18n.t('rolify.names.admin'), from: 'role_name'
    
    # Submit the form - should be denied
    assert_no_difference("@team_member.roles.count") do
      click_button I18n.t('actions.grant')
      sleep 0.1 # Give time for the request to complete
    end
    @team_member.reload
    refute @team_member.has_role?(:admin)
    # Check for the redirect to forbidden page
    assert_selector 'h1', text: I18n.t('errors.forbidden.header')
    sign_out @admin
  end
  
  test "admin can grant functional role to user" do
    sign_in @admin
    visit roles_path
    
    # Select user
    select @regular_user.name, from: 'role_user_id'
    
    # Get available functional roles
    functional_roles = Role.valid_roles_for(nil).select { |r| Role.functional_roles.include?(r) }
    assert_not_empty functional_roles, "No functional roles available"
    
    # Select the first available functional role
    role_name = functional_roles.first
    select I18n.t("rolify.names.#{role_name}"), from: 'role_name'
    
    # Submit the form and verify role assignment
    assert_difference('@regular_user.roles.count', 1) do
      click_button I18n.t('actions.grant')
      sleep 0.1 # Give time for the request to complete
    end
    
    assert_text I18n.t('rolify.flash.granted', role_type: I18n.t('rolify.role_types.global'))
    @regular_user.reload
    assert @regular_user.has_role?(role_name.to_sym)
    sign_out @admin
  end
  
  test "admin can revoke role" do
    sign_in @admin
    
    # Clear any existing roles to avoid interference
    @team_member.roles.destroy_all
    
    # Assign a role to a user
    @team_member.add_role(:electrical_designer)
    assert @team_member.has_role?(:electrical_designer), "Role should be assigned before test"
    
    visit roles_path
    
    # Ensure the page has loaded the roles table
    assert_selector 'table#roles', wait: 5
    
    # Find the row containing the role we just created
    role_row = nil
    all('table#roles tbody tr').each do |row|
      if row.has_text?('electrical_designer') && row.has_text?(@team_member.name)
        role_row = row
        break
      end
    end
    
    assert role_row, "Could not find role assignment row for user #{@team_member.name}"
    
    # Find and click the delete button
    delete_button = role_row.find('a[data-turbo-method="delete"]')
    
    # Accept the confirmation dialog and click the delete button
    accept_confirm do
      delete_button.click
    end
    
    # Check for success message
    assert_text I18n.t('rolify.flash.revoked', role_type: I18n.t('rolify.role_types.global')), wait: 0.5
    
    # Verify the role was revoked
    @team_member.reload
    refute @team_member.has_role?(:electrical_designer), "Expected global role to be revoked"
    
    sign_out @admin
  end
  
  test "cannot assign duplicate global roles" do
    # First assign the role
    @team_member.grant(:electrical_designer)
    sign_in @admin
    visit roles_path
    
    # Try to assign the same role again
    select @team_member.name, from: 'role_user_id'
    select I18n.t('rolify.names.electrical_designer'), from: 'role_name'
    
    # Submit the form - Rolify will silently ignore the duplicate
    assert_no_difference('@team_member.roles.count') do
      click_button I18n.t('actions.grant')
      sleep 0.1 # Give time for the request to complete
    end
    
    # No error message: rolify ignores duplicate roles [TODO: possibly catch this in the controller to show a message]
    # assert_text I18n.t('flash.roles.failed_to_grant', role_type: I18n.t('flash.role_types.global'))
    sign_out @admin
  end
  
  test "admin cannot assign role with blank user" do
    sign_in @admin
    visit roles_path
    
    assert_no_difference('Role.count') do
      # Submit without required user field
      click_button I18n.t('actions.grant')
    end
    
    # Should still be on the new role page with flash message
    assert_current_path roles_path
    # Defer error message checks as html form validation is preventing the error getting to the controller.
    # assert_selector '.alert.alert-warning', text: I18n.t('rolify.flash.user_id_blank')

    sign_out @admin
  end
  
  test "shows errors for blank role name submission" do
    sign_in @admin
    visit roles_path
    select @team_member.name, from: 'role_user_id'
    
    # Submit without required name field
    click_button I18n.t('actions.grant')
    
    # Should still be on the new role page with flash message
    assert_current_path roles_path
    # Defer error message checks as html form validation is preventing the error getting to the controller.
    # assert_selector '.alert.alert-warning', text: I18n.t('rolify.flash.name_blank')

    sign_out @admin
  end

  # Resource instance roles view and assignment tests
  test "admin can see roles partial on resource edit form" do
    sign_in @admin
    visit edit_project_path(@project)
    
    assert_selector "h4", text: I18n.t('roles.new.title')
    sign_out @admin
  end

  test "project owner can see roles partial on resource edit form" do
    sign_in @project_owner
    visit edit_project_path(@project)
    
    assert_selector "h4", text: I18n.t('roles.new.title')
    sign_out @project_owner
  end

  test "project owner can assign team_member role on own project" do
    sign_in @project_owner
    visit edit_project_path(@project)
    
    select @regular_user.name, from: 'role_user_id'
    select I18n.t('rolify.names.team_member'), from: 'role_name'
        
    # Submit the form and verify role assignment
    assert_difference('@regular_user.roles.count', 1) do
      click_button I18n.t('actions.grant')
      sleep 0.1 # Give time for the request to complete
    end
    # Check the flash message
    assert_text I18n.t('rolify.flash.granted', role_type: I18n.t('rolify.role_types.resource_instance'))
    
    sign_out @project_owner
  end
end
