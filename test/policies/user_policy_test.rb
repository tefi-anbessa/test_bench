require 'test_helper'
require_relative '../helpers/resource_policy_test'

class UserPolicyTest < ActiveSupport::TestCase
  include PolicyTestHelpers
  
  def setup
    setup_policy_test
  end
  
  # Helper to create policy with user and project context
  def policy(user, project, record = nil)
    user_context = ApplicationPolicy::UserContext.new(user, project)
    UserPolicy.new(user_context, record || User)
  end

  test "scope includes admins and users with project roles" do
    context = ApplicationPolicy::UserContext.new(@team_member, @project)
    scope = UserPolicy::Scope.new(context, User).resolve
    assert_includes scope, @project_manager
    assert_includes scope, @team_member
    assert_includes scope, @app_owner
    assert_includes scope, @admin
    refute_includes scope, @regular_user
  end

  test "index is not allowed when not signed in" do
    refute policy(nil, @project).index?
  end

  test "index is allowed when signed in" do
    assert policy(@admin, @project).index?
  end

  test "show is allowed for any user" do
    assert policy(@admin, @project).show?
  end
end
