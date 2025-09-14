require 'test_helper'

class ProjectPolicyTest < ActiveSupport::TestCase
  include PolicyHelpers

  def setup
    setup_policy_test
  end

  # Helper to create user context for policy
  def user_context(user, project = nil)
    user ? ApplicationPolicy::UserContext.new(user, project) : nil
  end

  # Scope tests
  test 'scope for app owner includes all projects' do
    projects = ProjectPolicy::Scope.new(user_context(@app_owner), Project).resolve
    assert_includes projects, @project
    assert_includes projects, @other_project
  end

  test 'scope for admin includes all projects' do
    projects = ProjectPolicy::Scope.new(user_context(@admin), Project).resolve
    assert_includes projects, @project
    assert_includes projects, @other_project
  end

  test 'scope for users only includes projects where they have a role' do
    projects = ProjectPolicy::Scope.new(user_context(@team_member), Project).resolve
    assert_includes projects, @project
    refute_includes projects, @other_project
  end

  test 'scope for regular user does not include projects where they have no role' do
    projects = ProjectPolicy::Scope.new(user_context(@regular_user), Project).resolve
    refute_includes projects, @project
  end

  # Index tests
  test 'index? allows any authenticated user' do
    assert ProjectPolicy.new(user_context(@app_owner), Project).index?
    assert ProjectPolicy.new(user_context(@regular_user), Project).index?
  end

  test 'index? denies unauthenticated users' do
    refute ProjectPolicy.new(nil, Project).index?
  end
  
  # Show tests
  test 'show? allows any authenticated user with project access' do
    assert ProjectPolicy.new(user_context(@app_owner), @project).show?
    assert ProjectPolicy.new(user_context(@team_member), @project).show?
  end

  test 'show? denies users without project role' do
    refute ProjectPolicy.new(user_context(@regular_user), @project).show?
  end

  test 'show? denies unauthenticated users' do
    refute ProjectPolicy.new(nil, @project).show?
  end

  # New Tests defer to create
  # Create tests
  test 'create only allows app owners or admins' do
    assert ProjectPolicy.new(user_context(@app_owner), Project).create?
    assert ProjectPolicy.new(user_context(@admin), Project).create?
  end

  test 'create denies users other than admins or app owners' do
    refute ProjectPolicy.new(user_context(@regular_user), Project).create?
    refute ProjectPolicy.new(user_context(@project_manager), Project).create?
    refute ProjectPolicy.new(user_context(nil), Project).create?
  end

  # Edit tests defer to update
  # Update tests
  test 'update allows project manager' do
    assert ProjectPolicy.new(user_context(@project_manager), @project).update?
  end

  test 'update allows app owner and admin' do
    assert ProjectPolicy.new(user_context(@app_owner), @project).update?
    assert ProjectPolicy.new(user_context(@admin), @project).update?
  end

  test 'update denies user other than project owner, app owner and admin' do
    refute ProjectPolicy.new(user_context(@regular_user), @project).update?
    refute ProjectPolicy.new(user_context(@team_member), @project).update?
    refute ProjectPolicy.new(user_context(nil), @project).update?
  end

  # Destroy tests
  test 'destroy allows app owner' do
    assert ProjectPolicy.new(user_context(@app_owner), @project).destroy?
  end

  test 'destroy denies project manager, team members and regular users' do
    refute ProjectPolicy.new(user_context(@project_manager), @project).destroy?
    refute ProjectPolicy.new(user_context(@team_member), @project).destroy?
    refute ProjectPolicy.new(user_context(@regular_user), @project).destroy?
  end

  test 'destroy denies unauthenticated users' do
    refute ProjectPolicy.new(user_context(nil), @project).destroy?
  end
end
