require 'test_helper'
# test/support/_resource_policy_test.rb
# return if self.class == ResourcePolicyTest
require_relative 'policy_test_helpers'

module ResourcePolicyTest
  extend ActiveSupport::Concern
  include PolicyTestHelpers
  included do
    def setup_resource_policy_test
      # Set up projects and disciplines for in and out of current project scope tests,
      # and core users with roles
      setup_policy_test # In test/support/policy_test_helpers.rb 
      
      # Accredited users for electrical models
      @accredited_user = create(:user)
      @accredited_user.grant(:team_member, @project)
      @accredited_user.grant(resource_class.required_role)
      @accredited_user_other_project = create(:user)
      @accredited_user_other_project.grant(:team_member, @other_project)
      @accredited_user_other_project.grant(resource_class.required_role)

      # Set up tags in and out of scope for testing
      @tag = create(:tag, discipline: @discipline)
      @other_tag = create(:tag, :unique_tag, discipline: @other_discipline)

      # Inheriting classes must set up resources in and out of scope for testing, e.g.:
      # @resource = create(:cable, tag: @tag)
      # @other_resource = create(:cable, tag: @other_tag)
      @resource = create_resource(tag: @tag)
      @other_resource = create_resource(tag: @other_tag)
    end

    def policy_class
      @policy_class ||= "#{resource_class}Policy".constantize
    end

    # Helper to be overridden by subclasses
    def resource_class
      self.class.to_s.sub('PolicyTest', '').constantize
    end

    # Helper to create resource with tag association for tagable models.
    # Other models need to implement their own create_resource method.
    def create_resource(tag: @tag, **attributes)
      create(resource_class.model_name.param_key, tag: tag, **attributes)
    end

    # Helper to build resource with tag association for tagable models.
    # Other models need to implement their own new_resource method.
    def new_resource(discipline:)
      build(resource_class.model_name.param_key, tag: create(:tag, discipline: discipline))
    end

    # Helper to create policy with user and project context
    def policy(user, project, record = nil)
      user_context = ApplicationPolicy::UserContext.new(user, project)
      policy_class = "#{resource_class}Policy".constantize
      policy_class.new(user_context, record || resource_class)
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
      assert policy(@admin, @project, new_resource(discipline: @discipline)).create?
      assert policy(@app_owner, @project, new_resource(discipline: @discipline)).create?
      assert policy(@accredited_user, @project, new_resource(discipline: @discipline)).create?
    end

    test 'create allows admins with nil current project to create resource on any project' do
      assert policy(@admin, nil, new_resource(discipline: @discipline)).create?
      assert policy(@app_owner, nil, new_resource(discipline: @discipline)).create?
      assert policy(@admin, nil, new_resource(discipline: @other_discipline)).create?
      assert policy(@app_owner, nil, new_resource(discipline: @other_discipline)).create?
    end

    test "create denies any user without accreditation to create resource on current project" do
      refute policy(@project_manager, @project, new_resource(discipline: @discipline)).create?
      refute policy(@team_member, @project, new_resource(discipline: @discipline)).create?
      refute policy(@accredited_user_other_project, @project, new_resource(discipline: @discipline)).create?
      refute policy(@regular_user, @project, new_resource(discipline: @discipline)).create?
      refute policy(nil, @project, new_resource(discipline: @discipline)).create?
    end

    test 'create denies accredited users with nil current project to create resource on any project' do
      refute policy(@accredited_user, nil, new_resource(discipline: @discipline)).create?
      refute policy(@accredited_user, nil, new_resource(discipline: @other_discipline)).create?
    end

    test "create denies accredited user to create resource on other project" do
      unless Tag.tagable_types.include?(resource_class.name) 
      # Tagable types can create tag and resource in the same action, but pundit does not have access to
      # the project association of the associated tag when creating a resource. 
      # Authorise the tag in the same controller action to assure that resources aren't being created 
      # in another project. 
      # Other resources which can access their parent tag at create time can be tested.
        refute policy(@accredited_user, @project, new_resource(discipline: @other_discipline)).create?
        refute policy(@admin, @project, new_resource(discipline: @other_discipline)).create?
        refute policy(@app_owner, @project, new_resource(discipline: @other_discipline)).create?
      end
      assert true # dummy assertion to avoid warning message
    end

    # Edit tests defer to update
    # Update Tests
    test 'update allows admins and accredited team members to update resource on the current project' do
      assert policy(@admin, @project, @resource).update?
      assert policy(@app_owner, @project, @resource).update?
      assert policy(@accredited_user, @project, @resource).update?
    end

# This test is a placeholder in case we figure out how to authorize resources directly.
    test 'update denies accredited users on current project to update resource on different project' do
      unless Tag.tagable_types.include?(resource_class.name) 
      # Tagable types can create a new tag as part of the resource update action,
      # this allows rescue of orphaned resources. Pundit does not have access to the project association
      # of the new tag when updating a resource. Authorise the tag in the same controller action to
      # assure that resources aren't being updated in another project.
      # Other resources which can access their parent tag at update time can be tested.
        refute policy(@admin, @project, @other_resource).update?
        refute policy(@app_owner, @project, @other_resource).update?
        refute policy(@accredited_user, @project, @other_resource).update?
      end
      assert true # dummy assertion to avoid warning message
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