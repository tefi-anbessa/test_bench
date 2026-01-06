require 'test_helper'
require_relative '../../helpers/resource_policy_test'
module Electrical
  class HeaterPolicyTest < ActiveSupport::TestCase
    include ResourcePolicyTest

    def setup
      setup_resource_policy_test
    end

    # All setup and tests have been abstracted to ResourcePolicyTest and PolicyTestHelpers.
  end
end