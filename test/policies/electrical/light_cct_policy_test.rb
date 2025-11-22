require 'test_helper'
require_relative '../../helpers/resource_policy_test'
module Electrical
  class LightCctPolicyTest < ActiveSupport::TestCase
    include ResourcePolicyTest
    def setup
      setup_resource_policy_test
    end
    def resource_class
      Electrical::LightCct
    end

    def create_resource(tag:)
      # Use light_cct factory to create light_cct with tag association, using default prefix and unique serial.
      create(:electrical_light_cct, tag: tag)
    end

    def new_resource(discipline:)
      # Use light_cct factory to build new light_cct with tag association, using default prefix and unique serial.
      build(:electrical_light_cct, tag: create(:tag, discipline: discipline))
    end

    def self.required_role
      :electrical_designer
    end
  end
end