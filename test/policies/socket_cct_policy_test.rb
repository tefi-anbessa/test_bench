require 'test_helper'

class SocketCctPolicyTest < ActiveSupport::TestCase
  include PolicyHelpers
  
  def setup
    setup_policy_test
    
    # Create a socket circuit with a tag associated with the project
    @socket_cct = create(:socket_cct)
    @tag = create(:tag, tagable: @socket_cct, project: @project)
    
    # Add electrical_designer role to project_owner and team_member
    @project_owner.add_role(:project_owner, @project)
    @project_owner.add_role(:electrical_designer)
    
    @team_member.add_role(:team_member, @project)
    @team_member.add_role(:electrical_designer)
    
    # Make sure the socket circuit is associated with the project through the tag
    @socket_cct.reload
  end

  # Scope Tests
  test 'scope for app owner shows all socket circuits' do
    scope = SocketCctPolicy::Scope.new(user_context(@app_owner), SocketCct).resolve
    assert_includes scope, @socket_cct
    assert_equal SocketCct.count, scope.count
  end

  test 'scope for admin shows all socket circuits' do
    scope = SocketCctPolicy::Scope.new(user_context(@admin), SocketCct).resolve
    assert_includes scope, @socket_cct
    assert_equal SocketCct.count, scope.count
  end

  test 'scope for project owner shows socket circuits in their project' do
    scope = SocketCctPolicy::Scope.new(user_context(@project_owner), SocketCct).resolve
    assert_includes scope, @socket_cct
    
    # Test that socket circuits in other projects are not included
    other_project = create(:project)
    other_socket_cct = create(:socket_cct)
    create(:tag, tagable: other_socket_cct, project: other_project)
    
    refute_includes scope, other_socket_cct
  end

  test 'scope for team member shows socket circuits in their project' do
    scope = SocketCctPolicy::Scope.new(user_context(@team_member), SocketCct).resolve
    assert_includes scope, @socket_cct
    
    # Test that socket circuits in other projects are not included
    other_project = create(:project)
    other_socket_cct = create(:socket_cct)
    create(:tag, tagable: other_socket_cct, project: other_project)
    
    refute_includes scope, other_socket_cct
  end

  test 'scope for regular user shows no socket circuits' do
    scope = SocketCctPolicy::Scope.new(user_context(@regular_user), SocketCct).resolve
    assert_empty scope
  end

  # Index Tests
  test 'index? allows any authenticated user' do
    assert SocketCctPolicy.new(user_context(@regular_user), SocketCct).index?
  end

  test 'index? denies unauthenticated users' do
    refute SocketCctPolicy.new(nil, SocketCct).index?
  end

  # Show Tests
  test 'show? allows users with project access' do
    assert SocketCctPolicy.new(user_context(@project_owner), @socket_cct).show?
    assert SocketCctPolicy.new(user_context(@team_member), @socket_cct).show?
  end

  test 'show? denies users without project access' do
    refute SocketCctPolicy.new(user_context(@regular_user), @socket_cct).show?
    refute SocketCctPolicy.new(user_context(nil), @socket_cct).show?
  end

  # Create Tests
  test 'create allows users with electrical designer role' do
    assert SocketCctPolicy.new(user_context(@project_owner), SocketCct.new).create?
    assert SocketCctPolicy.new(user_context(@team_member), SocketCct.new).create?
  end

  test 'create denies users without electrical designer role' do
    regular_user = create(:user)
    regular_user.add_role(:team_member, @project)  # Has project role but not electrical_designer
    
    refute SocketCctPolicy.new(user_context(regular_user), SocketCct.new).create?
    refute SocketCctPolicy.new(user_context(@regular_user), SocketCct.new).create?
    refute SocketCctPolicy.new(user_context(nil), SocketCct.new).create?
  end

  # Update Tests
  test 'update allows users with electrical designer role' do
    assert SocketCctPolicy.new(user_context(@project_owner), @socket_cct).update?
    assert SocketCctPolicy.new(user_context(@team_member), @socket_cct).update?
  end

  test 'update denies users without electrical designer role' do
    regular_user = create(:user)
    regular_user.add_role(:team_member, @project)  # Has project role but not electrical_designer
    
    refute SocketCctPolicy.new(user_context(regular_user), @socket_cct).update?
    refute SocketCctPolicy.new(user_context(@regular_user), @socket_cct).update?
    refute SocketCctPolicy.new(user_context(nil), @socket_cct).update?
  end

  # Destroy Tests
  test 'destroy allows admin and app_owner' do
    assert SocketCctPolicy.new(user_context(@admin), @socket_cct).destroy?
    assert SocketCctPolicy.new(user_context(@app_owner), @socket_cct).destroy?
  end

  test 'destroy denies non-admin users' do
    refute SocketCctPolicy.new(user_context(@project_owner), @socket_cct).destroy?
    refute SocketCctPolicy.new(user_context(@team_member), @socket_cct).destroy?
    refute SocketCctPolicy.new(user_context(@regular_user), @socket_cct).destroy?
    refute SocketCctPolicy.new(user_context(nil), @socket_cct).destroy?
  end
end
