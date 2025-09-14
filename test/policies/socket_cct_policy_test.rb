require 'test_helper'

class SocketCctPolicyTest < ActiveSupport::TestCase
  include PolicyHelpers
  
  def setup
    setup_policy_test

    # Create electrical discipline
    @e = create(:discipline, :e)
    
    # Create a socket circuit with a tag associated with the project
    @tag = create(:tag, :unique_tag, prefix: 'ES', discipline: @e, project: @project)
    @socket_cct = create(:socket_cct, tag: @tag)

    # Create a socket circuit in another project
    @other_tag = create(:tag, :unique_tag, prefix: 'ES', discipline: @e, project: @other_project)
    @other_socket_cct = create(:socket_cct, tag: @other_tag)
    
    # Add electrical_designer role
    @electrical_designer = create(:user)
    @electrical_designer.grant(:team_member, @project)
    @electrical_designer.grant(:electrical_designer)
  end
  
  # Helper to create policy with user and project context
  def policy(user, project, record = nil)
    user_context = ApplicationPolicy::UserContext.new(user, project)
    SocketCctPolicy.new(user_context, record || SocketCct)
  end

  # Scope Tests
  test 'scope returns cables for current project' do
    scope = SocketCctPolicy::Scope.new(ApplicationPolicy::UserContext.new(@team_member, @project), SocketCct).resolve
    assert_includes scope, @socket_cct
    refute_includes scope, @other_socket_cct
  end
  
  test 'scope returns empty when no project is selected' do
    scope = SocketCctPolicy::Scope.new(ApplicationPolicy::UserContext.new(@team_member, nil), SocketCct).resolve
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
    assert policy(@team_member, @project, @socket_cct).show?
  end
  
  test 'show? denies viewing in other projects' do
    refute policy(@team_member, @project, @other_socket_cct).show?
  end
  
  test 'show? denies when no project is selected' do
    refute policy(@team_member, nil, @socket_cct).show?
  end

  # New Tests defer to create
  # Create Tests
  test 'create allows users with electrical designer role' do
    assert policy(@electrical_designer, @project, SocketCct.new).create?
  end

  test 'create denies users without electrical designer role' do
    refute policy(@regular_user, @project, SocketCct.new).create?
    refute policy(@team_member, @project, SocketCct.new).create?
    refute policy(nil, @project, SocketCct.new).create?
  end

  # Update Tests
  test 'update allows users with electrical designer role' do
    assert policy(@electrical_designer, @project, @socket_cct).update?
  end

  test 'update denies users without electrical designer role' do
    refute policy(@regular_user, @project, @socket_cct).update?
    refute policy(@team_member, @project, @socket_cct).update?
    refute policy(nil, @project, @socket_cct).update?
  end

  # Destroy Tests
  # Uses default ApplicationPolicy behavior (admin and app_owner only)
  test 'destroy allows admin and app_owner' do
    assert policy(@admin, @project, @socket_cct).destroy?
    assert policy(@app_owner, @project, @socket_cct).destroy?
  end

  test 'destroy denies non-admin users' do
    
    # Electrical designers cannot destroy
    refute policy(@electrical_designer, @project, @socket_cct).destroy?
    
    # Regular users cannot destroy
    refute policy(@regular_user, @project, @socket_cct).destroy?
    
    # Project managers cannot destroy
    refute policy(@project_manager, @project, @socket_cct).destroy?
    
    # Team members cannot destroy
    refute policy(@team_member, @project, @socket_cct).destroy?
    
    # Unauthenticated users cannot destroy
    refute SocketCctPolicy.new(nil, @socket_cct).destroy?
  end
end
