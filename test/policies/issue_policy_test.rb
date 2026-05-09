# frozen_string_literal: true
require 'test_helper'
require 'helpers/test_setup_helpers'
require 'helpers/discipline_resource_policy_test'
class IssuePolicyTest < ActiveSupport::TestCase
  include TestSetupHelpers
  include DisciplineResourcePolicyTest

  setup do
    setup_projects_and_users
    setup_disciplines(name: "Electrical", required_role: :designer)
    @document = create(:document, discipline: @discipline)
    @resource = create(:issue, document: @document)
  end

  def new_resource(discipline)
    build(:issue, document: @document)
  end

  # All setup and tests have been abstracted to DisciplineResourcePolicyTest and TestSetupHelpers.
end