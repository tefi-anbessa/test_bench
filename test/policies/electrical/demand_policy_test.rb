require 'test_helper'
require_relative '../../helpers/resource_policy_test'
module Electrical
  class DemandPolicyTest < ActiveSupport::TestCase
    include ResourcePolicyTest
    def setup
      setup_resource_policy_test
    end

    def resource_class
      Electrical::Demand
    end

    def create_resource(tag:)
      # Uses demand factory to create demand with tag association, using default prefix and unique serial.
      create(:electrical_demand, demandable: create(:electrical_motor, tag: tag))
    end

    def new_resource(discipline:)
      # Uses demand factory to build new demand with tag association, using default prefix and unique serial.
      build(:electrical_demand, demandable: create(:electrical_motor, tag: create(:tag, discipline: discipline)))
    end

    def self.required_role
      :electrical_designer
    end
  end
end