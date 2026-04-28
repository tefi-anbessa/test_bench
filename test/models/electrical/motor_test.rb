# frozen_string_literal: true
require "test_helper"
require 'helpers/tagable_model_tests'

module Electrical
  class MotorTest < ActiveSupport::TestCase
    include TagableModelTests

    def setup
      setup_common_test_data
      @resource.electrical_demand = create(:electrical_demand, demandable: @resource)
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
    
    test "should have demand through demandable concern" do
      assert_respond_to @resource, :electrical_demand
    end
    
    test "should have tag through tagable concern" do
      assert_respond_to @resource, :tag
      assert_equal @tag, @resource.tag
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
    
    # Test enum definitions
    test "should have enum attribute methods" do
      assert_respond_to @resource, :motor_type
      assert_respond_to @resource, :induction?
      assert_respond_to @resource, :frame_size
      assert_respond_to @resource, :"63?"
      assert_equal 'induction', @resource.motor_type
    end
  end
end