# frozen_string_literal: true
require 'test_helper'
require 'helpers/test_setup_helpers'
require 'helpers/discipline_resource_policy_test'

class DocTypePolicyTest < ActiveSupport::TestCase
  include TestSetupHelpers
  include DisciplineResourcePolicyTest

  setup do
    setup_projects_and_users
    setup_disciplines(name: "Electrical", required_role: :designer)
    setup_discipline_resources
    setup_accredited_users(:document_controller)
  end
  undef :test_index_is_available_to_admins_and_team_members_on_current_project
    # Index Tests - doc type override. Index is only available to admins and accredited users.
    test 'index is available to admins and team members on current project' do
      @accredited_user.grant(:document_controller, @project)
      assert policy(@admin, @project).index?
      assert policy(@app_owner, @project).index?
      refute policy(@project_manager, @project).index?
      assert policy(@project_admin, @project).index?
      refute policy(@team_member, @project).index?
      assert policy(@accredited_user, @project).index?
    end
end
