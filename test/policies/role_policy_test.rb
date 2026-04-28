require 'test_helper'
require 'helpers/test_setup_helpers'

class RolePolicyTest < ActiveSupport::TestCase
  include TestSetupHelpers
  
  setup do
    # Create projects with standard disciplines
    setup_projects_and_users
    # Set discipline roles
    setup_disciplines(name: "Electrical", required_role: :designer)
    # Create accredited users to get discipline roles
    setup_accredited_users(:designer)
    # Additional Role specific setup
    # Get reference to role instances for testing
    @global_role = Role.find_by(name: 'admin', resource: nil)
    @project_role = Role.find_by(name: 'team_member', resource: @project)
    @discipline_role = Role.find_by(name: 'designer', resource: @discipline)
    # For test purposes, create a resource wide role.
    @team_member.grant(:team_member, Project)
    @resource_wide_role = Role.find_by(name: 'team_member', resource_type: 'Project', resource_id: nil)
    # Create role instances for testing (even though they won't be valid)
    @new_role = Role.new(name: 'team_member', resource: @project)
    @new_resource_wide_role = Role.new(name: 'team_member', resource_type: 'Project')
    @new_global_role = Role.new(name: 'admin', resource: nil)
  end

  # Index action - if current project is set, all users except regular users can view roles
  test 'app owners, admins, project owners and team members can view roles when current project is set' do
    assert RolePolicy.new(user_context(@app_owner, @project), Role).index?,
      'App owner should be able to view roles with project context'
    assert RolePolicy.new(user_context(@admin, @project), Role).index?,
      'Admin should be able to view roles with project context'
    assert RolePolicy.new(user_context(@project_manager, @project), Role).index?,
      'Project manager should be able to view roles with project context'
    assert RolePolicy.new(user_context(@project_admin, @project), Role).index?,
      'Project admin should be able to view roles with project context'
    assert RolePolicy.new(user_context(@team_member, @project), Role).index?,
      'Team member should be able to view roles with project context'
    refute RolePolicy.new(user_context(@regular_user, @project), Role).index?,
      'Regular user should not be able to view roles even with project context'
  end

  # Index action - if no current project is selected, only app owners and admins can view roles
  test 'only app owners and admins can view roles when no current project' do
    assert RolePolicy.new(user_context(@app_owner, nil), nil).index?,
      'App owner should be able to view roles without project context'
    assert RolePolicy.new(user_context(@admin, nil), nil).index?,
      'Admin should be able to view roles without project context'
    refute RolePolicy.new(user_context(@project_manager, nil), nil).index?,
      'Project manager should not be able to view roles without project context'
    refute RolePolicy.new(user_context(@project_admin, nil), nil).index?,
      'Project admin should not be able to view roles without project context'
    refute RolePolicy.new(user_context(@team_member, nil), nil).index?,
      'Team member should not be able to view roles without project context'
    refute RolePolicy.new(user_context(@regular_user, nil), nil).index?,
      'Regular user should not be able to view roles without project context'
  end

  # New action - only app owners and admins can access global role creation from the index form
  test 'new only allows app owners and admins to access global role creation' do
    # Test global role creation (record is the Role class)
    assert RolePolicy.new(user_context(@app_owner, nil), @new_global_role).new?,
      'App owner should be able to access new global role form'
    assert RolePolicy.new(user_context(@admin, nil), @new_global_role).new?,
      'Admin should be able to access new global role form'
      
    # Other roles should not have access to global role creation
    refute RolePolicy.new(user_context(@project_manager, @project), @new_global_role).new?,
      'Project manager should not be able to access new global role form'
    refute RolePolicy.new(user_context(@project_admin, @project), @new_global_role).new?,
      'Project admin should not be able to access new global role form'
    refute RolePolicy.new(user_context(@team_member, @project), @new_global_role).new?,
      'Team member should not be able to access new global role form'
    refute RolePolicy.new(user_context(@regular_user, @project), @new_global_role).new?,
      'Regular user should not be able to access new global role form'
    refute RolePolicy.new(user_context(nil, @project), @new_global_role).new?,
      'Guest user should not be able to access new global role form'
  end

  test 'create global role permissions' do
    # Test admin/app_owner role creation - only app owner can do this
    admin_role = Role.new(name: 'admin', resource: nil)
    app_owner_role = Role.new(name: 'app_owner', resource: nil)
    project_manager_role = Role.new(name: 'project_manager', resource: nil)
    project_admin_role = Role.new(name: 'project_admin', resource: nil)
    
    assert RolePolicy.new(user_context(@app_owner, nil), app_owner_role).create?,
      'App owner should be able to create app_owner role'
    assert RolePolicy.new(user_context(@app_owner, nil), admin_role).create?,
      'App owner should be able to create admin role'
    assert RolePolicy.new(user_context(@app_owner, nil), project_manager_role).create?,
      'App owner should be able to create project_manager role'
    assert RolePolicy.new(user_context(@app_owner, nil), project_admin_role).create?,
      'App owner should be able to create project_admin role'
      
    refute RolePolicy.new(user_context(@admin, nil), app_owner_role).create?,
      'Admin should not be able to create app_owner role'
    refute RolePolicy.new(user_context(@admin, nil), admin_role).create?,
      'Admin should not be able to create admin role'
    assert RolePolicy.new(user_context(@admin, nil), project_manager_role).create?,
      'Admin should be able to create project_manager role'
    refute RolePolicy.new(user_context(@admin, nil), project_admin_role).create?,
      'Admin should not be able to create project_admin role'
    
    # Other users cannot create any global roles
    refute RolePolicy.new(user_context(@project_manager, nil), admin_role).create?,
      'Project manager should not be able to create global roles'
    refute RolePolicy.new(user_context(@project_admin, nil), admin_role).create?,
      'Project admin should not be able to create global roles'
    refute RolePolicy.new(user_context(@team_member, nil), admin_role).create?,
      'Team member should not be able to create global roles'
    refute RolePolicy.new(user_context(@regular_user, nil), admin_role).create?,
      'Regular user should not be able to create global roles'
    refute RolePolicy.new(user_context(nil, nil), admin_role).create?,
      'Guest user should not be able to create global roles'
  end

  test 'create resource wide role permissions' do
    # Global admins can create resource wide roles
    assert RolePolicy.new(user_context(@app_owner, nil), @new_resource_wide_role).create?,
      'App owner should be able to create resource wide roles'
    assert RolePolicy.new(user_context(@admin, nil), @new_resource_wide_role).create?,
      'Admin should be able to create resource wide roles'
    
    # Other users cannot create resource wide roles
    refute RolePolicy.new(user_context(@project_manager, nil), @new_resource_wide_role).create?,
      'Project manager should not be able to create resource wide roles'
    refute RolePolicy.new(user_context(@project_admin, nil), @new_resource_wide_role).create?,
      'Project admin should not be able to create resource wide roles'
    refute RolePolicy.new(user_context(@team_member, nil), @new_resource_wide_role).create?,
      'Team member should not be able to create resource wide roles'
    refute RolePolicy.new(user_context(@regular_user, nil), @new_resource_wide_role).create?,
      'Regular user should not be able to create resource wide roles'
    refute RolePolicy.new(user_context(nil, nil), @new_resource_wide_role).create?,
      'Guest user should not be able to create resource wide roles'
  end

  test 'create resource instance role permissions' do
    # Resource instance create and destroy are delegated to the resource policy,
    # and should be tested by the resource policy test.
    # Project and discipline are tested here, in future this should only test the delegation works.

    project_role = Role.new(name: :team_member, resource: @project)
    discipline_role = Role.new(name: :designer, resource: @discipline)
    # Project admins can create project roles
    assert RolePolicy.new(user_context(@project_manager, @project), project_role).create?,
      'Project manager should be able to create project roles'
    assert RolePolicy.new(user_context(@project_manager, @project), discipline_role).create?,
      'Project manager should be able to create discipline roles'
    
    # Other users cannot create project roles
    refute RolePolicy.new(user_context(@project_admin, @project), project_role).create?,
      'Project admin should not be able to create project roles'
    refute RolePolicy.new(user_context(@project_admin, @project), discipline_role).create?,
      'Project admin should not be able to create discipline roles'
    refute RolePolicy.new(user_context(@team_member, @project), project_role).create?,
      'Team member should not be able to create project roles'
    refute RolePolicy.new(user_context(@team_member, @project), discipline_role).create?,
      'Team member should not be able to create discipline roles'
    refute RolePolicy.new(user_context(@regular_user, @project), project_role).create?,
      'Regular user should not be able to create project roles'
    refute RolePolicy.new(user_context(@regular_user, @project), discipline_role).create?,
      'Regular user should not be able to create discipline roles'
    refute RolePolicy.new(user_context(nil, @project), project_role).create?,
      'Guest user should not be able to create project roles'
    refute RolePolicy.new(user_context(nil, @project), discipline_role).create?,
      'Guest user should not be able to create discipline roles'
  end

  # Destroy action - role deletion permissions
  test 'destroy global permissions' do
    # Global roles - only app owners can destroy
    assert RolePolicy.new(user_context(@app_owner, nil), @global_role).destroy?,
      'App owner should be able to destroy global roles'
    refute RolePolicy.new(user_context(@admin, nil), @global_role).destroy?,
      'Admin should not be able to destroy global roles'
    refute RolePolicy.new(user_context(@project_manager, nil), @global_role).destroy?,
      'Project manager should not be able to destroy global roles'
    refute RolePolicy.new(user_context(@project_admin, nil), @global_role).destroy?,
      'Project admin should not be able to destroy global roles'
  end

  test 'destroy resource wide permissions' do
    # Only global admins can destroy resource wide roles
    assert RolePolicy.new(user_context(@app_owner, @project), @resource_wide_role).destroy?,
      'App owner should be able to destroy resource wide roles'
    assert RolePolicy.new(user_context(@admin, @project), @resource_wide_role).destroy?,
      'Admin should be able to destroy resource wide roles'
    refute RolePolicy.new(user_context(@project_manager, @project), @resource_wide_role).destroy?,
      'Project manager should not be able to destroy resource wide roles'
    refute RolePolicy.new(user_context(@project_admin, @project), @resource_wide_role).destroy?,
      'Project admin should not be able to destroy resource wide roles'
    refute RolePolicy.new(user_context(@team_member, @project), @resource_wide_role).destroy?,
      'Team member should not be able to destroy roles in their project'
    refute RolePolicy.new(user_context(@regular_user, @project), @resource_wide_role).destroy?,
      'Regular user should not be able to destroy project roles'
    refute RolePolicy.new(user_context(nil, @project), @resource_wide_role).destroy?,
      'Guest user should not be able to destroy project roles'
  end

  test 'destroy resource instance permissions' do
    # Resource instance create and destroy are delegated to the resource policy,
    # and should be tested by the resource policy test.
    # Project and discipline are tested here, in future this should only test the delegation works.
    # Project and discipline roles - project managers can destroy roles in their projects
    assert RolePolicy.new(user_context(@project_manager, @project), @project_role).destroy?,
      'Project manager should be able to destroy project roles'
    assert RolePolicy.new(user_context(@project_manager, @project), @discipline_role).destroy?,
      'Project manager should be able to destroy discipline roles'
    refute RolePolicy.new(user_context(@project_admin, @project), @project_role).destroy?,
      'Project admin should not be able to destroy project roles'
    refute RolePolicy.new(user_context(@project_admin, @project), @discipline_role).destroy?,
      'Project admin should not be able to destroy discipline roles'
    refute RolePolicy.new(user_context(@team_member, @project), @project_role).destroy?,
      'Team member should not be able to destroy project roles'
    refute RolePolicy.new(user_context(@team_member, @project), @discipline_role).destroy?,
      'Team member should not be able to destroy discipline roles'
    refute RolePolicy.new(user_context(@regular_user, @project), @project_role).destroy?,
      'Regular user should not be able to destroy project roles'
    refute RolePolicy.new(user_context(@regular_user, @project), @discipline_role).destroy?,
      'Regular user should not be able to destroy discipline roles'
    refute RolePolicy.new(user_context(nil, @project), @project_role).destroy?,
      'Guest user should not be able to destroy project roles'
    refute RolePolicy.new(user_context(nil, @project), @discipline_role).destroy?,
      'Guest user should not be able to destroy discipline roles'
  end

  # Scope filters roles based on user and project
  test 'scope filters roles based on user and project' do
    # App owner sees all roles
    app_owner_scope = RolePolicy::Scope.new(user_context(@app_owner, nil), Role).resolve
    assert_includes app_owner_scope, @global_role,
      'App owner should see global roles'
    assert_includes app_owner_scope, @project_role,
      'App owner should see project roles'

    # Admin sees all roles
    admin_scope = RolePolicy::Scope.new(user_context(@admin, nil), Role).resolve
    assert_includes admin_scope, @global_role,
      'Admin should see global roles'
    assert_includes admin_scope, @project_role,
      'Admin should see project roles'

    # Project manager sees only their project's roles
    project_manager_scope = RolePolicy::Scope.new(user_context(@project_manager, @project), Role).resolve
    refute_includes project_manager_scope, @global_role,
      'Project manager should not see global roles'
    assert_includes project_manager_scope, @project_role,
      'Project manager should see roles from their project'

    # Team member sees only their project's roles
    team_member_scope = RolePolicy::Scope.new(user_context(@team_member, @project), Role).resolve
    refute_includes team_member_scope, @global_role,
      'Team member should not see global roles'
    assert_includes team_member_scope, @project_role,
      'Team member should see roles from their project'

    # Regular user without project context sees no roles
    assert_empty RolePolicy::Scope.new(user_context(@regular_user, nil), Role).resolve,
      'Regular user without project context should see no roles'
      
    # Regular user with project context but no role sees no roles
    assert_empty RolePolicy::Scope.new(user_context(@regular_user, @project), Role).resolve,
      'Regular user without project role should see no roles'
  end
end
