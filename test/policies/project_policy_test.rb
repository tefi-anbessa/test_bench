require 'test_helper'
require 'helpers/test_setup_helpers'

class ProjectPolicyTest < ActiveSupport::TestCase
  include TestSetupHelpers

  def setup
    setup_projects_and_users
  end
  
  # Helper to create policy with user and project context
  def policy(user, project, record = nil)
    user_context = ApplicationPolicy::UserContext.new(user, project)
    ProjectPolicy.new(user_context, record || Project)
  end

  def new_role(role_name, resource)
    Role.new(name: role_name, resource_type: resource.class.name, resource_id: resource.id)
  end

  # Helper to create role policy, which then delegates back to project policy.
  def role_policy(user, project, role)
    user_context = ApplicationPolicy::UserContext.new(user, project)
    RolePolicy.new(user_context, role)
  end

  # Scope tests
  test 'scope for app owner includes all projects' do
    context = ApplicationPolicy::UserContext.new(@app_owner, @project)
    scope = ProjectPolicy::Scope.new(context, Project).resolve
    assert_includes scope, @project
    assert_includes scope, @other_project
  end

  test 'scope for admin includes all projects' do
    context = ApplicationPolicy::UserContext.new(@admin, @project)
    scope = ProjectPolicy::Scope.new(context, Project).resolve
    assert_includes scope, @project
    assert_includes scope, @other_project
  end

  test 'scope for users only includes projects where they have a role' do
    context = ApplicationPolicy::UserContext.new(@team_member, @project)
    scope = ProjectPolicy::Scope.new(context, Project).resolve
    assert_includes scope, @project
    refute_includes scope, @other_project
  end

  test 'scope for regular user does not include projects where they have no role' do
    context = ApplicationPolicy::UserContext.new(@regular_user, @project)
    scope = ProjectPolicy::Scope.new(context, Project).resolve
    refute_includes scope, @project
  end

  # Index tests
  test 'index? allows any authenticated user' do
    assert policy(@admin, @project).index?
    assert policy(@app_owner, @project).index?
    assert policy(@regular_user, @project).index?
  end

  test 'index? denies unauthenticated users' do
    refute policy(nil, @project).index?
  end
  
  # Show tests
  test 'show? allows any authenticated user with project role' do
    assert policy(@team_member, @project, @project).show?
    assert policy(@app_owner, @project, @project).show?
  end

  test 'show? denies users without project role' do
    refute policy(@regular_user, @project, @project).show?
  end

  test 'show? denies unauthenticated users' do
    refute policy(nil, @project, @project).show?
  end

  # New tests
  test 'new allows app owners and admins' do
    assert policy(@admin, @project, build(:project)).new?
    assert policy(@app_owner, @project, build(:project)).new?
  end

  test 'new denies users other than admins or app owners' do
    refute policy(@project_manager, @project, build(:project)).new?
    refute policy(@project_admin, @project, build(:project)).new?
    refute policy(@team_member, @project, build(:project)).new?
    refute policy(@regular_user, @project, build(:project)).new?
    refute policy(nil, @project, build(:project)).new?
  end

  # Create tests
  test 'create only allows app owners or admins' do
    assert policy(@admin, @project, build(:project)).create?
    assert policy(@app_owner, @project, build(:project)).create?
  end

  test 'create denies users other than admins or app owners' do
    refute policy(@project_manager, @project, build(:project)).create?
    refute policy(@project_admin, @project, build(:project)).create?
    refute policy(@team_member, @project, build(:project)).create?
    refute policy(@regular_user, @project, build(:project)).create?
  end

  # Edit tests
  test 'edit allows project manager or project admin' do
    assert policy(@project_manager, @project, @project).edit?
    assert policy(@project_admin, @project, @project).edit?
  end

  test 'edit allows app owner and admin' do
    assert policy(@admin, @project, @project).edit?
    assert policy(@app_owner, @project, @project).edit?
  end

  test 'edit denies user other than project manager, project admin, app owner and admin' do
    refute policy(@team_member, @project, @project).edit?
    refute policy(@regular_user, @project, @project).edit?
    refute policy(nil, @project, @project).edit?
  end

  test 'edit denies project manager when editing project they do not have role on' do
    # Project manager has role on @project but tries to edit @other_project
    refute policy(@project_manager, @project, @other_project).edit?
    refute policy(@project_admin, @project, @other_project).edit?
  end

  # Update tests
  test 'update allows project manager or project admin' do
    assert policy(@project_manager, @project, @project).update?
    assert policy(@project_admin, @project, @project).update?
  end

  test 'update allows app owner and admin' do
    assert policy(@admin, @project, @project).update?
    assert policy(@app_owner, @project, @project).update?
  end

  test 'update denies user other than project manager, project admin, app owner and admin' do
    refute policy(@team_member, @project, @project).update?
    refute policy(@regular_user, @project, @project).update?
    refute policy(nil, @project, @project).update?
  end

  test 'update denies project manager when updating project they do not have role on' do
    # Project manager has role on @project but tries to update @other_project
    refute policy(@project_manager, @project, @other_project).update?
    refute policy(@project_admin, @project, @other_project).update?
  end

  # Destroy tests
  test 'destroy allows app owner' do
    assert policy(@app_owner, @project, @project).destroy?
  end

  test 'destroy denies admin, project manager, project admin, team members and regular users' do
    refute policy(@admin, @project, @project).destroy?
    refute policy(@project_manager, @project, @project).destroy?
    refute policy(@project_admin, @project, @project).destroy?
    refute policy(@team_member, @project, @project).destroy?
    refute policy(@regular_user, @project, @project).destroy?
  end

  test 'destroy denies unauthenticated users' do
    refute policy(nil, @project, @project).destroy?
  end

  # Grant role tests (for project-scoped roles, delegated from RolePolicy)
  test 'delegation from role policy create to project grant_role' do
    # test delegation from RolePolicy
    assert role_policy(@app_owner, @project, new_role(:team_member, @project)).create?
    assert role_policy(@admin, @project, new_role(:team_member, @project)).create?
    assert role_policy(@project_manager, @project, new_role(:team_member, @project)).create?
  end

  test 'delegation from role policy create to project protects against cross project assignment' do
    # test delegation from RolePolicy
    assert role_policy(@app_owner, @project, new_role(:team_member, @other_project)).create?
    assert role_policy(@admin, @project, new_role(:team_member, @other_project)).create?
    refute role_policy(@project_manager, @project, new_role(:team_member, @other_project)).create?
  end

  # Grant role tests (for resource-scoped roles, delegated from RolePolicy)
  test 'grant_role protects against nil user' do
    # test grant_role action directly in ProjectPolicy
    role = Role.new(name: :team_member, resource_type: @project.class.name, resource_id: @project.id)
    refute policy(nil, @project, role).grant_role?
  end

  test 'grant_role denies global and resource roles' do
    global_role = Role.find_by(name: :admin)
    resource_role = Role.new(name: :team_member, resource_type: @project.class.name, resource_id: nil)
    refute policy(@app_owner, @project, global_role).grant_role?
    refute policy(@app_owner, @project, resource_role).grant_role?
  end

  test 'grant_role denies invalid role names' do
    invalid_role = Role.new(name: :designer, resource_type: @project.class.name, resource_id: @project.id)
    refute policy(@app_owner, @project, invalid_role).grant_role?
  end

  test 'grant_role allows project app owner to grant project admin role' do
    project_admin_role = Role.new(name: :project_admin, resource: @project)
    assert policy(@app_owner, @project, project_admin_role).grant_role?
  end

  test 'grant_role denies project manager and admin from granting project admin roles' do
    project_admin_role = Role.new(name: :project_admin, resource: @project)
    refute policy(@admin, @project, project_admin_role).grant_role?
    refute policy(@project_manager, @project, project_admin_role).grant_role?
  end

  test 'grant_role allows project manager and global admins to grant project roles' do
    team_member_role = Role.new(name: :team_member, resource: @project)
    assert policy(@admin, @project, team_member_role).grant_role?
    assert policy(@project_manager, @project, team_member_role).grant_role?
  end

  test 'grant_role denies users without proper permissions' do
    team_member_role = Role.new(name: :team_member, resource: @project)
    refute policy(@project_admin, @project, team_member_role).grant_role?
    refute policy(@team_member, @project, team_member_role).grant_role?
    refute policy(@regular_user, @project, team_member_role).grant_role?
    refute policy(nil, @project, team_member_role).grant_role?
  end

  # Revoke role tests (only for project-scoped roles, delegated from RolePolicy)
  test 'delegation from role policy destroy to project revoke role' do
    # test delegation from RolePolicy
    role = Role.find_by(name: 'team_member', resource: @project)
    assert role_policy(@app_owner, @project, role).destroy?
    assert role_policy(@admin, @project, role).destroy?
    assert role_policy(@project_manager, @project, role).destroy?
  end

  # Dumb test but concurs with the documentation...
  test 'delegation from role policy destroy to other project allows global admins but not project manager' do
    # test delegation from RolePolicy
    role = Role.find_by(name: 'team_member', resource: @other_project)
    assert role_policy(@app_owner, @project, role).destroy?
    assert role_policy(@admin, @project, role).destroy?
    refute role_policy(@project_manager, @project, role).destroy?
  end

  # Revoke role tests (for project-scoped roles, delegated from RolePolicy)
  test 'revoke_role protects against nil user' do
    # test revoke_role action directly in ProjectPolicy
    role = Role.new(name: :team_member, resource_type: @project.class.name, resource_id: @project.id)
    refute policy(nil, @project, role).revoke_role?
  end

  test 'revoke_role denies global and resource roles' do
    global_role = Role.new(name: :admin)
    resource_role = Role.new(name: :team_member, resource_type: @project.class.name, resource_id: nil)
    refute policy(@app_owner, @project, global_role).revoke_role?
    refute policy(@app_owner, @project, resource_role).revoke_role?
  end

  test 'revoke_role allows invalid role names' do
    invalid_role = Role.new(name: :invalid_role, 
      resource_type: @project.class.name, 
      resource_id: @project.id)
    assert policy(@app_owner, @project, invalid_role).revoke_role?
  end

  test 'revoke_role allows project app owner to revoke project admin role' do
    project_admin_role = Role.new(name: :project_admin, resource: @project)
    assert policy(@app_owner, @project, project_admin_role).revoke_role?
  end

  test 'revoke_role denies project manager and admin from revoking project admin roles' do
    project_admin_role = Role.new(name: :project_admin, resource: @project)
    refute policy(@admin, @project, project_admin_role).revoke_role?
    refute policy(@project_manager, @project, project_admin_role).revoke_role?
  end

  test 'revoke_role allows project manager and global admins to revoke project roles' do
    team_member_role = Role.new(name: :team_member, resource: @project)
    assert policy(@admin, @project, team_member_role).revoke_role?
    assert policy(@project_manager, @project, team_member_role).revoke_role?
  end

  test 'revoke_role denies users without proper permissions' do
    team_member_role = Role.new(name: :team_member, resource: @project)
    refute policy(@project_admin, @project, team_member_role).revoke_role?
    refute policy(@team_member, @project, team_member_role).revoke_role?
    refute policy(@regular_user, @project, team_member_role).revoke_role?
    refute policy(nil, @project, team_member_role).revoke_role?
  end

  test 'revoke_role denies project managers to revoke role on other project' do
    role = Role.new(name: :team_member, resource: @other_project)
    assert policy(@app_owner, @project, role).revoke_role?
    assert policy(@admin, @project, role).revoke_role?
    refute policy(@project_manager, @project, role).revoke_role?
  end
end
