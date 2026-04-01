require 'test_helper'
require 'helpers/test_login_helpers'

module ResourcePolicyTest
  extend ActiveSupport::Concern
  include TestLoginHelpers
  included do
    def setup_resource_policy_test
      # Set up projects and disciplines for in and out of current project scope tests,
      # and core users with roles
      setup_projects_and_users # In test/support/test_login_helpers.rb 

      # Inheriting classes must set up resources in and out of project scope for testing, i.e. 
      # @resource = create(:cable, tag: @tag)
      # @other_resource = create(:cable, tag: @other_tag)
    end

    def policy_class
      @policy_class ||= "#{resource_class}Policy".constantize
    end

    # Helper to be overridden by subclasses
    def resource_class
      self.class.to_s.sub('PolicyTest', '').constantize
    end

    # Helper to create policy with user and project context
    def policy(user, project, record = nil)
      user_context = ApplicationPolicy::UserContext.new(user, project)
      policy_class = "#{resource_class}Policy".constantize
      policy_class.new(user_context, record || resource_class)
    end

  def test_setup_is_valid
    if resource_class.respond_to?(:required_role)
      assert resource_class.required_role.present?
    end
    assert @project.valid?
    assert @project.persisted?
    assert @discipline.valid?
    assert @discipline.persisted?
    assert @admin.valid?
    assert @admin.persisted?
    assert @project_manager.valid?
    assert @project_manager.persisted?
    assert @team_member.valid?
    assert @team_member.persisted?
    assert @regular_user.valid?
    assert @regular_user.persisted?
    assert @accredited_team_member.valid?
    assert @accredited_team_member.persisted?
  end

  # Ensure that the including controller test creates valid in and out of scope resources
  def test_resource_setup_is_valid
    assert @resource.valid?
    assert @resource.persisted?
    assert @other_resource.valid?
    assert @other_resource.persisted?
  end

    # Scope Tests
    test 'scope for team_member returns only resources for current project' do
      context = ApplicationPolicy::UserContext.new(@team_member, @project)
      scope = policy_class::Scope.new(context, resource_class).resolve
      assert_includes scope, @resource
      refute_includes scope, @other_resource
    end

    test 'scope for admins returns resources for current project when current project selected' do
      context = ApplicationPolicy::UserContext.new(@admin, @project)
      scope = policy_class::Scope.new(context, resource_class).resolve
      assert_includes scope, @resource
      refute_includes scope, @other_resource
    end

    test 'scope for admins returns resources for all projects when current project is nil' do
      context = ApplicationPolicy::UserContext.new(@admin, nil)
      scope = policy_class::Scope.new(context, resource_class).resolve
      assert_includes scope, @resource
      assert_includes scope, @other_resource
    end

    test 'scope for users without project role returns empty scope' do
      context = ApplicationPolicy::UserContext.new(@accredited_user_other_project, @project)
      scope = policy_class::Scope.new(context, resource_class).resolve
      assert_empty scope
      context = ApplicationPolicy::UserContext.new(@regular_user, @project)
      scope = policy_class::Scope.new(context, resource_class).resolve
      assert_empty scope
      context = ApplicationPolicy::UserContext.new(@regular_user, nil)
      scope = policy_class::Scope.new(context, resource_class).resolve
      assert_empty scope
      context = ApplicationPolicy::UserContext.new(@nil, @project)
      scope = policy_class::Scope.new(context, resource_class).resolve
      assert_empty scope
    end

    # Index Tests
    test 'index? is available to admins and team members on current project' do
      assert policy(@admin, @project).index?
      assert policy(@app_owner, @project).index?
      assert policy(@project_manager, @project).index?
      assert policy(@team_member, @project).index?
      assert policy(@accredited_user, @project).index?
    end

    test 'index? is available to admins without current project' do
      assert policy(@admin, nil).index?
      assert policy(@app_owner, nil).index?
    end

    test 'index? denies team members when no project is selected' do
      refute policy(@project_manager, nil).index?
      refute policy(@team_member, nil).index?
      refute policy(@accredited_user, nil).index?
    end

    test 'index? is denied to user without a project role' do
      refute policy(@accredited_user_other_project, @project).index?
      refute policy(@regular_user, @project).index?
      refute policy(@regular_user, nil).index?
    end

    test 'index? is denied when user is not set' do
      refute policy(nil, @project).index?
      refute policy(nil, nil).index?
    end

    # Show Tests
    test 'show? allows admins and team members on current project to view resource on current project' do
      assert policy(@admin, @project, @resource).show?
      assert policy(@app_owner, @project, @resource).show?
      assert policy(@project_manager, @project, @resource).show?
      assert policy(@team_member, @project, @resource).show?
      assert policy(@accredited_user, @project, @resource).show?
    end

    test 'show? denies admins and team members on current project to view resource on different project' do
      refute policy(@project_manager, @project, @other_resource).show?
      refute policy(@team_member, @project, @other_resource).show?
      refute policy(@admin, @project, @other_resource).show?
      refute policy(@app_owner, @project, @other_resource).show?
    end

    test 'show? allows admins with nil current project to view any resource' do
      assert policy(@admin, nil, @resource).show?
      assert policy(@admin, nil, @other_resource).show?
    end
    
    test 'show? denies team members with nil current project to view any resource' do
      refute policy(@team_member, nil, @resource).show?
      refute policy(@team_member, nil, @other_resource).show?
      refute policy(@project_manager, nil, @resource).show?
      refute policy(@project_manager, nil, @other_resource).show?
      refute policy(@accredited_user, nil, @resource).show?
      refute policy(@accredited_user, nil, @other_resource).show?
    end

    test 'show denies users without project access' do
      refute policy(@accredited_user_other_project, @project, @resource).show?
      refute policy(@regular_user, @project, @resource).show?
      refute policy(@regular_user, @project, nil).show?
      refute policy(nil, @project, @resource).show?
    end

    # New tests defer to create
    # Create Tests
    test 'create allows admins and accredited team members to create resource on the current project' do
      assert policy(@admin, @project, new_project_resource).create?
      assert policy(@app_owner, @project, new_project_resource).create?
      assert policy(@accredited_user, @project, new_project_resource).create?
    end

    test "create denies any user without accreditation to create resource on current project" do
      refute policy(@project_manager, @project, new_project_resource).create?
      refute policy(@team_member, @project, new_project_resource).create?
      refute policy(@accredited_user_other_project, @project, new_project_resource).create?
      refute policy(@regular_user, @project, new_project_resource).create?
      refute policy(nil, @project, new_project_resource).create?
    end

    test 'create denies accredited users with nil current project to create resource on any project' do
      refute policy(@accredited_user, nil, new_project_resource).create?
      refute policy(@accredited_user, nil, new_other_project_resource).create?
    end

    test "create denies accredited user to create resource on other project" do
      refute policy(@accredited_user, @project, new_other_project_resource).create?
      refute policy(@admin, @project, new_other_project_resource).create?
      refute policy(@app_owner, @project, new_other_project_resource).create?
    end

    # Edit tests defer to update
    # Update Tests
    test 'update allows admins and accredited team members to update resource on the current project' do
      assert policy(@admin, @project, @resource).update?
      assert policy(@app_owner, @project, @resource).update?
      assert policy(@accredited_user, @project, @resource).update?
    end

    test 'update denies accredited users with nil current project to update resources on any project' do
      refute policy(@accredited_user, nil, @resource).update?
      refute policy(@accredited_user, nil, @other_resource).update?
    end

    test 'update denies users without accreditation and project role' do
      refute policy(@project_manager, @project, @resource).update?
      refute policy(@team_member, @project, @resource).update?
      refute policy(@regular_user, @project, @resource).update?
      refute policy(@accredited_user_other_project, @project, @resource).update?
      refute policy(nil, @project, @resource).update?
    end

    # Destroy Tests
    test 'destroy allows admin and app_owner' do
      assert policy(@admin, @project, @resource).destroy?
      assert policy(@app_owner, @project, @resource).destroy?
    end

    test 'destroy denies project manager, team members and regular users' do
      refute policy(@project_manager, @project, @resource).destroy?
      refute policy(@team_member, @project, @resource).destroy?
      refute policy(@regular_user, @project, @resource).destroy?
      refute policy(nil, @project, @resource).destroy?
    end
  end
end