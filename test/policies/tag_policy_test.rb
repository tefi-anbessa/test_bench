require 'test_helper'

class TagPolicyTest < ActiveSupport::TestCase
  include PolicyHelpers
  
  def setup
    setup_policy_test
    @tag = create(:tag, project: @project)
  end

  # Scope Tests
  test 'scope for app owner shows all tags' do
    scope = TagPolicy::Scope.new(user_context(@app_owner), Tag).resolve
    assert_includes scope, @tag
    assert_equal Tag.count, scope.count
  end

  test 'scope for admin shows all tags' do
    scope = TagPolicy::Scope.new(user_context(@admin), Tag).resolve
    assert_includes scope, @tag
    assert_equal Tag.count, scope.count
  end

  test 'scope for project owner shows tags in their project' do
    @project_owner.add_role(:project_owner, @project)
    scope = TagPolicy::Scope.new(user_context(@project_owner), Tag).resolve
    assert_includes scope, @tag
  end

  test 'scope for team member shows tags in their project' do
    @team_member.add_role(:team_member, @project)
    scope = TagPolicy::Scope.new(user_context(@team_member), Tag).resolve
    assert_includes scope, @tag
  end

  test 'scope for regular user shows no tags' do
    scope = TagPolicy::Scope.new(user_context(@regular_user), Tag).resolve
    assert_empty scope
  end

  test 'scope for guest shows no tags' do
    scope = TagPolicy::Scope.new(user_context(nil), Tag).resolve
    assert_empty scope
  end

  # Show Tests
  test 'show allows anyone with project access' do
    assert TagPolicy.new(user_context(@project_owner), @tag).show?
    assert TagPolicy.new(user_context(@team_member), @tag).show?
    assert TagPolicy.new(user_context(@admin), @tag).show?
    assert TagPolicy.new(user_context(@app_owner), @tag).show?
  end

  test 'show denies users without project access' do
    refute TagPolicy.new(user_context(@regular_user), @tag).show?
    refute TagPolicy.new(user_context(nil), @tag).show?
  end

  # Create Tests
  test 'create allows users with any project role' do
    # Test with standard project roles
    @project_owner.add_role(:project_owner, @project)
    @team_member.add_role(:team_member, @project)
    
    assert TagPolicy.new(user_context(@project_owner), Tag.new(project: @project)).create?
    assert TagPolicy.new(user_context(@team_member), Tag.new(project: @project)).create?
  end

  test 'create denies users without project role' do
    refute TagPolicy.new(user_context(@regular_user), Tag.new(project: @project)).create?
    refute TagPolicy.new(user_context(nil), Tag.new(project: @project)).create?
  end

  # Update Tests
  test 'update allows users with any project role' do
    # Test with standard project roles
    @project_owner.add_role(:project_owner, @project)
    @team_member.add_role(:team_member, @project)
    
    assert TagPolicy.new(user_context(@project_owner), @tag).update?
    assert TagPolicy.new(user_context(@team_member), @tag).update?
  end

  test 'update denies users without project role' do
    refute TagPolicy.new(user_context(@regular_user), @tag).update?
    refute TagPolicy.new(user_context(nil), @tag).update?
  end

  # Destroy Tests
  test 'destroy allows only admin and app_owner' do
    assert TagPolicy.new(user_context(@admin), @tag).destroy?
    assert TagPolicy.new(user_context(@app_owner), @tag).destroy?
  end

  test 'destroy denies project owner, team members and regular users' do
    @project_owner.add_role(:project_owner, @project)
    @team_member.add_role(:team_member, @project)
    
    refute TagPolicy.new(user_context(@project_owner), @tag).destroy?
    refute TagPolicy.new(user_context(@team_member), @tag).destroy?
    refute TagPolicy.new(user_context(@regular_user), @tag).destroy?
    refute TagPolicy.new(user_context(nil), @tag).destroy?
  end
end
