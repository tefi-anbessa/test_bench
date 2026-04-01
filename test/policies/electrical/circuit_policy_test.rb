require 'test_helper'
require_relative '../../helpers/tagable_policy_test'
module Electrical
  class CircuitPolicyTest < ActiveSupport::TestCase
    include TagablePolicyTest
    def setup
      setup_tagable_policy_test
    end

    def create_resource(tag:)
      # Use circuit factory to create circuit with tag association, using default prefix and unique serial.
      create(:electrical_circuit, electrical_switchboard: create(:electrical_switchboard, tag: tag))
    end

    def new_resource(discipline:)
      # Use circuit factory to build new circuit belonging to switchboard with tag association, using default prefix and unique serial.
      build(:electrical_circuit, electrical_switchboard: create(:electrical_switchboard, tag: create(:tag, discipline: discipline)))
    end

    # All remaining setup and tests have been abstracted to TagablePolicyTest and PolicyTestHelpers.
  end
end