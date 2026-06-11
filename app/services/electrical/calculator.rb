# app/services/electrical/calculator.rb
module Electrical
  class Calculator
    attr_reader :demand

    def initialize(demand)
      @demand = demand
    end

    def calculate!
      return unless valid_inputs?

      case demand.basis
      when "power_pf"
        calculate_from_power_pf
      when "vector_pf"
        calculate_from_vector_pf
      when "current_pf"
        calculate_from_current_pf
      end

      demand
    end

    private

    def valid_inputs?
      demand.supply.present? && demand.config.present?
    end

    # ---- Basis strategies ----

    def calculate_from_power_pf
      return unless demand.power && demand.power_factor

      demand.vector  = demand.power / demand.power_factor
      demand.current = current_from_apparent(demand.vector)
    end

    def calculate_from_vector_pf
      return unless demand.vector && demand.power_factor

      demand.power   = demand.vector * demand.power_factor
      demand.current = current_from_apparent(demand.vector)
    end

    def calculate_from_current_pf
      return unless demand.current && demand.power_factor

      s = apparent_from_current(demand.current)
      demand.vector = s
      demand.power  = s * demand.power_factor
    end

    # ---- Core electrical logic ----

    def current_from_apparent(s)
      case demand.config
      when "three_3c"
        s / (Math.sqrt(3) * voltage_ll)
      when "three_4c"
        s / (3 * voltage_ln)
      else
        s / voltage_ln
      end
    end

    def apparent_from_current(i)
      case demand.config
      when "three_3c"
        i * Math.sqrt(3) * voltage_ll
      when "three_4c"
        i * 3 * voltage_ln
      else
        i * voltage_ln
      end
    end

    # ---- Voltage interpretation ----

    def voltage_ln
      demand.voltage_reference == "ln" ? demand.supply : demand.supply / Math.sqrt(3)
    end

    def voltage_ll
      demand.voltage_reference == "ll" ? demand.supply : demand.supply * Math.sqrt(3)
    end
  end
end