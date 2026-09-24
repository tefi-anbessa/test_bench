require "test_helper"

module Electrical
  class DownstreamLoadAnalysisTest < ActiveSupport::TestCase
    # Connects a circuit to a demand via a feeder cable, as the real app does.
    def connect(circuit, demand)
      create(:electrical_cable, from: circuit, to: demand)
    end

    def leaf_demand(current:, power_factor: 1.0)
      create(:electrical_demand, basis: "current_pf", current: current, power_factor: power_factor)
    end

    test "sums single-phase circuits onto their own phase" do
      board = create(:electrical_switchboard)
      l1 = create(:electrical_circuit, switchboard: board, phase: "L1")
      l2 = create(:electrical_circuit, switchboard: board, phase: "L2")
      connect(l1, leaf_demand(current: 10.0))
      connect(l2, leaf_demand(current: 5.0))

      totals = Electrical::DownstreamLoadAnalysis.new(board).call

      assert_in_delta 10.0, totals["L1"].current, 0.0001
      assert_in_delta 5.0, totals["L2"].current, 0.0001
      assert_in_delta 0.0, totals["L3"].current, 0.0001
    end

    test "a circuit with no connected demand contributes nothing" do
      board = create(:electrical_switchboard)
      create(:electrical_circuit, switchboard: board, phase: "L1") # no cable/demand attached

      totals = Electrical::DownstreamLoadAnalysis.new(board).call

      assert_in_delta 0.0, totals["L1"].current, 0.0001
    end

    test "an ALL-phase (three-phase) downstream load is split evenly across the three lines" do
      board = create(:electrical_switchboard)
      three_phase = create(:electrical_circuit, switchboard: board, phase: "ALL")
      connect(three_phase, leaf_demand(current: 9.0))

      totals = Electrical::DownstreamLoadAnalysis.new(board).call

      %w[L1 L2 L3].each do |phase|
        assert_in_delta 3.0, totals[phase].current, 0.0001
      end
    end

    test "recurses into a downstream board whose own demand is basis: summation" do
      sub_board = create(:electrical_switchboard)
      sub_l1 = create(:electrical_circuit, switchboard: sub_board, phase: "L1")
      sub_l2 = create(:electrical_circuit, switchboard: sub_board, phase: "L2")
      connect(sub_l1, leaf_demand(current: 10.0))
      connect(sub_l2, leaf_demand(current: 5.0))

      sub_board_demand = create(:electrical_demand, demandable: sub_board, basis: "summation")

      root = create(:electrical_switchboard)
      feeder_circuit = create(:electrical_circuit, switchboard: root, phase: "L1")
      connect(feeder_circuit, sub_board_demand)
      direct_leaf_circuit = create(:electrical_circuit, switchboard: root, phase: "L2")
      connect(direct_leaf_circuit, leaf_demand(current: 3.0))

      totals = Electrical::DownstreamLoadAnalysis.new(root).call

      # sub_board's own two in-phase (pf 1.0) leaf loads combine to 15A, folded
      # onto the root's L1 (the phase the feeder circuit is on).
      assert_in_delta 15.0, totals["L1"].current, 0.0001
      assert_in_delta 3.0, totals["L2"].current, 0.0001
      assert_in_delta 0.0, totals["L3"].current, 0.0001
    end

    test "raises CircularReferenceError instead of looping on a self-referential board" do
      board = create(:electrical_switchboard)
      demand = create(:electrical_demand, demandable: board, basis: "summation")
      circuit = create(:electrical_circuit, switchboard: board, phase: "L1")
      connect(circuit, demand)

      assert_raises(Electrical::DownstreamLoadAnalysis::CircularReferenceError) do
        Electrical::DownstreamLoadAnalysis.new(board).call
      end
    end

    test "CircularReferenceError is an AnalysisError, so callers can rescue the common base" do
      assert_operator Electrical::DownstreamLoadAnalysis::CircularReferenceError, :<,
        Electrical::DownstreamLoadAnalysis::AnalysisError
    end

    test "raises PhaseMismatchError when a single-phase board feeds a three-phase board" do
      three_phase_board = create(:electrical_switchboard)
      three_phase_demand = create(:electrical_demand, demandable: three_phase_board,
                                   basis: "summation", config: "three_3c")

      single_phase_board = create(:electrical_switchboard)
      single_phase_demand = create(:electrical_demand, demandable: single_phase_board,
                                    basis: "current_pf", config: "one", current: 5.0, power_factor: 1.0)
      feeder = create(:electrical_circuit, switchboard: single_phase_board, phase: "L1")
      connect(feeder, three_phase_demand)

      error = assert_raises(Electrical::DownstreamLoadAnalysis::PhaseMismatchError) do
        Electrical::DownstreamLoadAnalysis.new(single_phase_board).call
      end
      assert_kind_of Electrical::DownstreamLoadAnalysis::AnalysisError, error
    end

    test "does not raise when a three-phase board feeds another three-phase board" do
      leaf_board = create(:electrical_switchboard)
      leaf_l1 = create(:electrical_circuit, switchboard: leaf_board, phase: "L1")
      connect(leaf_l1, leaf_demand(current: 6.0))
      leaf_demand_record = create(:electrical_demand, demandable: leaf_board, basis: "summation", config: "three_3c")

      root = create(:electrical_switchboard)
      root_demand = create(:electrical_demand, demandable: root, basis: "current_pf", config: "three_4c",
                            current: 5.0, power_factor: 1.0)
      feeder = create(:electrical_circuit, switchboard: root, phase: "L1")
      connect(feeder, leaf_demand_record)

      totals = Electrical::DownstreamLoadAnalysis.new(root).call
      assert_in_delta 6.0, totals["L1"].current, 0.0001
    end
  end
end
