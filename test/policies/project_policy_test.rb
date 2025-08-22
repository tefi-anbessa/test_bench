require 'test_helper'

class ProjectPolicyTest < ActiveSupport::TestCase
  def setup
    @project = create(:project)
    @app_owner = create(:user, :app_owner)
    @admin = create(:user, :admin)
    @regular_user = create(:user)
    @project_owner = create(:user)
    @project_owner.add_role(:project_owner, @project)
    @team_member = create(:user)
    @team_member.add_role(:team_member, @project)
  end

  # Scope tests
  def test_scope_for_app_owner
    projects = ProjectPolicy::Scope.new(@app_owner, Project).resolve
    assert_includes projects, @project
  end

  def test_scope_for_admin
    projects = ProjectPolicy::Scope.new(@admin, Project).resolve
    assert_includes projects, @project
  end

  def test_scope_for_project_owner
    projects = ProjectPolicy::Scope.new(@project_owner, Project).resolve
    assert_includes projects, @project
  end

  def test_scope_for_team_member
    projects = ProjectPolicy::Scope.new(@team_member, Project).resolve
    assert_includes projects, @project
  end

  def test_scope_for_regular_user
    projects = ProjectPolicy::Scope.new(@regular_user, Project).resolve
    assert_not_includes projects, @project
  end

  # Show tests
  def test_show_allows_anyone
    assert ProjectPolicy.new(@regular_user, @project).show?
    assert ProjectPolicy.new(@app_owner, @project).show?
    assert ProjectPolicy.new(@admin, @project).show?
    assert ProjectPolicy.new(@project_owner, @project).show?
    assert ProjectPolicy.new(@team_member, @project).show?
  end

  # New tests
  def test_new_allows_app_owner
    assert ProjectPolicy.new(@app_owner, Project).new?
  end

  def test_new_denies_non_owners
    refute ProjectPolicy.new(@admin, Project).new?
    refute ProjectPolicy.new(@regular_user, Project).new?
    refute ProjectPolicy.new(@project_owner, Project).new?
  end

  # Create tests
  def test_create_allows_app_owner
    assert ProjectPolicy.new(@app_owner, Project).create?
  end

  def test_create_denies_non_owners
    refute ProjectPolicy.new(@admin, Project).create?
    refute ProjectPolicy.new(@regular_user, Project).create?
    refute ProjectPolicy.new(@project_owner, Project).create?
  end

  # Edit tests
  def test_edit_allows_app_owner
    assert ProjectPolicy.new(@app_owner, @project).edit?
  end

  def test_edit_allows_admin
    assert ProjectPolicy.new(@admin, @project).edit?
  end

  def test_edit_allows_project_owner
    assert ProjectPolicy.new(@project_owner, @project).edit?
  end

  def test_edit_denies_team_members_and_regular_users
    refute ProjectPolicy.new(@team_member, @project).edit?
    refute ProjectPolicy.new(@regular_user, @project).edit?
  end
  def test_destroy_allows_app_owner
    assert ProjectPolicy.new(@app_owner, @project).destroy?
  end

  def test_destroy_denies_non_owners
    refute ProjectPolicy.new(@admin, @project).destroy?
    refute ProjectPolicy.new(@regular_user, @project).destroy?
    refute ProjectPolicy.new(@project_owner, @project).destroy?
    refute ProjectPolicy.new(@team_member, @project).destroy?
  end

  def test_destroy_denies_unauthenticated_users
    refute ProjectPolicy.new(nil, @project).destroy?
  end

  # Update tests (aliased to edit?)
  def test_update_follows_edit_permissions
    assert ProjectPolicy.new(@app_owner, @project).update?
    assert ProjectPolicy.new(@admin, @project).update?
    assert ProjectPolicy.new(@project_owner, @project).update?
    refute ProjectPolicy.new(@team_member, @project).update?
    refute ProjectPolicy.new(@regular_user, @project).update?
  end

  # Role management tests
  def test_can_manage_team_members
    assert ProjectPolicy.new(@app_owner, @project).manage_team_members?
    assert ProjectPolicy.new(@project_owner, @project).manage_team_members?
    refute ProjectPolicy.new(@admin, @project).manage_team_members?
    refute ProjectPolicy.new(@team_member, @project).manage_team_members?
    refute ProjectPolicy.new(@regular_user, @project).manage_team_members?
  end
end
