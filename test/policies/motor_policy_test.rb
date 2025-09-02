require 'test_helper'

class MotorPolicyTest < ActiveSupport::TestCase
  include PolicyHelpers
  
  def setup
    setup_policy_test

    # Create electrical discipline
    @e = create(:discipline, :e)
    
    # Create a motor with a tag associated with the project
    @tag = create(:tag, :unique_tag, prefix: 'M', discipline: @e, project: @project)
    @motor = create(:motor, tag: @tag)

    # Create a motor in another project
    @other_tag = create(:tag, :unique_tag, prefix: 'M', discipline: @e, project: @other_project)
    @other_motor = create(:motor, tag: @other_tag)
    
    # Add electrical_designer role
    @electrical_designer = create(:user)
    @electrical_designer.grant(:team_member, @project)
    @electrical_designer.grant(:electrical_designer)
  end
  
  # Helper to create policy with user and project context
  def policy(user, project, record = nil)
    user_context = ApplicationPolicy::UserContext.new(user, project)
    MotorPolicy.new(user_context, record || Motor)
  end

  # Scope Tests
  test 'scope returns motors for current project' do
    scope = MotorPolicy::Scope.new(ApplicationPolicy::UserContext.new(@team_member, @project), Motor).resolve
    assert_includes scope, @motor
    refute_includes scope, @other_motor
  end
  
  test 'scope returns empty when no project is selected' do
    scope = MotorPolicy::Scope.new(ApplicationPolicy::UserContext.new(@team_member, nil), Motor).resolve
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
    refute policy(@team_member, nil).index?
  end

  # Show Tests
  test 'show? allows viewing in current project' do
    assert policy(@team_member, @project, @motor).show?
  end
  
  test 'show? denies viewing in other projects' do
    refute policy(@team_member, @project, @other_motor).show?
  end
  
  test 'show? denies when no project is selected' do
    refute policy(@team_member, nil, @motor).show?
  end

  # New Tests defer to create
  # Create Tests
  test 'create allows users with electrical designer role' do
    assert policy(@electrical_designer, @project, Motor.new).create?
  end

  test 'create denies users without electrical designer role' do
    refute policy(@regular_user, @project, Motor.new).create?
    refute policy(@team_member, @project, Motor.new).create?
    refute policy(nil, @project, Cable.new).create?
  end

  # Edit Tests defer to update
  # Update Tests
  test 'update allows users with electrical designer role' do
    assert policy(@electrical_designer, @project, @motor).update?
  end

  test 'update denies users without electrical designer role' do
    refute policy(@regular_user, @project, @motor).update?
    refute policy(@team_member, @project, @motor).update?
    refute policy(nil, @project, @motor).update?
  end

  # Destroy Tests
  # Uses default ApplicationPolicy behavior (admin and app_owner only)
  test 'destroy allows admin and app_owner' do
    assert policy(@admin, @project, @motor).destroy?
    assert policy(@app_owner, @project, @motor).destroy?
  end

  test 'destroy denies non-admin users' do
    
    # Electrical designers cannot destroy
    refute policy(@electrical_designer, @project, @motor).destroy?
    
    # Regular users cannot destroy
    refute policy(@regular_user, @project, @motor).destroy?
    
    # Project owners cannot destroy
    refute policy(@project_owner, @project, @motor).destroy?
    
    # Team members cannot destroy
    refute policy(@team_member, @project, @motor).destroy?
    
    # Unauthenticated users cannot destroy
    refute MotorPolicy.new(nil, @motor).destroy?
  end
end
