# frozen_string_literal: true

require 'test_helper'
require 'helpers/test_setup_helpers'
require 'helpers/project_resource_policy_test'
class DisciplinePolicyTest < ActiveSupport::TestCase
  include TestSetupHelpers
  include ProjectResourcePolicyTest

  setup do
    setup_projects_and_users
    setup_project_resources

    # Setup discipline policy specific requirements (alternate to test setup helpers)
    @accredited_user = create(:user)
    @accredited_user.grant(:project_admin, @project)
    @accredited_user_other_project = create(:user)
    @accredited_user_other_project.grant(:project_admin, @other_project)
  end

  # Override abstracted test for special case: accredited user is an admin and can create disciplines.
  # Line 195
  undef test_create_allows_admins_and_accredited_users_to_create_resource_on_the_current_project if method_defined?(:test_create_allows_admins_and_accredited_users_to_create_resource_on_the_current_project)
  test 'create allows admins and accredited users to create resource on the current project' do
    assert policy(@admin, @project, @new_resource).create?
    assert policy(@app_owner, @project, @new_resource).create?
    assert policy(@project_admin, @project, @new_resource).create?
    assert policy(@accredited_user, @project, @new_resource).create?
  end

  # Override abstracted test for special case: global admins actually can create disciplines on 
  # other projects. Line 217
  undef test_create_denies_accredited_user_to_create_resource_on_other_project if method_defined?(:test_create_denies_accredited_user_to_create_resource_on_other_project)
  test "create denies accredited user to create resource on other project" do
    refute policy(@accredited_user, @project, @new_other_resource).create?
    assert policy(@admin, @project, @new_other_resource).create?
    assert policy(@app_owner, @project, @new_other_resource).create?
  end

  # Accredited user is an admin in this case, so they can destroy
  undef test_destroy_denies_users_other_than_admins if method_defined?(:test_destroy_denies_users_other_than_admins)
  test 'destroy denies users other than admins' do
      refute policy(@project_manager, @project, @resource).destroy?
      assert policy(@accredited_user, @project, @resource).destroy?
      refute policy(@team_member, @project, @resource).destroy?
      refute policy(@regular_user, @project, @resource).destroy?
      refute policy(nil, @project, @resource).destroy?
    end
end

