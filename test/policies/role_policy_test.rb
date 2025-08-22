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
    
    @regular_user = create(:user)
    
    # Get reference to role instances for testing
    @global_role = Role.find_by(name: 'admin', resource: nil)
    @project_role = Role.find_by(name: 'team_member', resource: @project)
  end

  # Helper to create user context for policy
  def user_context(user, project = nil)
    ApplicationPolicy::UserContext.new(user, project)
  end

  # Index action - requires a project context
  test 'index requires project context' do
    # With project context
    assert RolePolicy.new(user_context(@app_owner, @project), Role).index?
    assert RolePolicy.new(user_context(@admin, @project), Role).index?
    assert RolePolicy.new(user_context(@project_owner, @project), Role).index?
    assert RolePolicy.new(user_context(@team_member, @project), Role).index?
    assert RolePolicy.new(user_context(@regular_user, @project), Role).index?
    
    # Without project context
    refute RolePolicy.new(user_context(@app_owner), Role).index?
    refute RolePolicy.new(user_context(nil), Role).index?
  end

  # New action - only app owners can access
  test 'new only allows app owners' do
    assert RolePolicy.new(user_context(@app_owner, @project), Role).new?
    refute RolePolicy.new(user_context(@admin, @project), Role).new?
    refute RolePolicy.new(user_context(@project_owner, @project), Role).new?
    refute RolePolicy.new(user_context(@team_member, @project), Role).new?
    refute RolePolicy.new(user_context(@regular_user, @project), Role).new?
    refute RolePolicy.new(user_context(nil, @project), Role).new?
  end

  # Create action - only app owners can access
  test 'create only allows app owners' do
    assert RolePolicy.new(user_context(@app_owner, @project), Role).create?
    refute RolePolicy.new(user_context(@admin, @project), Role).create?
    refute RolePolicy.new(user_context(@project_owner, @project), Role).create?
    refute RolePolicy.new(user_context(@team_member, @project), Role).create?
    refute RolePolicy.new(user_context(@regular_user, @project), Role).create?
    refute RolePolicy.new(user_context(nil, @project), Role).create?
  end

  # Destroy action - only app owners can access
  test 'destroy only allows app owners' do
    assert RolePolicy.new(user_context(@app_owner, @project), @global_role).destroy?
    refute RolePolicy.new(user_context(@admin, @project), @global_role).destroy?
    refute RolePolicy.new(user_context(@project_owner, @project), @project_role).destroy?
    refute RolePolicy.new(user_context(@team_member, @project), @project_role).destroy?
    refute RolePolicy.new(user_context(@regular_user, @project), @project_role).destroy?
    refute RolePolicy.new(user_context(nil, @project), @project_role).destroy?
  end

  # Scope filters roles based on user and project
  test 'scope filters roles based on user and project' do
    # App owner sees all roles
    app_owner_scope = RolePolicy::Scope.new(user_context(@app_owner), Role).resolve
    assert_includes app_owner_scope, @global_role
    assert_includes app_owner_scope, @project_role

    # Admin sees all roles
    admin_scope = RolePolicy::Scope.new(user_context(@admin), Role).resolve
    assert_includes admin_scope, @global_role
    assert_includes admin_scope, @project_role

    # Project owner sees project roles
    project_owner_scope = RolePolicy::Scope.new(user_context(@project_owner, @project), Role).resolve
    refute_includes project_owner_scope, @global_role
    assert_includes project_owner_scope, @project_role

    # Regular user sees project roles
    regular_user_scope = RolePolicy::Scope.new(user_context(@regular_user, @project), Role).resolve
    refute_includes regular_user_scope, @global_role
    assert_includes regular_user_scope, @project_role

    # No project context shows no roles
    assert_empty RolePolicy::Scope.new(user_context(@regular_user), Role).resolve
  end
end
