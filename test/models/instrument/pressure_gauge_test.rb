require "test_helper"
require 'helpers/tagable_model_tests'
module Instrument
  class PressureGaugeTest < ActiveSupport::TestCase
    include TagableModelTests

    def setup
      setup_common_test_data
      setup_model_specific_data
    end

    def setup_model_specific_data
      # @resource and its tag are already created by setup_common_test_data.
      # Insert model specific test setup here, including relationships with other models.
      # E.g. setup electrical_demand for electrical models.
    end

    test_required_fields(:measurement_type, :range_min, :range_max)
    test_enum_field(:measurement_type, prefix: true)
    test_enum_field(:pressure_unit, prefix: true)
    test_enum_field(:fluid_phase, prefix: true)
    test_enum_field(:process_fluid, prefix: true)
    test_enum_field(:accuracy_class, prefix: true)
    test_enum_field(:dial_size, prefix: true)
    test_enum_field(:connection_type, prefix: true)
    test_enum_field(:connection_size, prefix: true)
    test_enum_field(:case_material, prefix: true)
    test_enum_field(:wetted_material, prefix: true)
    test_enum_field(:movement_type, prefix: true)
    test_enum_field(:fill_fluid, prefix: true)
    test_enum_translations(:measurement_type, :pressure_unit, :fluid_phase, :process_fluid, :accuracy_class,
      :dial_size, :connection_type, :connection_size, :case_material, :wetted_material, :movement_type, :fill_fluid)

    # Insert model specific tests here.
    # E.g. test electrical_demand for electrical models.

  end
end
