# frozen_string_literal: true

require "test_helper"
require 'helpers/tagable_model_tests'

module Electrical
  class SocketCctTest < ActiveSupport::TestCase
    include TagableModelTests

    def setup
      setup_common_test_data
      @resource.electrical_demand = create(:electrical_demand, demandable: @resource)
    end

    test "socket circuit type must be present" do
      @resource.socket_type = nil
      refute @resource.valid?
      assert_includes @resource.errors[:socket_type], I18n.t("errors.messages.blank")
    end

    test "socket circuit quantity must be present" do
      @resource.quantity = nil
      refute @resource.valid?
      assert_includes @resource.errors[:quantity], I18n.t("errors.messages.not_a_number")
    end

    test "socket circuit quantity must be greater than 0" do
      @resource.quantity = 0
      refute @resource.valid?
      assert_includes @resource.errors[:quantity], I18n.t("errors.messages.greater_than", count: 0)
    end

    # Demand creation is tested separately in Demand model tests

    test "destroy socket circuit should nullify tagable" do
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
    test "should have socket_type attribute" do
      assert_respond_to @resource, :socket_type
      assert_respond_to @resource, :'10A?'
      assert_equal '10A', @resource.socket_type
    end
  end
end