require "test_helper"
require "helpers/test_setup_helpers"
module Instrument
  class PressureGaugeTest < ActiveSupport::TestCase
    include TestSetupHelpers

    def setup
      setup_common_test_data
      setup_model_specific_data
    end
    
    def setup_model_specific_data
      @resource = create(:instrument_pressure_gauge)
      # Insert model specific test setup here, including relationships with other models.
      # E.g. setup electrical_demand for electrical models.
    end

    test "measurement_type must be present" do
      @resource.measurement_type = nil
      refute @resource.valid?
      assert_includes @resource.errors[:measurement_type], I18n.t("errors.messages.blank")
    end
    test "range_min must be present" do
      @resource.range_min = nil
      refute @resource.valid?
      assert_includes @resource.errors[:range_min], I18n.t("errors.messages.blank")
    end
    test "range_max must be present" do
      @resource.range_max = nil
      refute @resource.valid?
      assert_includes @resource.errors[:range_max], I18n.t("errors.messages.blank")
    end

    # Insert model specific tests here.
    # E.g. test electrical_demand for electrical models.

  end
end