require 'test_helper'
require 'helpers/test_setup_helpers'
require 'helpers/discipline_resource_policy_test'

class TagPolicyTest < ActiveSupport::TestCase
  include TestSetupHelpers
  include DisciplineResourcePolicyTest

  def setup
    setup_projects_and_users
    setup_disciplines(name: "Electrical", required_role: :designer)
    setup_discipline_resources # Choose discipline scoped resources for tags.
    setup_accredited_users(:designer)
  end
end
