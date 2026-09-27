# frozen_string_literal: true
# Mix in for project-scoped resource policy tests.
require 'test_helper'
require 'helpers/test_setup_helpers'

module TagablePolicyTest
  extend ActiveSupport::Concern
  include TestSetupHelpers
  included do

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
    
    def setup_tagable_policy_test
      # Set up projects and disciplines for in and out of current project scope tests,
      # and core users with roles
      setup_projects_and_users # In test/helpers/test_setup_helpers.rb
      # Setup in and out of scope disciplines.
      # Defaults to "Electrical" with required role "designer"
      setup_disciplines
      # Set up accredited users for electrical disciplines in each project
      setup_accredited_users(:designer)
      # Set up tags in and out of scope for testing
      setup_tags
      # Set up resource associated with each tag
      setup_tagable_resources
    end

    test "project and user setup is valid" do
      assert @project.valid?
      assert @project.persisted?
      assert @admin.valid?
      assert @admin.persisted?
      assert @project_manager.valid?
      assert @project_manager.persisted?
      assert @project_admin.valid?
      assert @project_admin.persisted?
      assert @team_member.valid?
      assert @team_member.persisted?
      assert @regular_user.valid?
      assert @regular_user.persisted?
    end

    test "discipline setup is valid" do
      assert @discipline.valid?
      assert @discipline.persisted?
      assert_equal @discipline.required_role.to_sym, :designer
      assert @other_discipline.valid?
      assert @other_discipline.persisted?
      assert_equal @other_discipline.required_role.to_sym, :designer
    end

    test "accredited user setup is valid" do
      assert @accredited_user.valid?
      assert @accredited_user.persisted?
      assert @accredited_user.has_role?(:designer, @discipline)
      assert @accredited_user_other_project.valid?
      assert @accredited_user_other_project.persisted?
      assert @accredited_user_other_project.has_role?(:designer, @other_discipline)
    end

    # Ensure that the including controller test creates valid in and out of scope resources
    test "resource setup is valid" do
      assert @tag.valid?
      assert @tag.persisted?
      assert @other_tag.valid?
      assert @other_tag.persisted?
      assert @resource.valid?
      assert @resource.persisted?
      assert @other_resource.valid?
      assert @other_resource.persisted?
      assert_equal @tag.tagable, @resource
      assert_equal @other_tag.tagable, @other_resource
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
      assert policy(@project_admin, @project).index?
      assert policy(@team_member, @project).index?
      assert policy(@accredited_user, @project).index?
    end

    test 'index? is available to global admins without current project' do
      assert policy(@admin, nil).index?
      assert policy(@app_owner, nil).index?
    end

    test 'index? denies team members when no project is selected' do
      refute policy(@project_manager, nil).index?
      refute policy(@project_admin, nil).index?
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
      assert policy(@project_admin, @project, @resource).show?
      assert policy(@team_member, @project, @resource).show?
      assert policy(@accredited_user, @project, @resource).show?
    end

    test 'show? denies admins and team members on current project to view resource on different project' do
      refute policy(@project_manager, @project, @other_resource).show?
      refute policy(@project_admin, @project, @other_resource).show?
      refute policy(@team_member, @project, @other_resource).show?
      refute policy(@admin, @project, @other_resource).show?
      refute policy(@app_owner, @project, @other_resource).show?
    end

    test 'show? allows global admins with nil current project to view any resource' do
      assert policy(@admin, nil, @resource).show?
      assert policy(@admin, nil, @other_resource).show?
    end
    
    test 'show? denies team members with nil current project to view any resource' do
      refute policy(@team_member, nil, @resource).show?
      refute policy(@team_member, nil, @other_resource).show?
      refute policy(@project_manager, nil, @resource).show?
      refute policy(@project_manager, nil, @other_resource).show?
      refute policy(@project_admin, nil, @resource).show?
      refute policy(@project_admin, nil, @other_resource).show?
      refute policy(@accredited_user, nil, @resource).show?
      refute policy(@accredited_user, nil, @other_resource).show?
    end

    test 'show denies users without project access' do
      refute policy(@accredited_user_other_project, @project, @resource).show?
      refute policy(@regular_user, @project, @resource).show?
      refute policy(@regular_user, @project, nil).show?
      refute policy(nil, @project, @resource).show?
    end

    # new?/create?/edit?/update?/destroy? are deliberately not tested here -
    # TagablePolicy no longer defines them. TagablesController's own
    # create/new/edit/update/destroy actions authorize @tag, not the
    # tagable, so the real authorization for all of those is TagPolicy's
    # (via @discipline.tags.build/@tagable.tag) - already covered by
    # TagPolicy's own test suite and by test/helpers/tagable_controller_tests.rb,
    # which drives real requests through that actual path. See
    # app/policies/tagable_policy.rb's own comment for the full reasoning.
  end
end