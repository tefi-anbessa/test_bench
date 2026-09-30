require 'test_helper'

require helpers/tagable_resource_policy_test
require 'helpers/resource_policy_test'
module Instrument
  class PressureGaugePolicyTest < ActiveSupport::TestCase

    include TagableResourcePolicyTest

    def setup
      setup_resource_policy_test
      @resource = create(:instrument_pressure_gauge, discipline: @discipline)
      @other_resource = create(:instrument_pressure_gauge, discipline: @other_discipline)
    end

    def new_project_resource
      build(:instrument_pressure_gauge, discipline: @discipline)
    end

    def new_other_project_resource
      build(:instrument_pressure_gauge, discipline: @other_discipline)
    end

    # All setup and tests have been abstracted to ResourcePolicyTest and PolicyTestHelpers.
  end
end
