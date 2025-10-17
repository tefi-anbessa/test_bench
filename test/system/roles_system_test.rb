require "application_system_test_case"

class RolesTest < ApplicationSystemTestCase
  include Devise::Test::IntegrationHelpers
    
  # Use JavaScript driver for tests that need it
  driven_by :selenium, using: :headless_chrome, screen_size: [1400, 1400]
  
  setup do
    # Create a project first to avoid reference issues
    @project = create(:project, code: 'AA', title: 'Test Project')
    
    # Create admin user with admin role using factory
    @admin = create(:user, :admin)
    
    # Create project manager user with project_manager role on the project
    @project_manager = create(:user)
    @project_manager.grant(:project_manager, @project)
    
    # Create team member user with team_member role on the project
    @team_member = create(:user)
    @team_member.grant(:team_member, @project)
    
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
    assert_selector "h3", text: I18n.t('roles.index.header')
    assert_selector "#roles-index"
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
      end
    @team_member.reload
    refute @team_member.has_role?(:admin)
    assert_selector 'h1', text: I18n.t('errors.forbidden.header')
    sign_out @admin
  end
  
  test "admin can grant functional role to user" do
    # Use a valid functional role from constants
    role_name = 'electrical_designer'  # From config/constants/role.yml
    
    sign_in @admin
    visit roles_path
    
    # Wait for the page to load
    assert_selector 'h3', text: I18n.t('roles.index.header')
    
    # Select the user and role
    select @regular_user.name, from: 'role_user_id'
    role_display_name = I18n.t("rolify.names.#{role_name}", default: role_name.to_s.humanize)
    select role_display_name, from: 'role_name'
    
    # Submit the form and verify role assignment
    assert_difference('@regular_user.roles.count', 1) do
      click_button I18n.t('actions.grant')
      
      # Wait for the AJAX request to complete by checking for the success flash message
      assert_text I18n.t('rolify.flash.granted', role_type: I18n.t('rolify.role_types.global')), wait: 10
      
      # Ensure the user is reloaded to get the latest state
      @regular_user.reload
    end
    
    # Verify the result
    assert @regular_user.has_role?(role_name.to_sym), "User should have the #{role_name} role"
    
    sign_out @admin
  end
  
  test "admin can revoke role" do
    sign_in @admin
    
    # Clear any existing roles to avoid interference
    @team_member.roles.destroy_all
    
    # Get the translated role name from the locale file
    role_name = :electrical_designer
    translated_role = I18n.t("rolify.names.#{role_name}")
    
    # Assign a role to a user
    @team_member.add_role(role_name)
    assert @team_member.has_role?(role_name), "Role should be assigned before test"
    
    visit roles_path
    
    # Ensure the page has loaded the roles table
    assert_selector '#roles-index', wait: 5
    
    
    # Find the row with the role and user using the translated role name
    role_row = nil
    all('.row.g-1.mb-1').each do |row|
      if row.has_text?(translated_role, wait: 0) && row.has_text?(@team_member.name, wait: 0)
        role_row = row
        break
      end
    end
    
    # Fallback to raw role name if not found with translation
    unless role_row
      all('.row.g-1.mb-1').each do |row|
        if row.has_text?(role_name.to_s.humanize, wait: 0) && row.has_text?(@team_member.name, wait: 0)
          role_row = row
          break
        end
      end
    end
    
    assert role_row, "Could not find role assignment row for user #{@team_member.name} with role #{translated_role} (#{role_name})"
    
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
      end
    
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

    sign_out @admin
  end

  # Resource instance roles view and assignment tests
  test "admin can see roles partial on resource edit form" do
    sign_in @admin
    visit edit_project_path(@project)
    
    assert_selector "h5", text: I18n.t('roles.new.title')
    sign_out @admin
  end
  
  test "project manager can see roles partial on resource edit form" do
    sign_in @project_manager
    visit edit_project_path(@project)
    
    # Wait for the page to load and the form to be ready
    assert_selector 'h5', text: I18n.t('roles.new.title')
    sign_out @project_manager
  end

  # AI wrote this huge test, it took ages to debug and it doesn't look robust. Take care.
  test "project manager can assign team_member role on project" do
    # Ensure all users are created and persisted
    assert @project_manager.persisted?, "Project manager should be persisted"
    assert @regular_user.persisted?, "Regular user should be persisted"
    
    # Ensure project manager has the project_manager role on the project
    assert @project_manager.has_role?(:project_manager, @project), 
           "Project manager should have project_manager role on project"
    
    # Sign in as project manager and navigate to project roles
    sign_in @project_manager
    visit edit_project_path(@project)
    
    # Wait for the page to load and the form to be ready
    assert_selector 'h5', text: I18n.t('roles.new.title')
    
    # Wait for the form to be interactive and find it by action
    form = find('form[action*="/roles"]', wait: 10)
    
    # Wait for the user select to be present and enabled
    within form do
      # Wait for the user select to be present and enabled
      assert_selector 'select[name="role[user_id]"]:not([disabled])', wait: 10
      
      # Wait for the dropdown to be populated with users (excluding the current user)
      user_options = all('select[name="role[user_id]"] option').map { |opt| [opt.text, opt.value] }
      
      # Check if the regular user is in the dropdown
      assert_includes user_options.map(&:first), @regular_user.name, "Regular user should be in the dropdown"
      
      # Select the user
      select @regular_user.name, from: 'role[user_id]'
      
      # Wait for the role select to be present and enabled
      assert_selector 'select[name="role[name]"]:not([disabled])', wait: 10
      
      # Select the role
      select I18n.t('rolify.names.team_member'), from: 'role[name]', match: :first
      user_id = find('select[name="role[user_id]"]').value
      selected_user = User.find(user_id)

sleep 0.1  # Allow async role assignment to complete

      # Submit the form and verify role assignment
      assert_difference('selected_user.roles.count', 1) do
        click_button I18n.t('actions.grant')
        # Wait for the AJAX request to complete
        assert_no_selector '.spinner-border', wait: 10
      end
    end
    
    # Check the flash message
    assert_text I18n.t('rolify.flash.granted', role_type: I18n.t('rolify.role_types.resource_instance')), wait: 10
    
    sign_out @project_manager
  end
end
