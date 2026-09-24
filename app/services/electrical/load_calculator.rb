# app/services/electrical/load_calculator.rb
module Electrical
  # Derives whichever electrical quantities the user did not enter directly
  # for a demand's load basis (current, power, power factor, vector/apparent
  # power). Mirrors the client-side live-update logic in
  # app/javascript/controllers/electrical_demand_controller.js - keep the
  # two in sync if either changes.
  class LoadCalculator
    def initialize(basis:, config:, supply:, current:, power:, power_factor:, vector:)
      @basis = basis
      @config = config
      @supply = supply.to_f
      @current = current.to_f
      @power = power.to_f
      @power_factor = power_factor.to_f
      @vector = vector.to_f
    end

    def current
      calculated[:current]
    end

    def power
      calculated[:power]
    end

    def power_factor
      calculated[:power_factor]
    end

    def vector
      calculated[:vector]
    end

    private

      def calculated
        @calculated ||= case @basis
        when "power_pf"
          apparent = apparent_power_from_power_pf
          { current: current_from_apparent(apparent), power: @power, power_factor: @power_factor, vector: apparent }
        when "vector_pf"
          { current: current_from_apparent(@vector), power: real_power_from_vector_pf, power_factor: @power_factor, vector: @vector }
        when "current_pf"
          apparent = apparent_power_from_current
          { current: @current, power: real_power_from_apparent(apparent), power_factor: @power_factor, vector: apparent }
        when "current_power"
          apparent = apparent_power_from_current
          { current: @current, power: @power, power_factor: power_factor_from_real(apparent), vector: apparent }
        else
          # "summation" - not implemented yet; leave values as entered.
          { current: @current, power: @power, power_factor: @power_factor, vector: @vector }
        end
      end

      # Apparent power (VA) from current, config-aware:
      # three_3c uses line-to-line voltage (sqrt(3) factor),
      # three_4c uses line-to-neutral voltage (factor of 3).
      def apparent_power_from_current
        case @config
        when "three_3c" then Math.sqrt(3) * @supply * @current
        when "three_4c" then 3 * @supply * @current
        else @supply * @current
        end
      end

      def current_from_apparent(apparent)
        return 0.0 if @supply.zero?
        case @config
        when "three_3c" then apparent / (Math.sqrt(3) * @supply)
        when "three_4c" then apparent / (3 * @supply)
        else apparent / @supply
        end
      end

      def apparent_power_from_power_pf
        return 0.0 if @power_factor.zero?
        @power / @power_factor
      end

      def real_power_from_vector_pf
        @vector * @power_factor
      end

      def real_power_from_apparent(apparent)
        apparent * @power_factor
      end

      def power_factor_from_real(apparent)
        return 0.0 if apparent.zero?
        @power / apparent
      end
  end
end
