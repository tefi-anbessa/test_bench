require 'test_helper'
require_relative '../../helpers/tagable_policy_test'
module Electrical
  class HeaterPolicyTest < ActiveSupport::TestCase
    include TagablePolicyTest

    def setup
      setup_tagable_policy_test
    end

    # All setup and tests have been abstracted to ResourcePolicyTest and PolicyTestHelpers.
  end
end