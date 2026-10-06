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

    test_required_fields(:socket_type)
    test_enum_field(:socket_type)
    test_demandable_association

    test "socket circuit quantity must be greater than 0" do
      @resource.quantity = 0
      refute @resource.valid?
      assert_includes @resource.errors[:quantity], I18n.t("errors.messages.greater_than", count: 0)
    end
  end
end