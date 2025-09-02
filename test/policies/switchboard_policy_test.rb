require 'test_helper'

class SwitchboardPolicyTest < ActiveSupport::TestCase
  include PolicyHelpers
  
  def setup
    setup_policy_test

    # Create electrical discipline
    @e = create(:discipline, :e)
    
    # Create a switchboard with a tag associated with the project
    @tag = create(:tag, :unique_tag, prefix: 'EX', discipline: @e, project: @project)
    @switchboard = create(:switchboard, tag: @tag)

    # Create a switchboard in another project
    @other_tag = create(:tag, :unique_tag, prefix: 'EX', discipline: @e, project: @other_project)
    @other_switchboard = create(:switchboard, tag: @other_tag)
    
    # Add electrical_designer role
    @electrical_designer = create(:user)
    @electrical_designer.grant(:team_member, @project)
    @electrical_designer.grant(:electrical_designer)
  end
  
  # Helper to create policy with user and project context
  def policy(user, project, record = nil)
    user_context = ApplicationPolicy::UserContext.new(user, project)
    SwitchboardPolicy.new(user_context, record || Switchboard)
  end

  # Scope Tests
  test 'scope returns only switchboards for current project' do
    scope = SwitchboardPolicy::Scope.new(ApplicationPolicy::UserContext.new(@team_member, @project), Switchboard).resolve
    assert_includes scope, @switchboard
    refute_includes scope, @other_switchboard
  end
  
  test 'scope returns empty when no project is selected' do
    scope = SwitchboardPolicy::Scope.new(ApplicationPolicy::UserContext.new(@team_member, nil), Switchboard).resolve
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
    assert policy(@team_member, @project, @switchboard).show?
  end
  
  test 'show? denies viewing in other projects' do
    refute policy(@team_member, @project, @other_switchboard).show?
  end
  
  test 'show? denies when no project is selected' do
    refute policy(@team_member, nil, @switchboard).show?
  end

  # New Tests defer to create
  # Create Tests
  test 'create allows users with electrical designer role' do
    assert policy(@electrical_designer, @project, Switchboard.new).create?
  end

  test 'create denies users without electrical designer role' do
    refute policy(@regular_user, @project, Switchboard.new).create?
    refute policy(@team_member, @project, Switchboard.new).create?
    refute policy(nil, @project, Switchboard.new).create?
  end

  # Edit Tests defer to update
  # Update Tests
  test 'update allows users with electrical designer role' do
    assert policy(@electrical_designer, @project, @switchboard).update?
  end

  test 'update denies users without electrical designer role' do
    refute policy(@regular_user, @project, @switchboard).update?
    refute policy(@team_member, @project, @switchboard).update?
    refute policy(nil, @project, @switchboard).update?
  end

  # Destroy Tests
  # Uses default ApplicationPolicy behavior (admin and app_owner only)
  test 'destroy allows admin and app_owner' do
    assert policy(@admin, @project, @switchboard).destroy?
    assert policy(@app_owner, @project, @switchboard).destroy?
  end

  test 'destroy denies non-admin users' do
    
    # Electrical designers cannot destroy
    refute policy(@electrical_designer, @project, @switchboard).destroy?
    
    # Regular users cannot destroy
    refute policy(@regular_user, @project, @switchboard).destroy?
    
    # Project owners cannot destroy
    refute policy(@project_owner, @project, @switchboard).destroy?
    
    # Team members cannot destroy
    refute policy(@team_member, @project, @switchboard).destroy?
    
    # Unauthenticated users cannot destroy
    refute SwitchboardPolicy.new(nil, @switchboard).destroy?
  end
end
