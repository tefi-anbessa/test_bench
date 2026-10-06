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

    test_required_fields(:motor_type)
    test_enum_field(:motor_type)
    test_enum_field(:frame_size)
    test_demandable_association
  end
end