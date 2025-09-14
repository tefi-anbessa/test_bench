require 'test_helper'

class CablePolicyTest < ActiveSupport::TestCase
  include PolicyHelpers
  
  def setup
    setup_policy_test

    # Create electrical discipline
    @e = create(:discipline, :e)
    
    # Create a cable with a tag associated with the project
    @tag = create(:tag, :unique_tag, prefix: 'EC', discipline: @e, project: @project)
    @cable = create(:cable, tag: @tag)

    # Create a cable in another project
    @other_tag = create(:tag, :unique_tag, prefix: 'EC', discipline: @e, project: @other_project)
    @other_cable = create(:cable, tag: @other_tag)
    
    # Add electrical_designer role
    @electrical_designer = create(:user)
    @electrical_designer.grant(:team_member, @project)
    @electrical_designer.grant(:electrical_designer)
  end
  
  # Helper to create policy with user and project context
  def policy(user, project, record = nil)
    user_context = ApplicationPolicy::UserContext.new(user, project)
    CablePolicy.new(user_context, record || Cable)
  end

  # Scope Tests
  test 'scope returns cables for current project' do
    scope = CablePolicy::Scope.new(ApplicationPolicy::UserContext.new(@team_member, @project), Cable).resolve
    assert_includes scope, @cable
    refute_includes scope, @other_cable
  end
  
  test 'scope returns empty when no project is selected' do
    scope = CablePolicy::Scope.new(ApplicationPolicy::UserContext.new(@team_member, nil), Cable).resolve
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
    assert policy(@team_member, @project, @cable).show?
  end
  
  test 'show? denies viewing in other projects' do
    refute policy(@team_member, @project, @other_cable).show?
  end
  
  test 'show? denies when no project is selected' do
    refute policy(@team_member, nil, @cable).show?
  end

  # New Tests defer to create
  # Create Tests
  test 'create allows users with electrical designer role' do
    assert policy(@electrical_designer, @project, Cable.new).create?
  end

  test 'create denies users without electrical designer role' do
    refute policy(@regular_user, @project, Cable.new).create?
    refute policy(@team_member, @project, Cable.new).create?
    refute policy(nil, @project, Cable.new).create?
  end

  # Edit Tests defer to update
  # Update Tests
  test 'update allows users with electrical designer role' do
    assert policy(@electrical_designer, @project, @cable).update?
  end

  test 'update denies users without electrical designer role' do
    refute policy(@regular_user, @project, @cable).update?
    refute policy(@team_member, @project, @cable).update?
    refute policy(nil, @project, @cable).update?
  end

  # Destroy Tests
  # Uses default ApplicationPolicy behavior (admin and app_owner only)
  test 'destroy allows admin and app_owner' do
    assert policy(@admin, @project, @cable).destroy?
    assert policy(@app_owner, @project, @cable).destroy?
  end

  test 'destroy denies non-admin users' do
    
    # Electrical designers cannot destroy
    refute policy(@electrical_designer, @project, @cable).destroy?
    
    # Regular users cannot destroy
    refute policy(@regular_user, @project, @cable).destroy?
    
    # Project managers cannot destroy
    refute policy(@project_manager, @project, @cable).destroy?
    
    # Team members cannot destroy
    refute policy(@team_member, @project, @cable).destroy?
    
    # Unauthenticated users cannot destroy
    refute CablePolicy.new(nil, @cable).destroy?
  end
end
