require "test_helper"
require_relative "../../helpers/tagable_model_patterns"
module Electrical
  class MotorTest < ActiveSupport::TestCase
    include TagableModelPatterns
    
    def setup
      setup_common_test_data
      setup_model_specific_data
    end
    
    def setup_model_specific_data
      @resource = create(:electrical_motor, tag: @tag,
                    motor_type: :induction,
                    frame_size: '132',
                    poles: 4,
                    ingress_protection: '55',
                    speed_rated: 1500.0
                  )
      @demand = create(:electrical_demand, demandable: @resource, basis: 'power_pf', basis_notes: 'Test basis notes 7',
        supply: 220.0, config: 'three_3c', power: 1000.0, duty: 0.5)
    end

    test "model specific setup should be valid" do
      assert @demand.valid?
      assert @demand.demandable == @resource
      assert @demand.tag == @tag
      assert @resource.electrical_demand == @demand
    end

    test "motor type must be present" do
      @resource.motor_type = nil
      refute @resource.valid?
      assert_includes @resource.errors[:motor_type], I18n.t("errors.messages.blank")
    end

    test "frame size must be present" do
      @resource.frame_size = nil
      refute @resource.valid?
      assert_includes @resource.errors[:frame_size], I18n.t("errors.messages.blank")
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