require 'test_helper'

class TagPolicyTest < ActiveSupport::TestCase
  include PolicyHelpers
  
  def setup
    setup_policy_test
    @tag = create(:tag, project: @project)
    @other_tag = create(:tag, :unique_tag, project: @other_project)
  end
  
  # Helper to create policy with user and project context
  def policy(user, project, record = nil)
    user_context = ApplicationPolicy::UserContext.new(user, project)
    TagPolicy.new(user_context, record || CableType)
  end
  
  # Scope Tests
  test 'scope returns tags for current project' do
    context = ApplicationPolicy::UserContext.new(@team_member, @project)
    scope = TagPolicy::Scope.new(context, Tag).resolve
    assert_includes scope, @tag
    refute_includes scope, @other_tag
  end  
  
  test 'scope returns empty when no project is selected' do
    context = ApplicationPolicy::UserContext.new(@team_member, nil)
    scope = TagPolicy::Scope.new(context, Tag).resolve
    assert_empty scope
  end
  
  # Index Tests
  test 'index? is available to admin and app_owner without current project' do
    assert policy(@admin, nil).index?
    assert policy(@app_owner, nil).index?
  end

  test 'index? requires user to have a project role' do
    refute policy(@regular_user, @project).index?
  end
  
  test 'index? denies when no project is selected' do
    refute policy(@regular_user, nil).index?
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

  test 'cannot show tag from different project' do
    @other_project = create(:project)
    @other_tag = create(:tag, :unique_tag, project: @other_project)
    refute TagPolicy.new(user_context(@project_owner), @other_tag).show?
    refute TagPolicy.new(user_context(@team_member), @other_tag).show?
  end

  # New tests defer to create
  # Create Tests
  test 'create allows users with any project role' do
    # Test with standard project roles
    assert TagPolicy.new(user_context(@project_owner), Tag.new(project: @project)).create?
    assert TagPolicy.new(user_context(@team_member), Tag.new(project: @project)).create?
  end

  test 'create denies users without project role' do
    refute TagPolicy.new(user_context(@regular_user), Tag.new(project: @project)).create?
    refute TagPolicy.new(user_context(nil), Tag.new(project: @project)).create?
  end

  # Edit tests defer to update
  # Update Tests
  test 'update allows users with any project role' do
    # Test with standard project roles
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
