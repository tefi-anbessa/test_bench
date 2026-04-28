# frozen_string_literal: true
require 'test_helper'
require 'helpers/test_setup_helpers'
require 'helpers/project_resource_policy_test'
module Electrical
  class CableTypePolicyTest < ActiveSupport::TestCase
    include TestSetupHelpers
    include ProjectResourcePolicyTest
    # Setup test data
    setup do 
      setup_projects_and_users
      setup_project_resources
      setup_disciplines(name: "Electrical", required_role: :designer)
      setup_accredited_users(:designer)
    end
  end
end