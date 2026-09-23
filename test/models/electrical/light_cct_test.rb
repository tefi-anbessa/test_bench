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

    test_required_fields(:light_fitting_type)
    test_enum_field(:light_fitting_type, keys: [:other, :general, :outdoor])
    test_demandable_association

    test "light circuit quantity must be greater than 0" do
      @resource.quantity = 0
      refute @resource.valid?
      assert_includes @resource.errors[:quantity], I18n.t("errors.messages.greater_than", count: 0)
    end
    
    # Test enum definitions
    test "should have light_fitting_type attribute" do
      assert_respond_to @resource, :light_fitting_type
      assert_respond_to @resource, :general?
    end
  end
end