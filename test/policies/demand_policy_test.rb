require 'test_helper'

class DemandPolicyTest < ActiveSupport::TestCase
  include PolicyHelpers
  
  def setup
    setup_policy_test
    
    # Create electrical discipline
    @e = create(:discipline, :e)
    
    # Create a motor and demand with a tag associated with the project
    @motor = create(:motor, tag: create(:tag, :unique_tag, prefix: "M", discipline: @e, project: @project))
    @demand = create(:demand, demandable: @motor)
    
    # Create a motor and demand in another project
    @other_motor = create(:motor, tag: create(:tag, :unique_tag, prefix: "M", discipline: @e, 
                                    project: @other_project))
    @other_demand = create(:demand, demandable: @other_motor)

    # Add electrical_designer role
    @electrical_designer = create(:user)
    @electrical_designer.grant(:team_member, @project)
    @electrical_designer.grant(:electrical_designer)
  end
  
  # Helper to create policy with user and project context
  def policy(user, project, record = nil)
    user_context = ApplicationPolicy::UserContext.new(user, project)
    DemandPolicy.new(user_context, record || @demand)
  end

  # Scope Tests
  test 'scope returns demands for current project' do
    scope = DemandPolicy::Scope.new(ApplicationPolicy::UserContext.new(@team_member, @project), Demand).resolve
    assert_includes scope, @demand
    refute_includes scope, @other_demand
  end

  test 'scope returns empty when no project is selected' do
    scope = DemandPolicy::Scope.new(ApplicationPolicy::UserContext.new(@team_member, nil), Demand).resolve
    assert_empty scope
  end

  # Index Tests
  test 'index? is available to admin and app_owner without current project' do
    assert policy(@admin, nil).index?
    assert policy(@app_owner, nil).index?
  end

  test 'index? is available to users with a project role' do
    assert policy(@team_member, @project).index?
  end

  test 'index? requires user to have a project role' do
    refute policy(@regular_user, @project).index?
  end
  
  test 'index? denies when no project is selected' do
    refute policy(@team_member, nil).index?
  end
  
  # Show Tests
  test 'show? allows viewing in current project' do
    assert policy(@team_member, @project, @demand).show?
  end
  
  test 'show? denies viewing in other projects' do
    refute policy(@regular_user, @project, @other_demand).show?
  end
  
  test 'show? denies when no project is selected' do
    refute policy(@team_member, nil, @demand).show?
  end

  # New Tests defer to create
  # Create Tests
  test 'create allows users with electrical designer role' do
    assert policy(@electrical_designer, @project, Demand.new).create?
  end

  test 'create denies users without electrical designer role' do
    refute policy(@regular_user, @project, Demand.new).create?
    refute policy(@project_owner, @project, Demand.new).create?
    refute policy(nil, @project, Demand.new).create?
  end

  # Edit Tests defer to update
  # Update Tests
  test 'update allows users with electrical designer role' do
    assert policy(@electrical_designer, @project, @circuit).update?
  end

  test 'update denies users without electrical designer role' do
    refute policy(@regular_user, @project, @circuit).update?
    refute policy(@project_owner, @project, @circuit).update?
    refute policy(nil, @project, @circuit).update?
  end

  # Destroy Tests
  # Uses default ApplicationPolicy behavior (admin and app_owner only)
  test 'destroy allows admin and app_owner' do
    assert policy(@admin, @project, @circuit).destroy?
    assert policy(@app_owner, @project, @circuit).destroy?
  end

  test 'destroy denies non-admin users' do
    
    # Electrical designers cannot destroy
    refute policy(@electrical_designer, @project, @circuit).destroy?
    
    # Regular users cannot destroy
    refute policy(@regular_user, @project, @circuit).destroy?
    
    # Project owners cannot destroy
    refute policy(@project_owner, @project, @circuit).destroy?
    
    # Team members cannot destroy
    refute policy(@team_member, @project, @circuit).destroy?
    
    # Unauthenticated users cannot destroy
    refute policy(nil, @project, @circuit).destroy?
  end
  
  private
  
  def user_context
    ApplicationPolicy::UserContext.new(@user, @project)
  end
end
