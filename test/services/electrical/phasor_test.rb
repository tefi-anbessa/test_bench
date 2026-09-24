require "test_helper"

module Electrical
  class PhasorTest < ActiveSupport::TestCase
    test "zero has no current and a unity power factor" do
      zero = Phasor.zero
      assert_equal 0.0, zero.current
      assert_equal 1.0, zero.power_factor
    end

    test "from_current round-trips current and power_factor" do
      phasor = Phasor.from_current(10.0, 0.8)
      assert_in_delta 10.0, phasor.current, 0.0001
      assert_in_delta 0.8, phasor.power_factor, 0.0001
    end

    test "adding two in-phase phasors sums their current directly" do
      sum = Phasor.from_current(3.0, 1.0) + Phasor.from_current(4.0, 1.0)
      assert_in_delta 7.0, sum.current, 0.0001
      assert_in_delta 1.0, sum.power_factor, 0.0001
    end

    test "adding perpendicular phasors (3-4-5 triangle) combines as vectors, not scalars" do
      # pf 1.0 -> angle 0 (magnitude 3 on the real axis)
      # pf 0.0 -> angle 90deg (magnitude 4, purely reactive)
      sum = Phasor.from_current(3.0, 1.0) + Phasor.from_current(4.0, 0.0)
      assert_in_delta 5.0, sum.current, 0.0001
      assert_in_delta 0.6, sum.power_factor, 0.0001 # cos(atan2(4,3))
    end

    test "multiplying by a scalar scales current and leaves power factor unchanged" do
      third = Phasor.from_current(9.0, 0.9) * (1.0 / 3)
      assert_in_delta 3.0, third.current, 0.0001
      assert_in_delta 0.9, third.power_factor, 0.0001
    end
  end
end
