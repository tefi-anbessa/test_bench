require "test_helper"

module Electrical
  class LoadCalculatorTest < ActiveSupport::TestCase
    # Mirrors the formulas in app/javascript/controllers/electrical_demand_controller.js -
    # if this test starts failing after a change to one side, check the other agrees.

    def calculator(basis:, config: "one", supply: 0, current: 0, power: 0, power_factor: 0, vector: 0)
      Electrical::LoadCalculator.new(
        basis: basis, config: config, supply: supply,
        current: current, power: power, power_factor: power_factor, vector: vector
      )
    end

    test "power_pf derives current and vector, leaves power and power_factor as given" do
      calc = calculator(basis: "power_pf", config: "one", supply: 230, power: 1000.0, power_factor: 0.8)

      assert_equal 1000.0, calc.power
      assert_equal 0.8, calc.power_factor
      assert_in_delta 1250.0, calc.vector, 0.0001               # power / pf
      assert_in_delta 1250.0 / 230, calc.current, 0.0001        # vector / supply (single phase)
    end

    test "vector_pf derives power and current, leaves vector and power_factor as given" do
      calc = calculator(basis: "vector_pf", config: "one", supply: 230, vector: 1500.0, power_factor: 0.75)

      assert_equal 1500.0, calc.vector
      assert_equal 0.75, calc.power_factor
      assert_in_delta 1125.0, calc.power, 0.0001                # vector * pf
      assert_in_delta 1500.0 / 230, calc.current, 0.0001        # vector / supply (single phase)
    end

    test "current_pf derives power and vector, leaves current and power_factor as given, three_3c uses sqrt(3)" do
      calc = calculator(basis: "current_pf", config: "three_3c", supply: 400, current: 10.0, power_factor: 0.9)

      expected_vector = Math.sqrt(3) * 400 * 10.0

      assert_equal 10.0, calc.current
      assert_equal 0.9, calc.power_factor
      assert_in_delta expected_vector, calc.vector, 0.0001
      assert_in_delta expected_vector * 0.9, calc.power, 0.0001
    end

    test "current_power derives power_factor and vector, leaves current and power as given, three_4c uses factor of 3" do
      calc = calculator(basis: "current_power", config: "three_4c", supply: 230, current: 15.0, power: 9000.0)

      expected_vector = 3 * 230 * 15.0

      assert_equal 15.0, calc.current
      assert_equal 9000.0, calc.power
      assert_in_delta expected_vector, calc.vector, 0.0001
      assert_in_delta 9000.0 / expected_vector, calc.power_factor, 0.0001
    end

    test "summation is not implemented yet and leaves every value unchanged" do
      calc = calculator(basis: "summation", current: 5.0, power: 1000.0, power_factor: 0.8, vector: 1250.0)

      assert_equal 5.0, calc.current
      assert_equal 1000.0, calc.power
      assert_equal 0.8, calc.power_factor
      assert_equal 1250.0, calc.vector
    end

    test "power_pf with a zero power factor does not raise and derives zero" do
      calc = calculator(basis: "power_pf", supply: 230, power: 1000.0, power_factor: 0.0)

      assert_equal 0.0, calc.vector
      assert_equal 0.0, calc.current
    end

    test "current derivation with zero supply does not raise and derives zero" do
      calc = calculator(basis: "vector_pf", supply: 0, vector: 1500.0, power_factor: 0.8)

      assert_equal 0.0, calc.current
    end

    test "current_power with zero current derives a zero power factor" do
      calc = calculator(basis: "current_power", config: "one", supply: 230, current: 0.0, power: 9000.0)

      assert_equal 0.0, calc.vector
      assert_equal 0.0, calc.power_factor
    end

    test "an unknown config falls back to single phase (supply * current)" do
      calc = calculator(basis: "current_pf", config: "dc", supply: 24, current: 2.0, power_factor: 1.0)

      assert_in_delta 48.0, calc.vector, 0.0001
    end
  end
end
