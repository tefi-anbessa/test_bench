# frozen_string_literal: true
require 'test_helper'
require 'helpers/test_setup_helpers'
require 'helpers/project_resource_policy_test'
module ProjectChange
  class RequestPolicyTest < ActiveSupport::TestCase
    include TestSetupHelpers
    include ProjectResourcePolicyTest

    setup do
      setup_projects_and_users
      setup_project_resources
      # Any team member can raise requests
      @accredited_user = @team_member
      @accredited_user_other_project = @team_member_other_project
    end

    # Overwrite tests expecting team member to have no permissions
    undef :test_new_denies_users_without_required_role_on_current_project_to_access_new_form
    test 'new denies users without required role on current project to access new form' do
      assert policy(@team_member, @project, resource_class).new?
    end

    undef :test_create_denies_any_user_without_accreditation_to_create_resource_on_current_project
    test "create denies any user without accreditation to create resource on current project" do
      assert policy(@team_member, @project, @new_resource).create?
      refute policy(@accredited_user_other_project, @project, @new_resource).create?
      refute policy(@regular_user, @project, @new_resource).create?
      refute policy(nil, @project, @new_resource).create?
    end

    undef :test_edit_denies_users_without_required_project_role
    test 'edit denies users without required project role' do
      assert policy(@team_member, @project, @resource).edit?
      refute policy(@regular_user, @project, @resource).edit?
      refute policy(nil, @project, @resource).edit?
    end

    undef :test_update_denies_users_without_accreditation_and_project_role
    test 'update denies users without accreditation and project role' do
      assert policy(@team_member, @project, @resource).update?
      refute policy(@regular_user, @project, @resource).update?
      refute policy(@accredited_user_other_project, @project, @resource).update?
      refute policy(nil, @project, @resource).update?
    end
  end
end
