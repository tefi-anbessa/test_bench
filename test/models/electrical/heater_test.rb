require "test_helper"
require_relative "../../helpers/tagable_model_patterns"
module Electrical
  class HeaterTest < ActiveSupport::TestCase
    include TagableModelPatterns

    def setup
      setup_common_test_data
      setup_model_specific_data
    end
    
    def setup_model_specific_data
      @resource = create(:electrical_heater, tag: @tag)
      # Insert model specific test setup here, including relationships with other models.
      # E.g. setup electrical_demand for electrical models.
    end

    test "model specific setup should be valid" do
      # Insert validity test of model specific test setup here, including relationships with other models.
      # E.g. electrical_demand for electrical models.
    end

    test "heater_type must be present" do
      @resource.heater_type = nil
      refute @resource.valid?
      assert_includes @resource.errors[:heater_type], I18n.t("errors.messages.blank")
    end
    test "application must be present" do
      @resource.application = nil
      refute @resource.valid?
      assert_includes @resource.errors[:application], I18n.t("errors.messages.blank")
    end

    test "destroy motor should destroy demand" do
      demand = @resource.electrical_demand
      assert_difference 'Electrical::Demand.count', -1 do
        @resource.destroy
      end
      assert_raises(ActiveRecord::RecordNotFound) { demand.reload }
    end
    
    test "should have electrical_demand through demandable concern" do
      assert_respond_to @resource, :electrical_demand
      assert @resource.electrical_demand.present?, 'Motor should have an electrical demand'
      assert_kind_of Electrical::Demand, @resource.electrical_demand
    end

  end
end