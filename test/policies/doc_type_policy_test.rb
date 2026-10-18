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
    # Index Tests - doc type override. Index is only available to admins
    # and accredited users, and project-wide vs discipline-scoped access
    # are gated separately (see DocTypePolicy#index?) - called with the
    # actual Discipline/Project being indexed, not the bare class.
    test 'index on a discipline is available to a document_controller scoped to that discipline, or to admins' do
      assert policy(@admin, @project, @discipline).index?
      assert policy(@app_owner, @project, @discipline).index?
      assert policy(@project_admin, @project, @discipline).index?
      assert policy(@accredited_user, @project, @discipline).index?
      refute policy(@project_manager, @project, @discipline).index?
      refute policy(@team_member, @project, @discipline).index?
    end

    test 'index on a discipline is also available to a document_controller scoped to the whole project' do
      @accredited_user.grant(:document_controller, @project)
      assert policy(@accredited_user, @project, @discipline).index?
    end

    test 'index on the project requires a project-scoped document_controller - a discipline-scoped grant is not enough' do
      assert policy(@admin, @project, @project).index?
      assert policy(@app_owner, @project, @project).index?
      assert policy(@project_admin, @project, @project).index?
      refute policy(@accredited_user, @project, @project).index?
      refute policy(@project_manager, @project, @project).index?
      refute policy(@team_member, @project, @project).index?
    end

    test 'index on the project is available to a document_controller scoped to the whole project' do
      @accredited_user.grant(:document_controller, @project)
      assert policy(@accredited_user, @project, @project).index?
    end

    test 'index is denied when called with the bare class - every caller must supply the actual discipline or project' do
      refute policy(@admin, @project).index?
      refute policy(@accredited_user, @project).index?
    end
end
