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

    test "heater type must be present" do
      @resource.heater_type = nil
      refute @resource.valid?
      assert_includes @resource.errors[:heater_type], I18n.t("errors.messages.blank")
    end

    test "application must be present" do
      @resource.application = nil
      refute @resource.valid?
      assert_includes @resource.errors[:application], I18n.t("errors.messages.blank")
    end

    # Demand creation is tested separately in Demand model tests

    test "destroy heater should nullify tagable" do
      @resource.destroy
      
      @tag.reload
      assert_nil @tag.tagable
      assert_nil @tag.tagable_type
      assert_nil @tag.tagable_id
    end
    
    test "should have demand through demandable concern" do
      assert_respond_to @resource, :electrical_demand
    end
    
    test "should have tag through tagable concern" do
      assert_respond_to @resource, :tag
      assert_equal @tag, @resource.tag
    end
    
    # Test enum definitions
    test "should have enum attributes" do
      assert_respond_to @resource, :heater_type
      assert_respond_to @resource, :cast_in?
      assert_respond_to @resource, :application
      assert_respond_to @resource, :annealing_heat_treating?
      assert_respond_to @resource, :sheath_material
      assert_respond_to @resource, :sheath_material_aluminium?
      assert_respond_to @resource, :insulation_material
      assert_respond_to @resource, :insulation_material_ceramic?
    end
  end
end