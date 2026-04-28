require 'test_helper'
require 'helpers/test_setup_helpers'
require 'helpers/discipline_resource_policy_test'

  class DocumentPolicyTest < ActiveSupport::TestCase
  include TestSetupHelpers
  include DisciplineResourcePolicyTest

    def setup
      setup_projects_and_users
      setup_disciplines(name: "Electrical", required_role: :designer)
      setup_discipline_resources # Choose discipline scoped resources for documents.
      setup_accredited_users(:designer)
    end

    # All setup and tests have been abstracted to DisciplineResourcePolicyTest and TestSetupHelpers.
  end
