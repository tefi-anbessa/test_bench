require 'test_helper'

class MotorPolicyTest < ActiveSupport::TestCase
  include PolicyHelpers
  
  def setup
    setup_policy_test
    
    # Create a motor with a tag associated with the project
    @motor = create(:motor)
    @tag = create(:tag, tagable: @motor, project: @project)
    
    # Add electrical_designer role to project_owner and team_member
    @project_owner.add_role(:project_owner, @project)
    @project_owner.add_role(:electrical_designer)
    
    @team_member.add_role(:team_member, @project)
    @team_member.add_role(:electrical_designer)
    
    # Make sure the motor is associated with the project through the tag
    @motor.reload
  end

  # Scope Tests
  test 'scope for app owner shows all motors' do
    scope = MotorPolicy::Scope.new(user_context(@app_owner), Motor).resolve
    assert_includes scope, @motor
    assert_equal Motor.count, scope.count
  end

  test 'scope for admin shows all motors' do
    scope = MotorPolicy::Scope.new(user_context(@admin), Motor).resolve
    assert_includes scope, @motor
    assert_equal Motor.count, scope.count
  end

  test 'scope for project owner shows motors in their project' do
    scope = MotorPolicy::Scope.new(user_context(@project_owner), Motor).resolve
    assert_includes scope, @motor
    
    # Test that motors in other projects are not included
    other_project = create(:project)
    other_motor = create(:motor)
    create(:tag, tagable: other_motor, project: other_project)
    
    refute_includes scope, other_motor
  end

  test 'scope for team member shows motors in their project' do
    scope = MotorPolicy::Scope.new(user_context(@team_member), Motor).resolve
    assert_includes scope, @motor
    
    # Test that motors in other projects are not included
    other_project = create(:project)
    other_motor = create(:motor)
    create(:tag, tagable: other_motor, project: other_project)
    
    refute_includes scope, other_motor
  end

  test 'scope for regular user shows no motors' do
    scope = MotorPolicy::Scope.new(user_context(@regular_user), Motor).resolve
    assert_empty scope
  end

  # Index Tests
  test 'index? allows any authenticated user' do
    assert MotorPolicy.new(user_context(@regular_user), Motor).index?
  end

  test 'index? denies unauthenticated users' do
    refute MotorPolicy.new(nil, Motor).index?
  end

  # Show Tests
  test 'show? allows users with project access' do
    assert MotorPolicy.new(user_context(@project_owner), @motor).show?
    assert MotorPolicy.new(user_context(@team_member), @motor).show?
  end

  test 'show? denies users without project access' do
    refute MotorPolicy.new(user_context(@regular_user), @motor).show?
    refute MotorPolicy.new(user_context(nil), @motor).show?
  end

  # Create Tests
  test 'create allows users with electrical designer role' do
    assert MotorPolicy.new(user_context(@project_owner), Motor.new).create?
    assert MotorPolicy.new(user_context(@team_member), Motor.new).create?
  end

  test 'create denies users without electrical designer role' do
    regular_user = create(:user)
    regular_user.add_role(:team_member, @project)  # Has project role but not electrical_designer
    
    refute MotorPolicy.new(user_context(regular_user), Motor.new).create?
    refute MotorPolicy.new(user_context(@regular_user), Motor.new).create?
    refute MotorPolicy.new(user_context(nil), Motor.new).create?
  end

  # Update Tests
  test 'update allows users with electrical designer role' do
    assert MotorPolicy.new(user_context(@project_owner), @motor).update?
    assert MotorPolicy.new(user_context(@team_member), @motor).update?
  end

  test 'update denies users without electrical designer role' do
    regular_user = create(:user)
    regular_user.add_role(:team_member, @project)  # Has project role but not electrical_designer
    
    refute MotorPolicy.new(user_context(regular_user), @motor).update?
    refute MotorPolicy.new(user_context(@regular_user), @motor).update?
    refute MotorPolicy.new(user_context(nil), @motor).update?
  end

  # Destroy Tests
  test 'destroy allows admin and app_owner' do
    assert MotorPolicy.new(user_context(@admin), @motor).destroy?
    assert MotorPolicy.new(user_context(@app_owner), @motor).destroy?
  end

  test 'destroy denies non-admin users' do
    refute MotorPolicy.new(user_context(@project_owner), @motor).destroy?
    refute MotorPolicy.new(user_context(@team_member), @motor).destroy?
    refute MotorPolicy.new(user_context(@regular_user), @motor).destroy?
    refute MotorPolicy.new(user_context(nil), @motor).destroy?
  end
end
