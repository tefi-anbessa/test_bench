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

    test_required_fields(:motor_type, :frame_size)
    test_enum_field(:motor_type, keys: [:other, :induction, :synchronous, :dc, :servo, :stepper, :brushless_dc, :universal])
    test_enum_field(:frame_size, keys: [:"63", :"71", :"80", :"90", :"100", :"112", :"132", :"160", :"180", :"200", :"225", :"250", :"280", :"315", :"355", :"400", :"450", :"500", :"560", :"630"])
    test_demandable_association
  end
end