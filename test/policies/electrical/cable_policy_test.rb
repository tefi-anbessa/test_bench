require 'test_helper'
require_relative '../../helpers/resource_policy_test'
module Electrical
  class CablePolicyTest < ActiveSupport::TestCase
    include ResourcePolicyTest
    def setup
      setup_resource_policy_test
    end
    def resource_class
      Electrical::Cable
    end

    def create_resource(tag:)
      # Use cable factory to create cable with tag association, using default prefix and unique serial.
      create(:electrical_cable, tag: tag)
    end

    def new_resource(discipline:)
      # Use cable factory to build new cable with tag association, using default prefix and unique serial.
      build(:electrical_cable, tag: create(:tag, discipline: discipline))
    end

    def self.required_role
      :electrical_designer
    end
  end
end