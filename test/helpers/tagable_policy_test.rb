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
      # Set up an alternate discipline in the same project for testing new action
      @alternate_discipline = create(:discipline, project: @project, name: "Test", 
      swatch: @swatch, required_role: :designer)
      @alternate_accredited_user = create(:user)
      @alternate_accredited_user.grant(:designer, @alternate_discipline)
    end

    # Helper to build resource with tag association for tagable models.
    # Other models need to implement their own new_resource method.
    def new_resource(discipline)
      build(resource_class.model_name.param_key, tag: build(:tag, :unique_tag, discipline: discipline))
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

    # New tests 
    test 'new allows accredited user to access the form' do
      assert policy(@admin, @project, nil).new?
      assert policy(@app_owner, @project, nil).new?
      assert policy(@project_admin, @project, nil).new?
      assert policy(@accredited_user, @project, nil).new?
      assert policy(@alternate_accredited_user, @project, nil).new?
    end

    test 'new denies users with nil current project to access the form' do
      refute policy(@admin, nil, nil).new?
      refute policy(@app_owner, nil, nil).new?
      refute policy(@accredited_user, nil, nil).new?
    end

    test "new denies any user without accreditation to access the form" do
      refute policy(@project_manager, @project, nil).new?
      refute policy(@team_member, @project, nil).new?
      refute policy(@accredited_user_other_project, @project, nil).new?
      refute policy(@regular_user, @project, nil).new?
      refute policy(nil, @project, nil).new?
    end
  
    # Create Tests
    test 'create allows admins and accredited team members to create resource on the current project' do
      assert policy(@admin, @project, new_resource(@discipline)).create?
      assert policy(@app_owner, @project, new_resource(@discipline)).create?
      assert policy(@project_admin, @project, new_resource(@discipline)).create?
      assert policy(@accredited_user, @project, new_resource(@discipline)).create?
      assert policy(@alternate_accredited_user, @project, new_resource(@alternate_discipline)).create?
    end

    test 'create denies users with nil current project to create resource on any project' do
      refute policy(@admin, nil, new_resource(@discipline)).create?
      refute policy(@app_owner, nil, new_resource(@discipline)).create?
      refute policy(@admin, nil, new_resource(@other_discipline)).create?
      refute policy(@app_owner, nil, new_resource(@other_discipline)).create?
      refute policy(@accredited_user, nil, new_resource(@discipline)).create?
      refute policy(@accredited_user, nil, new_resource(@other_discipline)).create?
    end

    test "create denies any user without accreditation to create resource on current project" do
      refute policy(@project_manager, @project, new_resource(@discipline)).create?
      refute policy(@team_member, @project, new_resource(@discipline)).create?
      refute policy(@accredited_user_other_project, @project, new_resource(@discipline)).create?
      refute policy(@regular_user, @project, new_resource(@discipline)).create?
      refute policy(nil, @project, new_resource(@discipline)).create?
    end

    # Edit tests
    test 'edit allows accredited users to access the form on the current project' do
      assert policy(@admin, @project, @resource).edit?
      assert policy(@app_owner, @project, @resource).edit?
      assert policy(@project_admin, @project, @resource).edit?
      assert policy(@accredited_user, @project, @resource).edit?
    end

    test 'edit denies any users without current project set to access the form' do
      refute policy(@admin, nil, @resource).edit?
      refute policy(@app_owner, nil, @resource).edit?
      refute policy(@accredited_user, nil, @resource).edit?
    end

    test 'edit denies any users without accreditation to access the form' do
      refute policy(@project_manager, @project, @resource).edit?
      refute policy(@team_member, @project, @resource).edit?
      refute policy(@accredited_user_other_project, @project, @resource).edit?
      refute policy(@regular_user, @project, @resource).edit?
      refute policy(nil, @project, @resource).edit?
    end

    # Update Tests
    test 'update allows admins and accredited team members to update resource on the current project' do
      assert policy(@admin, @project, @resource).update?
      assert policy(@app_owner, @project, @resource).update?
      assert policy(@project_admin, @project, @resource).update?
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

    test 'update denies any users with nil current project to update resources on any project' do
      refute policy(@admin, nil, @resource).update?
      refute policy(@app_owner, nil, @resource).update?
      refute policy(@accredited_user, nil, @resource).update?
      refute policy(@admin, nil, @other_resource).update?
      refute policy(@app_owner, nil, @other_resource).update?
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
      assert policy(@project_admin, @project, @resource).destroy?
    end

    test 'destroy denies project manager, team members and regular users' do
      refute policy(@project_manager, @project, @resource).destroy?
      refute policy(@team_member, @project, @resource).destroy?
      refute policy(@regular_user, @project, @resource).destroy?
      refute policy(nil, @project, @resource).destroy?
    end
  end
end