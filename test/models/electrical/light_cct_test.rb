# frozen_string_literal: true

require "test_helper"
require 'helpers/tagable_model_tests'

module Electrical
  class LightCctTest < ActiveSupport::TestCase
    include TagableModelTests

    def setup
      setup_common_test_data
      @resource.electrical_demand = create(:electrical_demand, demandable: @resource)
    end

    test "light circuit type must be present" do
      @resource.light_fitting_type = nil
      refute @resource.valid?
      assert_includes @resource.errors[:light_fitting_type], I18n.t("errors.messages.blank")
    end

    test "light circuit quantity must be present" do
      @resource.quantity = nil
      refute @resource.valid?
      assert_includes @resource.errors[:quantity], I18n.t("errors.messages.not_a_number")
    end

    test "light circuit quantity must be greater than 0" do
      @resource.quantity = 0
      refute @resource.valid?
      assert_includes @resource.errors[:quantity], I18n.t("errors.messages.greater_than", count: 0)
    end

    # Demand creation is tested separately in Demand model tests

    test "destroy light circuit should nullify tagable" do
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
    test "should have light_fitting_type attribute" do
      assert_respond_to @resource, :light_fitting_type
      assert_respond_to @resource, :general?
    end
  end
end