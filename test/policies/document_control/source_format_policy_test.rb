require 'test_helper'
require 'helpers/test_setup_helpers'
module DocumentControl
  class SourceFormatPolicyTest < ActiveSupport::TestCase
    include TestSetupHelpers

    def setup
      setup_projects_and_users
      @resource = create(:document_control_source_format)
      @accredited_user = create(:user)
      @accredited_user.grant(:document_controller, @project)
      @accredited_user_other_project = create(:user)
      @accredited_user_other_project.grant(:document_controller, @other_project)
      @new_resource = build(:document_control_source_format)
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

    test "setup is valid" do
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
      assert @team_member_other_project.valid?
      assert @team_member_other_project.persisted?
      assert @regular_user.valid?
      assert @regular_user.persisted?
      assert @accredited_user.valid?
      assert @accredited_user.persisted?
      assert @new_resource.valid?
    end
    # Scope Tests
    test 'scope for team_member returns all resources' do
      context = ApplicationPolicy::UserContext.new(@team_member, @project)
      scope = policy_class::Scope.new(context, resource_class).resolve
      assert_includes scope, @resource
    end

    # Index Tests
    test 'index? is available to all users' do
      assert policy(@admin, @project).index?
      assert policy(@app_owner, @project).index?
      assert policy(@project_manager, @project).index?
      assert policy(@project_admin, @project).index?
      assert policy(@team_member, @project).index?
      assert policy(@accredited_user, @project).index?
      assert policy(@accredited_user_other_project, @project).index?
      assert policy(@regular_user, @project).index?
      assert policy(@regular_user, nil).index?
    end

    # Show Tests
    test 'show? allows all users' do
      assert policy(@admin, @project, @resource).show?
      assert policy(@app_owner, @project, @resource).show?
      assert policy(@project_manager, @project, @resource).show?
      assert policy(@project_admin, @project, @resource).show?
      assert policy(@team_member, @project, @resource).show?
      assert policy(@accredited_user, @project, @resource).show?
      assert policy(@accredited_user_other_project, @project).show?
      assert policy(@regular_user, @project).show?
      assert policy(@regular_user, nil).show?
    end

      # New tests
    test 'new allows admins and accredited users to access new form' do
      assert policy(@admin, @project, @new_resource).new?
      assert policy(@app_owner, @project, @new_resource).new?
      assert policy(@project_admin, @project, @new_resource).new?
      assert policy(@accredited_user, @project, @new_resource).new?
    end

    test 'new denies users without required role' do
      refute policy(@project_manager, @project, @new_resource).new?
      refute policy(@team_member, @project, @new_resource).new?
      refute policy(@regular_user, @project, @new_resource).new?
      refute policy(nil, @project, @new_resource).new?
    end

    # Create Tests
    test 'create allows admins and accredited users to create resource' do
      assert policy(@admin, @project, @new_resource).create?
      assert policy(@app_owner, @project, @new_resource).create?
      assert policy(@project_admin, @project, @new_resource).create?
      assert policy(@accredited_user, @project, @new_resource).create?
      assert policy(@accredited_user_other_project, @project, @new_resource).create?
    end

    test "create denies any user without accreditation to create resource" do
      refute policy(@project_manager, @project, @new_resource).create?
      refute policy(@team_member, @project, @new_resource).create?
      refute policy(@regular_user, @project, @new_resource).create?
      refute policy(nil, @project, @new_resource).create?
    end

    # Edit tests
    test 'edit allows admins and accredited users on current project to access edit form' do
      assert policy(@admin, @project, @resource).edit?
      assert policy(@app_owner, @project, @resource).edit?
      assert policy(@project_admin, @project, @resource).edit?
      assert policy(@accredited_user, @project, @resource).edit?
      assert policy(@accredited_user_other_project, @project, @resource).edit?
    end

    test 'edit denies users without required role' do
      refute policy(@project_manager, @project, @resource).edit?
      refute policy(@team_member, @project, @resource).edit?
      refute policy(@regular_user, @project, @resource).edit?
      refute policy(nil, @project, @resource).edit?
    end

    # Update Tests
    test 'update allows admins and accredited users to update resource' do
      assert policy(@admin, @project, @resource).update?
      assert policy(@app_owner, @project, @resource).update?
      assert policy(@project_admin, @project, @resource).update?
      assert policy(@accredited_user, @project, @resource).update?
      assert policy(@accredited_user_other_project, @project, @resource).update?
    end

    test 'update denies users without required role' do
      refute policy(@project_manager, @project, @resource).update?
      refute policy(@team_member, @project, @resource).update?
      refute policy(@regular_user, @project, @resource).update?
      refute policy(nil, @project, @resource).update?
    end

    # Destroy Tests
    test 'destroy allows global admins' do
      assert policy(@admin, @project, @resource).destroy?
      assert policy(@app_owner, @project, @resource).destroy?
    end

    test 'destroy denies users other than global admins' do
      refute policy(@project_admin, @project, @resource).destroy?
      refute policy(@project_manager, @project, @resource).destroy?
      refute policy(@accredited_user, @project, @resource).destroy?
      refute policy(@team_member, @project, @resource).destroy?
      refute policy(@regular_user, @project, @resource).destroy?
      refute policy(nil, @project, @resource).destroy?
    end
  end
end
