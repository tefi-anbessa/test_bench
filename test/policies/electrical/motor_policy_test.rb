require 'test_helper'
require_relative '../../helpers/resource_policy_test'
module Electrical

  class MotorPolicyTest < ActiveSupport::TestCase
    include ResourcePolicyTest
    def setup
      setup_resource_policy_test
    end
    def resource_class
      Electrical::Motor
    end

    def create_resource(tag:)
      # Use motor factory to create motor with tag association, using default prefix and unique serial.
      create(:electrical_motor, tag: tag)
    end

    def new_resource(discipline:)
      # Use motor factory to build new motor with tag association, using default prefix and unique serial.
      build(:electrical_motor, tag: create(:tag, discipline: discipline))
    end
  end
end