require 'test_helper'
require_relative '../../helpers/resource_policy_test'
module Electrical

  class SwitchboardPolicyTest < ActiveSupport::TestCase
    include ResourcePolicyTest
    def setup
      setup_resource_policy_test
    end

    def resource_class
      Electrical::Switchboard
    end

    def create_resource(tag:)
      # Use switchboard factory to create switchboard with tag association, using default prefix and unique serial.
      create(:electrical_switchboard, tag: tag)
    end

    def new_resource(discipline:)
      # Use switchboard factory to build new switchboard with tag association, using default prefix and unique serial.
      build(:electrical_switchboard, tag: create(:tag, discipline: discipline))
    end
  end
end