require 'test_helper'

class LightCctPolicyTest < ActiveSupport::TestCase
  include PolicyHelpers
  
  def setup
    setup_policy_test
    
    # Create a light circuit with a tag associated with the project
    @light_cct = create(:light_cct)
    @tag = create(:tag, tagable: @light_cct, project: @project)
    
    # Add electrical_designer role to project_owner and team_member
    @project_owner.add_role(:project_owner, @project)
    @project_owner.add_role(:electrical_designer)
    
    @team_member.add_role(:team_member, @project)
    @team_member.add_role(:electrical_designer)
    
    # Make sure the light circuit is associated with the project through the tag
    @light_cct.reload
  end

  # Scope Tests
  test 'scope for app owner shows all light circuits' do
    scope = LightCctPolicy::Scope.new(user_context(@app_owner), LightCct).resolve
    assert_includes scope, @light_cct
    assert_equal LightCct.count, scope.count
  end

  test 'scope for admin shows all light circuits' do
    scope = LightCctPolicy::Scope.new(user_context(@admin), LightCct).resolve
    assert_includes scope, @light_cct
    assert_equal LightCct.count, scope.count
  end

  test 'scope for project owner shows light circuits in their project' do
    scope = LightCctPolicy::Scope.new(user_context(@project_owner), LightCct).resolve
    assert_includes scope, @light_cct
    
    # Test that light circuits in other projects are not included
    other_project = create(:project)
    other_light_cct = create(:light_cct)
    create(:tag, tagable: other_light_cct, project: other_project)
    
    refute_includes scope, other_light_cct
  end

  test 'scope for team member shows light circuits in their project' do
    scope = LightCctPolicy::Scope.new(user_context(@team_member), LightCct).resolve
    assert_includes scope, @light_cct
    
    # Test that light circuits in other projects are not included
    other_project = create(:project)
    other_light_cct = create(:light_cct)
    create(:tag, tagable: other_light_cct, project: other_project)
    
    refute_includes scope, other_light_cct
  end

  test 'scope for regular user shows no light circuits' do
    scope = LightCctPolicy::Scope.new(user_context(@regular_user), LightCct).resolve
    assert_empty scope
  end

  # Index Tests
  test 'index? allows any authenticated user' do
    assert LightCctPolicy.new(user_context(@regular_user), LightCct).index?
  end

  test 'index? denies unauthenticated users' do
    refute LightCctPolicy.new(nil, LightCct).index?
  end

  # Show Tests
  test 'show? allows users with project access' do
    assert LightCctPolicy.new(user_context(@project_owner), @light_cct).show?
    assert LightCctPolicy.new(user_context(@team_member), @light_cct).show?
  end

  test 'show? denies users without project access' do
    refute LightCctPolicy.new(user_context(@regular_user), @light_cct).show?
    refute LightCctPolicy.new(user_context(nil), @light_cct).show?
  end

  # Create Tests
  test 'create allows users with electrical designer role' do
    assert LightCctPolicy.new(user_context(@project_owner), LightCct.new).create?
    assert LightCctPolicy.new(user_context(@team_member), LightCct.new).create?
  end

  test 'create denies users without electrical designer role' do
    regular_user = create(:user)
    regular_user.add_role(:team_member, @project)  # Has project role but not electrical_designer
    
    refute LightCctPolicy.new(user_context(regular_user), LightCct.new).create?
    refute LightCctPolicy.new(user_context(@regular_user), LightCct.new).create?
    refute LightCctPolicy.new(user_context(nil), LightCct.new).create?
  end

  # Update Tests
  test 'update allows users with electrical designer role' do
    assert LightCctPolicy.new(user_context(@project_owner), @light_cct).update?
    assert LightCctPolicy.new(user_context(@team_member), @light_cct).update?
  end

  test 'update denies users without electrical designer role' do
    regular_user = create(:user)
    regular_user.add_role(:team_member, @project)  # Has project role but not electrical_designer
    
    refute LightCctPolicy.new(user_context(regular_user), @light_cct).update?
    refute LightCctPolicy.new(user_context(@regular_user), @light_cct).update?
    refute LightCctPolicy.new(user_context(nil), @light_cct).update?
  end

  # Destroy Tests
  test 'destroy allows admin and app_owner' do
    assert LightCctPolicy.new(user_context(@admin), @light_cct).destroy?
    assert LightCctPolicy.new(user_context(@app_owner), @light_cct).destroy?
  end

  test 'destroy denies non-admin users' do
    refute LightCctPolicy.new(user_context(@project_owner), @light_cct).destroy?
    refute LightCctPolicy.new(user_context(@team_member), @light_cct).destroy?
    refute LightCctPolicy.new(user_context(@regular_user), @light_cct).destroy?
    refute LightCctPolicy.new(user_context(nil), @light_cct).destroy?
  end
end
