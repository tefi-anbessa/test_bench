module Electrical
  # Interface for models that distribute power downstream via their own outgoing
  # connections (Switchboard via circuits today; a future JunctionBox with its
  # own protection-less child model would include this the same way).
  # Electrical::DownstreamLoadAnalysis only ever calls #downstream_connections,
  # never a concrete association name, so it works for either.
  module Distributable
    extend ActiveSupport::Concern

    # Must return an enumerable of objects that each respond to #phase (an
    # Electrical::Circuit phase value: "L1"/"L2"/"L3"/"ALL") and #demand
    # (the Electrical::Demand connected there, or nil).
    def downstream_connections
      raise NotImplementedError, "#{self.class} must implement #downstream_connections"
    end
  end
end
