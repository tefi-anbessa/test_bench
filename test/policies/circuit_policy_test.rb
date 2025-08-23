require 'test_helper'

class CircuitPolicyTest < ActiveSupport::TestCase
  include PolicyHelpers
  
  def setup
    setup_policy_test
    
    # Create a switchboard with a tag associated with the project
    @switchboard = create(:switchboard)
    @tag = create(:tag, tagable: @switchboard, project: @project)
    
    # Create a circuit in the switchboard
    @circuit = create(:circuit, switchboard: @switchboard)
    
    # Add electrical_designer role to project_owner and team_member
    @project_owner.add_role(:project_owner, @project)
    @project_owner.add_role(:electrical_designer)
    
    @team_member.add_role(:team_member, @project)
    @team_member.add_role(:electrical_designer)
    
    # Make sure the circuit is associated with the project through the switchboard's tag
    @circuit.reload
  end

  # Scope Tests
  test 'scope for app owner shows all circuits' do
    scope = CircuitPolicy::Scope.new(user_context(@app_owner), Circuit).resolve
    assert_includes scope, @circuit
    assert_equal Circuit.count, scope.count
  end

  test 'scope for admin shows all circuits' do
    scope = CircuitPolicy::Scope.new(user_context(@admin), Circuit).resolve
    assert_includes scope, @circuit
    assert_equal Circuit.count, scope.count
  end

  test 'scope for project owner shows circuits in their project' do
    scope = CircuitPolicy::Scope.new(user_context(@project_owner), Circuit).resolve
    assert_includes scope, @circuit
    
    # Test that circuits in other projects are not included
    other_project = create(:project)
    other_switchboard = create(:switchboard)
    create(:tag, tagable: other_switchboard, project: other_project)
    other_circuit = create(:circuit, switchboard: other_switchboard)
    
    refute_includes scope, other_circuit
  end

  test 'scope for team member shows circuits in their project' do
    scope = CircuitPolicy::Scope.new(user_context(@team_member), Circuit).resolve
    assert_includes scope, @circuit
    
    # Test that circuits in other projects are not included
    other_project = create(:project)
    other_switchboard = create(:switchboard)
    create(:tag, tagable: other_switchboard, project: other_project)
    other_circuit = create(:circuit, switchboard: other_switchboard)
    
    refute_includes scope, other_circuit
  end

  test 'scope for regular user shows no circuits' do
    scope = CircuitPolicy::Scope.new(user_context(@regular_user), Circuit).resolve
    assert_empty scope
  end

  # Index Tests
  test 'index? allows any authenticated user' do
    assert CircuitPolicy.new(user_context(@regular_user), Circuit).index?
  end

  test 'index? denies unauthenticated users' do
    refute CircuitPolicy.new(nil, Circuit).index?
  end

  # Show Tests
  test 'show? allows users with project access' do
    assert CircuitPolicy.new(user_context(@project_owner), @circuit).show?
    assert CircuitPolicy.new(user_context(@team_member), @circuit).show?
  end

  test 'show? denies users without project access' do
    refute CircuitPolicy.new(user_context(@regular_user), @circuit).show?
    refute CircuitPolicy.new(user_context(nil), @circuit).show?
  end

  # Create Tests
  test 'create allows users with electrical designer role' do
    assert CircuitPolicy.new(user_context(@project_owner), Circuit.new).create?
    assert CircuitPolicy.new(user_context(@team_member), Circuit.new).create?
  end

  test 'create denies users without electrical designer role' do
    regular_user = create(:user)
    regular_user.add_role(:team_member, @project)  # Has project role but not electrical_designer
    
    refute CircuitPolicy.new(user_context(regular_user), Circuit.new).create?
    refute CircuitPolicy.new(user_context(@regular_user), Circuit.new).create?
    refute CircuitPolicy.new(user_context(nil), Circuit.new).create?
  end

  # Update Tests
  test 'update allows users with electrical designer role' do
    assert CircuitPolicy.new(user_context(@project_owner), @circuit).update?
    assert CircuitPolicy.new(user_context(@team_member), @circuit).update?
  end

  test 'update denies users without electrical designer role' do
    regular_user = create(:user)
    regular_user.add_role(:team_member, @project)  # Has project role but not electrical_designer
    
    refute CircuitPolicy.new(user_context(regular_user), @circuit).update?
    refute CircuitPolicy.new(user_context(@regular_user), @circuit).update?
    refute CircuitPolicy.new(user_context(nil), @circuit).update?
  end

  # Destroy Tests
  test 'destroy allows admin and app_owner' do
    assert CircuitPolicy.new(user_context(@admin), @circuit).destroy?
    assert CircuitPolicy.new(user_context(@app_owner), @circuit).destroy?
  end

  test 'destroy denies non-admin users' do
    refute CircuitPolicy.new(user_context(@project_owner), @circuit).destroy?
    refute CircuitPolicy.new(user_context(@team_member), @circuit).destroy?
    refute CircuitPolicy.new(user_context(@regular_user), @circuit).destroy?
    refute CircuitPolicy.new(user_context(nil), @circuit).destroy?
  end
end
