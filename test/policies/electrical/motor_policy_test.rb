require 'test_helper'
require 'helpers/tagable_policy_test'
module Electrical
  class MotorPolicyTest < ActiveSupport::TestCase
    include TagablePolicyTest

    def setup
      setup_tagable_policy_test
    end

    # All setup and tests have been abstracted to TagablePolicyTest and TestSetupHelpers.
  end
end