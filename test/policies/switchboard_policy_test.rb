require 'test_helper'

class SwitchboardPolicyTest < ActiveSupport::TestCase
  include PolicyHelpers
  
  def setup
    setup_policy_test
    
    # Create a switchboard with a tag associated with the project
    @switchboard = create(:switchboard)
    @tag = create(:tag, tagable: @switchboard, project: @project)
    
    # Add electrical_designer role to project_owner and team_member
    @project_owner.add_role(:project_owner, @project)
    @project_owner.add_role(:electrical_designer)
    
    @team_member.add_role(:team_member, @project)
    @team_member.add_role(:electrical_designer)
    
    # Make sure the switchboard is associated with the project through the tag
    @switchboard.reload
  end

  # Scope Tests
  test 'scope for app owner shows all switchboards' do
    scope = SwitchboardPolicy::Scope.new(user_context(@app_owner), Switchboard).resolve
    assert_includes scope, @switchboard
    assert_equal Switchboard.count, scope.count
  end

  test 'scope for admin shows all switchboards' do
    scope = SwitchboardPolicy::Scope.new(user_context(@admin), Switchboard).resolve
    assert_includes scope, @switchboard
    assert_equal Switchboard.count, scope.count
  end

  test 'scope for project owner shows switchboards in their project' do
    scope = SwitchboardPolicy::Scope.new(user_context(@project_owner), Switchboard).resolve
    assert_includes scope, @switchboard
    
    # Test that switchboards in other projects are not included
    other_project = create(:project)
    other_switchboard = create(:switchboard)
    create(:tag, tagable: other_switchboard, project: other_project)
    
    refute_includes scope, other_switchboard
  end

  test 'scope for team member shows switchboards in their project' do
    scope = SwitchboardPolicy::Scope.new(user_context(@team_member), Switchboard).resolve
    assert_includes scope, @switchboard
    
    # Test that switchboards in other projects are not included
    other_project = create(:project)
    other_switchboard = create(:switchboard)
    create(:tag, tagable: other_switchboard, project: other_project)
    
    refute_includes scope, other_switchboard
  end

  test 'scope for regular user shows no switchboards' do
    scope = SwitchboardPolicy::Scope.new(user_context(@regular_user), Switchboard).resolve
    assert_empty scope
  end

  # Index Tests
  test 'index? allows any authenticated user' do
    assert SwitchboardPolicy.new(user_context(@regular_user), Switchboard).index?
  end

  test 'index? denies unauthenticated users' do
    refute SwitchboardPolicy.new(nil, Switchboard).index?
  end

  # Show Tests
  test 'show? allows users with project access' do
    assert SwitchboardPolicy.new(user_context(@project_owner), @switchboard).show?
    assert SwitchboardPolicy.new(user_context(@team_member), @switchboard).show?
  end

  test 'show? denies users without project access' do
    refute SwitchboardPolicy.new(user_context(@regular_user), @switchboard).show?
    refute SwitchboardPolicy.new(user_context(nil), @switchboard).show?
  end

  # Create Tests
  test 'create allows users with electrical designer role' do
    assert SwitchboardPolicy.new(user_context(@project_owner), Switchboard.new).create?
    assert SwitchboardPolicy.new(user_context(@team_member), Switchboard.new).create?
  end

  test 'create denies users without electrical designer role' do
    regular_user = create(:user)
    regular_user.add_role(:team_member, @project)  # Has project role but not electrical_designer
    
    refute SwitchboardPolicy.new(user_context(regular_user), Switchboard.new).create?
    refute SwitchboardPolicy.new(user_context(@regular_user), Switchboard.new).create?
    refute SwitchboardPolicy.new(user_context(nil), Switchboard.new).create?
  end

  # Update Tests
  test 'update allows users with electrical designer role' do
    assert SwitchboardPolicy.new(user_context(@project_owner), @switchboard).update?
    assert SwitchboardPolicy.new(user_context(@team_member), @switchboard).update?
  end

  test 'update denies users without electrical designer role' do
    regular_user = create(:user)
    regular_user.add_role(:team_member, @project)  # Has project role but not electrical_designer
    
    refute SwitchboardPolicy.new(user_context(regular_user), @switchboard).update?
    refute SwitchboardPolicy.new(user_context(@regular_user), @switchboard).update?
    refute SwitchboardPolicy.new(user_context(nil), @switchboard).update?
  end

  # Destroy Tests
  test 'destroy allows admin and app_owner' do
    assert SwitchboardPolicy.new(user_context(@admin), @switchboard).destroy?
    assert SwitchboardPolicy.new(user_context(@app_owner), @switchboard).destroy?
  end

  test 'destroy denies non-admin users' do
    refute SwitchboardPolicy.new(user_context(@project_owner), @switchboard).destroy?
    refute SwitchboardPolicy.new(user_context(@team_member), @switchboard).destroy?
    refute SwitchboardPolicy.new(user_context(@regular_user), @switchboard).destroy?
    refute SwitchboardPolicy.new(user_context(nil), @switchboard).destroy?
  end
end
