require 'test_helper'
require_relative '../helpers/policy_test_helpers'

class DisciplinePolicyTest < ActiveSupport::TestCase
  include PolicyTestHelpers

  def setup
    setup_policy_test
    @new_discipline = @project.disciplines.build()
  end
  
  # Helper to create policy with user and project context
  def policy(user, project, record = nil)
    user_context = ApplicationPolicy::UserContext.new(user, project)
    DisciplinePolicy.new(user_context, record || Discipline)
  end

  # Scope Tests
  test 'scope for admins and team_member returns discplines for current project' do
    context = ApplicationPolicy::UserContext.new(@admin, @project)
    scope = DisciplinePolicy::Scope.new(context, Discipline).resolve
    assert_includes scope, @discipline
    refute_includes scope, @other_discipline
    context = ApplicationPolicy::UserContext.new(@team_member, @project)
    scope = DisciplinePolicy::Scope.new(context, Discipline).resolve
    assert_includes scope, @discipline
    refute_includes scope, @other_discipline
  end

  test 'scope for team member returns empty when no current project is selected' do
    context = ApplicationPolicy::UserContext.new(@team_member, nil)
    scope = DisciplinePolicy::Scope.new(context, Discipline).resolve
    assert_empty scope
  end

  test 'scope for admins includes all disciplines when no current project is selected' do
    context = ApplicationPolicy::UserContext.new(@admin, nil)
    scope = DisciplinePolicy::Scope.new(context, Discipline).resolve
    assert_includes scope, @discipline
    assert_includes scope, @other_discipline
    context = ApplicationPolicy::UserContext.new(@app_owner, nil)
    scope = DisciplinePolicy::Scope.new(context, Discipline).resolve
    assert_includes scope, @discipline
    assert_includes scope, @other_discipline
  end

  test 'scope for users without a role on current project is empty' do
    context = ApplicationPolicy::UserContext.new(@regular_user, @project)
    scope = DisciplinePolicy::Scope.new(context, Discipline).resolve
    assert_empty scope
    context = ApplicationPolicy::UserContext.new(@regular_user, nil)
    scope = DisciplinePolicy::Scope.new(context, Discipline).resolve
    assert_empty scope
  end
  
  # Index Tests
  test 'index? is available to admins and team members on current project' do
    assert policy(@admin, @project, @discipline).index?
    assert policy(@app_owner, @project, @discipline).index?
    assert policy(@project_manager, @project, @discipline).index?
    assert policy(@team_member, @project, @discipline).index?
  end

  test 'index? is available to admins without current project' do
    assert policy(@admin, nil, @discipline).index?
    assert policy(@app_owner, nil, @discipline).index?
  end
  
  test 'index? denies team member when no project is selected' do
    refute policy(@project_manager, nil, @discipline).index?
    refute policy(@team_member, nil, @discipline).index?
  end

  test 'index? is denied to user without a project role' do
    refute policy(@regular_user, @project, @discipline).index?
  end

  test 'index? is denied when user is not set' do
    refute policy(nil, @project, @discipline).index?
  end

  # Show Tests
  test 'show? allows admins and team members on current project to view discipline on current project' do
    assert policy(@project_manager, @project, @discipline).show?
    assert policy(@team_member, @project, @discipline).show?
    assert policy(@admin, @project, @discipline).show?
    assert policy(@app_owner, @project, @discipline).show?
  end

  test 'show? denies admins and team members on current project to view discipline on different project' do
    refute policy(@project_manager, @project, @other_discipline).show?
    refute policy(@team_member, @project, @other_discipline).show?
    refute policy(@admin, @project, @other_discipline).show?
    refute policy(@app_owner, @project, @other_discipline).show?
  end

  test 'show? allows admins with nil current project to view any discipline' do
    assert policy(@admin, nil, @discipline).show?
    assert policy(@admin, nil, @other_discipline).show?
  end

  test 'show? denies team members with nil current project to view any discipline' do
    refute policy(@team_member, nil, @discipline).show?
    refute policy(@team_member, nil, @other_discipline).show?
    refute policy(@project_manager, nil, @discipline).show?
    refute policy(@project_manager, nil, @other_discipline).show?
  end

  test 'show denies users without project access' do
    refute policy(@regular_user, @project, @discipline).show?
    refute policy(nil, @project, @discipline).show?
  end

  # New tests defer to create
  # Create Tests
  test 'create allows admins and project managers on current project to create disciplines on the current project' do
    assert policy(@admin, @project, Discipline.new(project: @project)).create?
    assert policy(@app_owner, @project, Discipline.new(project: @project)).create?
    assert policy(@project_manager, @project, Discipline.new(project: @project)).create?
  end
  
  test 'create denies project managers with nil current project to create disciplines on any project' do
    refute policy(@project_manager, nil, Discipline.new(project: @project)).create?
    refute policy(@project_manager, nil, Discipline.new(project: @other_project)).create?
  end

  test 'create denies users other than project managers to create disciplines on current project' do
    refute policy(@team_member, @project, Discipline.new(project: @project)).create?
    refute policy(@regular_user, @project, Discipline.new(project: @project)).create?
    refute policy(nil, @project, Discipline.new(project: @project)).create?
  end

  # Edit tests defer to update
  # Update Tests
  test 'update allows admins and project managers on current project to update disciplines' do
    assert policy(@admin, @project, @discipline).update?
    assert policy(@app_owner, @project, @discipline).update?
    assert policy(@project_manager, @project, @discipline).update?
  end

  test 'update denies team members on current project to update disciplines' do
    refute policy(@team_member, @project, @discipline).update?
  end

  test 'update denies admins and team members on current project to update discipline on different project' do
    refute policy(@admin, @project, @other_discipline).update?
    refute policy(@app_owner, @project, @other_discipline).update?
    refute policy(@project_manager, @project, @other_discipline).update?
    refute policy(@team_member, @project, @other_discipline).update?
  end

  test 'update allows admins with nil current project to update any discipline' do
    assert policy(@admin, nil, @discipline).update?
    assert policy(@admin, nil, @other_discipline).update?
    assert policy(@app_owner, nil, @discipline).update?
    assert policy(@app_owner, nil, @other_discipline).update?
  end

  test 'update denies team members with nil current project to update any discipline' do
    refute policy(@team_member, nil, @discipline).update?
    refute policy(@team_member, nil, @other_discipline).update?
    refute policy(@project_manager, nil, @discipline).update?
    refute policy(@project_manager, nil, @other_discipline).update?
  end

  test 'update denies users without project role' do
    refute policy(@regular_user, @project, @discipline).update?
    refute policy(nil, @project, @discipline).update?
  end

  # Destroy Tests
  test 'destroy allows admin and app_owner' do
    assert policy(@admin, @project, @discipline).destroy?
    assert policy(@app_owner, @project, @discipline).destroy?
  end

  test 'destroy denies project manager, team members and regular users' do
    refute policy(@project_manager, @project, @discipline).destroy?
    refute policy(@team_member, @project, @discipline).destroy?
    refute policy(@regular_user, @project, @discipline).destroy?
    refute policy(nil, @project, @discipline).destroy?
  end
end

