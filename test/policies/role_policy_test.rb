require 'test_helper'

class RolePolicyTest < ActiveSupport::TestCase
  setup do
    @project = create(:project)
    
    # Create test users using factory traits
    @app_owner = create(:user, :app_owner)
    @admin = create(:user, :admin)
    
    # Create project-specific roles
    @project_owner = create(:user)
    @project_owner.add_role(:project_owner, @project)
    
    @team_member = create(:user)
    @team_member.add_role(:team_member, @project)
    @team_member.add_role(:electrical_designer)
    
    @regular_user = create(:user)
    
    # Get reference to role instances for testing
    @global_role = Role.find_by(name: 'admin', resource: nil)
    @functional_role = Role.find_by(name: 'electrical_designer', resource: nil)
    @project_role = Role.find_by(name: 'team_member', resource: @project)

    # Create role instances for testing (even though they won't be valid)
    @new_role = Role.new(name: 'team_member', resource: @project)
    @new_global_role = Role.new(name: 'team_member', resource: nil)
  end

  # Helper to create user context for policy
  def user_context(user, project = nil)
    ApplicationPolicy::UserContext.new(user, project)
  end

  # Index action - if current project is set, all users except regular users can view roles
  test 'app owners, admins, project owners and team members can view roles when current project is set' do
    assert RolePolicy.new(user_context(@app_owner, @project), Role).index?,
      'App owner should be able to view roles with project context'
    assert RolePolicy.new(user_context(@admin, @project), Role).index?,
      'Admin should be able to view roles with project context'
    assert RolePolicy.new(user_context(@project_owner, @project), Role).index?,
      'Project owner should be able to view roles with project context'
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
    refute RolePolicy.new(user_context(@project_owner, nil), nil).index?,
      'Project owner should not be able to view roles without project context'
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
    refute RolePolicy.new(user_context(@project_owner, @project), @new_global_role).new?,
      'Project owner should not be able to access new global role form'
    refute RolePolicy.new(user_context(@team_member, @project), @new_global_role).new?,
      'Team member should not be able to access new global role form'
    refute RolePolicy.new(user_context(@regular_user, @project), @new_global_role).new?,
      'Regular user should not be able to access new global role form'
    refute RolePolicy.new(user_context(nil, @project), @new_global_role).new?,
      'Guest user should not be able to access new global role form'
  end

  test 'create role permissions' do
    # Test admin/app_owner role creation - only app owner can do this
    admin_role = Role.new(name: 'admin', resource: nil)
    app_owner_role = Role.new(name: 'app_owner', resource: nil)
    
    assert RolePolicy.new(user_context(@app_owner, nil), admin_role).create?,
      'App owner should be able to create admin role'
    assert RolePolicy.new(user_context(@app_owner, nil), app_owner_role).create?,
      'App owner should be able to create app_owner role'
      
    refute RolePolicy.new(user_context(@admin, nil), admin_role).create?,
      'Admin should not be able to create admin role'
    refute RolePolicy.new(user_context(@admin, nil), app_owner_role).create?,
      'Admin should not be able to create app_owner role'
    
    # Test functional role creation - both app owner and admin can do this
    functional_role = Role.new(name: 'functional_role', resource: nil)
    
    assert RolePolicy.new(user_context(@app_owner, nil), functional_role).create?,
      'App owner should be able to create functional roles'
    assert RolePolicy.new(user_context(@admin, nil), functional_role).create?,
      'Admin should be able to create functional roles'
    
    # Other users cannot create any global roles
    refute RolePolicy.new(user_context(@project_owner, nil), functional_role).create?,
      'Project owner should not be able to create global roles'
    refute RolePolicy.new(user_context(@team_member, nil), functional_role).create?,
      'Team member should not be able to create global roles'
    refute RolePolicy.new(user_context(@regular_user, nil), functional_role).create?,
      'Regular user should not be able to create global roles'
    refute RolePolicy.new(user_context(nil, nil), functional_role).create?,
      'Guest user should not be able to create global roles'
      
    # Note: Resource role creation is handled by the resource's policy
    # and should be tested in the resource's policy tests
  end

  # Destroy action - role deletion permissions
  test 'destroy permissions' do
    # Global roles - only app owners and admins can destroy
    assert RolePolicy.new(user_context(@app_owner, nil), @global_role).destroy?,
      'App owner should be able to destroy global roles'
    refute RolePolicy.new(user_context(@admin, nil), @global_role).destroy?,
      'Admin should not be able to destroy global roles'
    refute RolePolicy.new(user_context(@project_owner, nil), @global_role).destroy?,
      'Project owner should not be able to destroy global roles'

    # Project roles - project owners can destroy roles in their projects
    assert RolePolicy.new(user_context(@project_owner, @project), @project_role).destroy?,
      'Project owner should be able to destroy roles in their project'
    refute RolePolicy.new(user_context(@team_member, @project), @project_role).destroy?,
      'Team member should not be able to destroy roles in their project'
    refute RolePolicy.new(user_context(@regular_user, @project), @project_role).destroy?,
      'Regular user should not be able to destroy project roles'
    refute RolePolicy.new(user_context(nil, @project), @project_role).destroy?,
      'Guest user should not be able to destroy project roles'
  end

  # Scope filters roles based on user and project
  test 'scope filters roles based on user and project' do
    # App owner sees all roles
    app_owner_scope = RolePolicy::Scope.new(user_context(@app_owner), Role).resolve
    assert_includes app_owner_scope, @global_role,
      'App owner should see global roles'
    assert_includes app_owner_scope, @project_role,
      'App owner should see project roles'

    # Admin sees all roles
    admin_scope = RolePolicy::Scope.new(user_context(@admin), Role).resolve
    assert_includes admin_scope, @global_role,
      'Admin should see global roles'
    assert_includes admin_scope, @project_role,
      'Admin should see project roles'

    # Project owner sees only their project's roles
    project_owner_scope = RolePolicy::Scope.new(user_context(@project_owner, @project), Role).resolve
    refute_includes project_owner_scope, @global_role,
      'Project owner should not see global roles'
    assert_includes project_owner_scope, @project_role,
      'Project owner should see roles from their project'

    # Team member sees only their project's roles
    team_member_scope = RolePolicy::Scope.new(user_context(@team_member, @project), Role).resolve
    refute_includes team_member_scope, @global_role,
      'Team member should not see global roles'
    assert_includes team_member_scope, @project_role,
      'Team member should see roles from their project'

    # Regular user without project context sees no roles
    assert_empty RolePolicy::Scope.new(user_context(@regular_user), Role).resolve,
      'Regular user without project context should see no roles'
      
    # Regular user with project context but no role sees no roles
    assert_empty RolePolicy::Scope.new(user_context(@regular_user, @project), Role).resolve,
      'Regular user without project role should see no roles'
  end
end
