require 'test_helper'

class CablePolicyTest < ActiveSupport::TestCase
  include PolicyHelpers
  
  def setup
    setup_policy_test
    
    # Create a cable with a tag associated with the project
    @cable = create(:cable)
    @tag = create(:tag, tagable: @cable, project: @project)
    
    # Add electrical_designer role to project_owner and team_member
    @project_owner.add_role(:project_owner, @project)
    @project_owner.add_role(:electrical_designer)
    
    @team_member.add_role(:team_member, @project)
    @team_member.add_role(:electrical_designer)
    
    # Make sure the cable is associated with the project through the tag
    @cable.reload
  end

  # Scope Tests
  test 'scope for app owner shows all cables' do
    scope = CablePolicy::Scope.new(user_context(@app_owner), Cable).resolve
    assert_includes scope, @cable
    assert_equal Cable.count, scope.count
  end

  test 'scope for admin shows all cables' do
    scope = CablePolicy::Scope.new(user_context(@admin), Cable).resolve
    assert_includes scope, @cable
    assert_equal Cable.count, scope.count
  end

  test 'scope for project owner shows cables in their project' do
    @project_owner.add_role(:project_owner, @project)
    scope = CablePolicy::Scope.new(user_context(@project_owner), Cable).resolve
    assert_includes scope, @cable
    
    # Test that cables in other projects are not included
    other_project = create(:project)
    other_cable = create(:cable)
    create(:tag, tagable: other_cable, project: other_project)
    
    refute_includes scope, other_cable
  end

  test 'scope for team member shows cables in their project' do
    @team_member.add_role(:team_member, @project)
    scope = CablePolicy::Scope.new(user_context(@team_member), Cable).resolve
    assert_includes scope, @cable
    
    # Test that cables in other projects are not included
    other_project = create(:project)
    other_cable = create(:cable)
    create(:tag, tagable: other_cable, project: other_project)
    
    refute_includes scope, other_cable
  end

  test 'scope for regular user shows no cables' do
    scope = CablePolicy::Scope.new(user_context(@regular_user), Cable).resolve
    assert_empty scope
  end

  # Index Tests
  test 'index? allows any authenticated user' do
    assert CablePolicy.new(user_context(@regular_user), Cable).index?
  end

  test 'index? denies unauthenticated users' do
    refute CablePolicy.new(nil, Cable).index?
  end

  # Show Tests
  test 'show? allows users with project access' do
    @project_owner.add_role(:project_owner, @project)
    @team_member.add_role(:team_member, @project)
    
    assert CablePolicy.new(user_context(@project_owner), @cable).show?
    assert CablePolicy.new(user_context(@team_member), @cable).show?
  end

  test 'show? denies users without project access' do
    refute CablePolicy.new(user_context(@regular_user), @cable).show?
    refute CablePolicy.new(user_context(nil), @cable).show?
  end

  # Create Tests
  test 'create allows users with electrical designer role' do
    @project_owner.add_role(:project_owner, @project)
    @team_member.add_role(:team_member, @project)
    
    # New cable will be created with a tag in the current project context
    assert CablePolicy.new(user_context(@project_owner), Cable.new).create?
    assert CablePolicy.new(user_context(@team_member), Cable.new).create?
  end

  test 'create denies users without electrical designer role' do
    regular_user = create(:user)
    regular_user.add_role(:team_member, @project)  # Has project role but not electrical_designer
    
    refute CablePolicy.new(user_context(regular_user), Cable.new).create?
    refute CablePolicy.new(user_context(@regular_user), Cable.new).create?
    refute CablePolicy.new(user_context(nil), Cable.new).create?
  end

  # Update Tests
  test 'update allows users with electrical designer role' do
    @project_owner.add_role(:project_owner, @project)
    @team_member.add_role(:team_member, @project)
    
    assert CablePolicy.new(user_context(@project_owner), @cable).update?
    assert CablePolicy.new(user_context(@team_member), @cable).update?
  end

  test 'update denies users without electrical designer role' do
    regular_user = create(:user)
    regular_user.add_role(:team_member, @project)  # Has project role but not electrical_designer
    
    refute CablePolicy.new(user_context(regular_user), @cable).update?
    refute CablePolicy.new(user_context(@regular_user), @cable).update?
    refute CablePolicy.new(user_context(nil), @cable).update?
  end

  # Destroy Tests
  # Uses default ApplicationPolicy behavior (admin and app_owner only)
  test 'destroy allows admin and app_owner' do
    assert CablePolicy.new(user_context(@admin), @cable).destroy?
    assert CablePolicy.new(user_context(@app_owner), @cable).destroy?
  end

  test 'destroy denies non-admin users' do
    # Regular users cannot destroy
    refute CablePolicy.new(user_context(@regular_user), @cable).destroy?
    
    # Project owners cannot destroy
    refute CablePolicy.new(user_context(@project_owner), @cable).destroy?
    
    # Team members cannot destroy
    refute CablePolicy.new(user_context(@team_member), @cable).destroy?
    
    # Unauthenticated users cannot destroy
    refute CablePolicy.new(nil, @cable).destroy?
  end
end
