require 'test_helper'
require_relative '../helpers/resource_policy_test'

class TagPolicyTest < ActiveSupport::TestCase
  include PolicyTestHelpers
  
  def setup
    setup_policy_test
    @tag = create(:tag, discipline: @discipline)
    @other_tag = create(:tag, :unique_tag, discipline: @other_discipline)
  end
  
  # Helper to create policy with user and project context
  def policy(user, project, record = nil)
    user_context = ApplicationPolicy::UserContext.new(user, project)
    TagPolicy.new(user_context, record || Tag)
  end
  
  # Scope Tests
  test 'scope for team_member returns tags for current project' do
    context = ApplicationPolicy::UserContext.new(@team_member, @project)
    scope = TagPolicy::Scope.new(context, Tag).resolve
    assert_includes scope, @tag
    refute_includes scope, @other_tag
  end
  
  test 'scope for team member returns empty when no current project is selected' do
    context = ApplicationPolicy::UserContext.new(@team_member, nil)
    scope = TagPolicy::Scope.new(context, Tag).resolve
    assert_empty scope
  end

  test 'scope for admin returns tags for current project' do
    context = ApplicationPolicy::UserContext.new(@admin, @project)
    scope = TagPolicy::Scope.new(context, Tag).resolve
    assert_includes scope, @tag
    refute_includes scope, @other_tag
  end
  
  test 'scope for admin returns all tags when no current project is selected' do
    context = ApplicationPolicy::UserContext.new(@admin, nil)
    scope = TagPolicy::Scope.new(context, Tag).resolve
    assert_includes scope, @tag
    assert_includes scope, @other_tag
  end
  
  test 'scope for user with no current project role returns empty' do
    context = ApplicationPolicy::UserContext.new(@regular_user, @project)
    scope = TagPolicy::Scope.new(context, Tag).resolve
    assert_empty scope
    context = ApplicationPolicy::UserContext.new(@regular_user, nil)
    scope = TagPolicy::Scope.new(context, Tag).resolve
    assert_empty scope
  end
  
  # Index Tests
  test 'index? is available to admins and team members on current project' do
    assert policy(@admin, @project).index?
    assert policy(@app_owner, @project).index?
    assert policy(@project_manager, @project).index?
    assert policy(@team_member, @project).index?
  end

  test 'index? is available to admins without current project' do
    assert policy(@admin, nil).index?
    assert policy(@app_owner, nil).index?
  end
  
  test 'index? denies team member when no project is selected' do
    refute policy(@project_manager, nil).index?
    refute policy(@team_member, nil).index?
  end

  test 'index? is denied to user without a project role' do
    refute policy(@regular_user, @project).index?
  end

  test 'index? is denied when user is not set' do
    refute policy(nil, @project).index?
  end

  # Show Tests
  test 'show? allows admins and team members on current project to view tag on current project' do
    assert policy(@project_manager, @project, @tag).show?
    assert policy(@team_member, @project, @tag).show?
    assert policy(@admin, @project, @tag).show?
    assert policy(@app_owner, @project, @tag).show?
  end

  test 'show? denies admins and team members on current project to view tag on different project' do
    refute policy(@project_manager, @project, @other_tag).show?
    refute policy(@team_member, @project, @other_tag).show?
    refute policy(@admin, @project, @other_tag).show?
    refute policy(@app_owner, @project, @other_tag).show?
  end

  test 'show? allows admins with nil current project to view any tag' do
    assert policy(@admin, nil, @tag).show?
    assert policy(@admin, nil, @other_tag).show?
  end

  test 'show? denies team members with nil current project to view any tag' do
    refute policy(@team_member, nil, @tag).show?
    refute policy(@team_member, nil, @other_tag).show?
    refute policy(@project_manager, nil, @tag).show?
    refute policy(@project_manager, nil, @other_tag).show?
  end

  test 'show denies users without project access' do
    refute policy(@regular_user, @project, @tag).show?
    refute policy(nil, @project, @tag).show?
  end

  # New tests defer to create
  # Create Tests
  test 'create allows admins and team members on current project to create tags on the current project' do
    assert policy(@admin, @project, Tag.new(discipline: @discipline)).create?
    assert policy(@app_owner, @project, Tag.new(discipline: @discipline)).create?
    assert policy(@project_manager, @project, Tag.new(discipline: @discipline)).create?
    assert policy(@team_member, @project, Tag.new(discipline: @discipline)).create?
  end

  test 'create denies admins and team members on current project to create tag on different project' do
    refute policy(@admin, @project, Tag.new(discipline: @other_discipline)).create?
    refute policy(@app_owner, @project, Tag.new(discipline: @other_discipline)).create?
    refute policy(@project_manager, @project, Tag.new(discipline: @other_discipline)).create?
    refute policy(@team_member, @project, Tag.new(discipline: @other_discipline)).create?
  end

  test 'create allows admins with nil current project to create tags on any project' do
    assert policy(@admin, nil, Tag.new(discipline: @other_discipline)).create?
    assert policy(@app_owner, nil, Tag.new(discipline: @other_discipline)).create?
  end

  test 'create denies team members with nil current project to create tags on any project' do
    refute policy(@team_member, nil, Tag.new(discipline: @discipline)).create?
    refute policy(@team_member, nil, Tag.new(discipline: @other_discipline)).create?
  end

  test 'create denies users without project role' do
    refute policy(@regular_user, @project, Tag.new(discipline: @discipline)).create?
    refute policy(nil, @project, Tag.new(discipline: @discipline)).create?
  end

  # Edit tests defer to update
  # Update Tests
  test 'update allows admins and team members on current project to update tags on the current project' do
    assert policy(@admin, @project, @tag).update?
    assert policy(@app_owner, @project, @tag).update?
    assert policy(@project_manager, @project, @tag).update?
    assert policy(@team_member, @project, @tag).update?
  end

  test 'update denies admins and team members on current project to update tag on different project' do
    refute policy(@admin, @project, @other_tag).update?
    refute policy(@app_owner, @project, @other_tag).update?
    refute policy(@project_manager, @project, @other_tag).update?
    refute policy(@team_member, @project, @other_tag).update?
  end

  test 'update allows admins with nil current project to update tags on any project' do
    assert policy(@admin, nil, @tag).update?
    assert policy(@app_owner, nil, @tag).update?
  end

  test 'update denies team members with nil current project to update tags on any project' do
    refute policy(@team_member, nil, @tag).update?
    refute policy(@team_member, nil, @other_tag).update?
  end

  test 'update denies users without project role' do
    refute policy(@regular_user, @project, @tag).update?
    refute policy(nil, @project, @tag).update?
  end

  # Destroy Tests
  test 'destroy allows admin and app_owner' do
    assert policy(@admin, @project, @tag).destroy?
    assert policy(@app_owner, @project, @tag).destroy?
  end

  test 'destroy denies project manager, team members and regular users' do
    refute policy(@project_manager, @project, @tag).destroy?
    refute policy(@team_member, @project, @tag).destroy?
    refute policy(@regular_user, @project, @tag).destroy?
    refute policy(nil, @project, @tag).destroy?
  end
end
