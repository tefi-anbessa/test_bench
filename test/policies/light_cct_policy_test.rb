require 'test_helper'

class LightCctPolicyTest < ActiveSupport::TestCase
  include PolicyHelpers
  
  def setup
    setup_policy_test

    # Create electrical discipline
    @e = create(:discipline, :e)
    
    # Create a cable with a tag associated with the project
    @tag = create(:tag, :unique_tag, prefix: 'EL', discipline: @e, project: @project)
    @light_cct = create(:light_cct, tag: @tag)

    # Create a cable in another project
    @other_tag = create(:tag, :unique_tag, prefix: 'EL', discipline: @e, project: @other_project)
    @other_light_cct = create(:light_cct, tag: @other_tag)
    
    # Add electrical_designer role
    @electrical_designer = create(:user)
    @electrical_designer.grant(:team_member, @project)
    @electrical_designer.grant(:electrical_designer)
  end
  
  # Helper to create policy with user and project context
  def policy(user, project, record = nil)
    user_context = ApplicationPolicy::UserContext.new(user, project)
    LightCctPolicy.new(user_context, record || LightCct)
  end

  # Scope Tests
  test 'scope returns cables for current project' do
    scope = LightCctPolicy::Scope.new(ApplicationPolicy::UserContext.new(@team_member, @project), LightCct).resolve
    assert_includes scope, @light_cct
    refute_includes scope, @other_light_cct
  end
  
  test 'scope returns empty when no project is selected' do
    scope = LightCctPolicy::Scope.new(ApplicationPolicy::UserContext.new(@team_member, nil), LightCct).resolve
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
    assert policy(@team_member, @project, @light_cct).show?
  end
  
  test 'show? denies viewing in other projects' do
    refute policy(@team_member, @project, @other_light_cct).show?
  end
  
  test 'show? denies when no project is selected' do
    refute policy(@team_member, nil, @light_cct).show?
  end

  # New Tests defer to create
  # Create Tests
  test 'create allows users with electrical designer role' do
    assert policy(@electrical_designer, @project, LightCct.new).create?
  end

  test 'create denies users without electrical designer role' do
    refute policy(@regular_user, @project, LightCct.new).create?
    refute policy(@team_member, @project, LightCct.new).create?
    refute policy(nil, @project, LightCct.new).create?
  end

  # Update Tests
  test 'update allows users with electrical designer role' do
    assert policy(@electrical_designer, @project, @light_cct).update?
  end

  test 'update denies users without electrical designer role' do
    refute policy(@regular_user, @project, @light_cct).update?
    refute policy(@team_member, @project, @light_cct).update?
    refute policy(nil, @project, @light_cct).update?
  end

  # Destroy Tests
  # Uses default ApplicationPolicy behavior (admin and app_owner only)
  test 'destroy allows admin and app_owner' do
    assert policy(@admin, @project, @light_cct).destroy?
    assert policy(@app_owner, @project, @light_cct).destroy?
  end

  test 'destroy denies non-admin users' do
    
    # Electrical designers cannot destroy
    refute policy(@electrical_designer, @project, @light_cct).destroy?
    
    # Regular users cannot destroy
    refute policy(@regular_user, @project, @light_cct).destroy?
    
    # Project owners cannot destroy
    refute policy(@project_owner, @project, @light_cct).destroy?
    
    # Team members cannot destroy
    refute policy(@team_member, @project, @light_cct).destroy?
    
    # Unauthenticated users cannot destroy
    refute LightCctPolicy.new(nil, @light_cct).destroy?
  end
end
