module Electrical
  # Walks everything connected downstream of a distributable (a Switchboard
  # today; a future JunctionBox would work the same way) and combines it into
  # a per-phase resultant current using phasor (vector) summation. Recurses
  # into any downstream demand whose own basis is "summation".
  #
  # This is a standalone analysis, run on demand - it never persists anything
  # back onto a Demand record. See docs/DEVELOPER_NOTES.md and the plan that
  # introduced this for why: recording load data and analysing the network
  # built from it are kept as separate concerns.
  #
  # Problems found while walking the network (bad wiring data, not an attack)
  # are raised as AnalysisError subclasses - callers should rescue the base
  # class and show a flash/notice, not treat it as a security conflict.
  class DownstreamLoadAnalysis
    AnalysisError = Class.new(StandardError)
    CircularReferenceError = Class.new(AnalysisError)
    PhaseMismatchError = Class.new(AnalysisError)

    PHASES = %w[L1 L2 L3].freeze
    THREE_PHASE_CONFIGS = %w[three_3c three_4c].freeze

    def initialize(distributable)
      @distributable = distributable
    end

    # Returns { "L1" => Phasor, "L2" => Phasor, "L3" => Phasor } for everything
    # connected downstream of the given distributable.
    def call
      totals = PHASES.index_with { Phasor.zero }
      accumulate(@distributable, totals, visited: Set.new)
      totals
    end

    private

      def accumulate(distributable, totals, visited:)
        key = [distributable.class.name, distributable.id]
        if visited.include?(key)
          raise CircularReferenceError, "The downstream network loops back to #{distributable.label || key.join('#')}"
        end
        visited = visited | [key]
        own_config = distributable.try(:electrical_demand)&.config

        distributable.downstream_connections.each do |connection|
          demand = connection.demand
          next unless demand

          phasor = phasor_for(demand, own_config, visited)
          share = connection.phase == "ALL" ? phasor * (1.0 / 3) : phasor
          phases_for(connection.phase).each { |phase| totals[phase] += share }
        end
      end

      # The phasor a single downstream demand contributes. If the demand is
      # itself basis: "summation" on another distributable, recurse and fold
      # that board's three lines back into one phasor for this connection -
      # after checking the upstream board isn't single-phase feeding a
      # three-phase one, which isn't a valid configuration.
      def phasor_for(demand, own_config, visited)
        if demand.basis == "summation" && demand.demandable.is_a?(Electrical::Distributable)
          if single_phase?(own_config) && three_phase?(demand.config)
            raise PhaseMismatchError,
              "#{demand.demandable.label} is three-phase but is fed from a single-phase board"
          end

          sub_totals = PHASES.index_with { Phasor.zero }
          accumulate(demand.demandable, sub_totals, visited: visited)
          sub_totals.values.reduce(:+)
        else
          Phasor.from_current(demand.current.to_f, demand.power_factor.to_f)
        end
      end

      def three_phase?(config)
        THREE_PHASE_CONFIGS.include?(config)
      end

      def single_phase?(config)
        config.present? && !three_phase?(config)
      end

      def phases_for(phase)
        phase == "ALL" ? PHASES : [phase]
      end
  end
end
