require 'test_helper'
require_relative '../helpers/resource_policy_test'

class ProjectPolicyTest < ActiveSupport::TestCase
  include PolicyTestHelpers

  def setup
    setup_policy_test
  end
  
  # Helper to create policy with user and project context
  def policy(user, project, record = nil)
    user_context = ApplicationPolicy::UserContext.new(user, project)
    ProjectPolicy.new(user_context, record || Project)
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

  # New Tests defer to create
  # Create tests
  test 'create only allows app owners or admins' do
    assert policy(@admin, @project, build(:project)).create?
    assert policy(@app_owner, @project, build(:project)).create?
  end

  test 'create denies users other than admins or app owners' do
    refute policy(@project_manager, @project, build(:project)).create?
    refute policy(@team_member, @project, build(:project)).create?
    refute policy(@regular_user, @project, build(:project)).create?
  end

  # Edit tests defer to update
  # Update tests
  test 'update allows project manager' do
    assert policy(@project_manager, @project, @project).update?
  end

  test 'update allows app owner and admin' do
    assert policy(@admin, @project, @project).update?
    assert policy(@app_owner, @project, @project).update?
  end

  test 'update denies user other than project manager, app owner and admin' do
    refute policy(@team_member, @project, @project).update?
    refute policy(@regular_user, @project, @project).update?
    refute policy(nil, @project, @project).update?
  end

  # Destroy tests
  test 'destroy allows app owner' do
    assert policy(@app_owner, @project, @project).destroy?
  end

  test 'destroy denies project manager, team members and regular users' do
    refute policy(@admin, @project, @project).destroy?
    refute policy(@project_manager, @project, @project).destroy?
    refute policy(@team_member, @project, @project).destroy?
    refute policy(@regular_user, @project, @project).destroy?
  end

  test 'destroy denies unauthenticated users' do
    refute policy(nil, @project, @project).destroy?
  end
end
