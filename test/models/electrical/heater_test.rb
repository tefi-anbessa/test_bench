# frozen_string_literal: true

require "test_helper"
require 'helpers/tagable_model_tests'

module Electrical
  class HeaterTest < ActiveSupport::TestCase
    include TagableModelTests

    def setup
      setup_common_test_data
      @resource.electrical_demand = create(:electrical_demand, demandable: @resource)
    end

    test_required_fields(:heater_type, :application)
    test_enum_field(:heater_type)
    test_enum_field(:application)
    test_enum_field(:sheath_material, prefix: true)
    test_enum_field(:insulation_material, prefix: true)
    test_enum_translations(:heater_type, :application, :sheath_material, :insulation_material)
  end
end
