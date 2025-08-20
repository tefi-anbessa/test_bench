require "test_helper"

class CircuitTest < ActiveSupport::TestCase
  def setup
    @switchboard = create(:switchboard)
    @circuit = create(:circuit, switchboard: @switchboard)
  end

  test "factory should create valid circuit" do
    assert @circuit.valid?
    assert @switchboard.circuits.include?(@circuit)
    assert (1..36).cover?(@circuit.serial), "Serial should be between 1 and 36"
    assert_equal 'L1', @circuit.phase
    assert_equal 'MCB', @circuit.device
    assert_equal 1, @circuit.poles
    assert_equal 'B', @circuit.curve
    assert_equal 16.0, @circuit.rating
    assert_equal 'None', @circuit.elcb
    assert_equal false, @circuit.contactor
    assert_nil @circuit.notes
  end

  test "should require serial number between 1 and 36" do
    @circuit.serial = 0
    assert_not @circuit.valid?
    assert_includes @circuit.errors[:serial], "is not included in the list"
    
    @circuit.serial = 37
    assert_not @circuit.valid?
    assert_includes @circuit.errors[:serial], "is not included in the list"
    
    @circuit.serial = 1
    assert @circuit.valid?
    
    @circuit.serial = 36
    assert @circuit.valid?
  end

  test "should require unique serial number per switchboard" do
    # Use a unique serial number for this test to avoid conflicts with other tests
    test_serial = 35  # Using a high number to avoid conflicts
    
    # First, create a circuit with our test serial on the switchboard
    create(:circuit, switchboard: @switchboard, serial: test_serial)
    
    # Try to create another circuit with the same serial on the same switchboard
    duplicate_circuit = build(:circuit, switchboard: @switchboard, serial: test_serial)
    assert_not duplicate_circuit.valid?
    assert_includes duplicate_circuit.errors[:serial], "already exists"
    
    # Should allow same serial on a different switchboard
    other_switchboard = create(:switchboard)
    other_circuit = build(:circuit, switchboard: other_switchboard, serial: test_serial)
    assert other_circuit.valid?
  end

  # TODO: Uncomment when load factory is available
  # test "should create circuit with load" do
  #   circuit = create(:circuit, :with_load, switchboard: @switchboard)
  #   assert circuit.load.present?
  #   assert_equal circuit, circuit.load.circuit
  # end

  test "should create circuit with cable" do
    circuit = create(:circuit, :with_cable, switchboard: @switchboard)
    assert circuit.cable.present?
    assert_equal circuit, circuit.cable.circuit
  end

  test "destroy circuit should nullify demand and cable references" do
    circuit = create(:circuit, :with_demand, :with_cable, switchboard: @switchboard)
    demand = circuit.demand
    cable = circuit.cable
    
    # Only the circuit count should decrease
    assert_difference 'Circuit.count', -1 do
      assert_no_difference ['Demand.count', 'Cable.count'] do
        circuit.destroy
      end
    end
    
    # Check that demand and cable still exist but their circuit reference is nullified
    assert_nil demand.reload.circuit_id
    assert_nil cable.reload.circuit_id
  end

  test "should create multiple circuits with unique serial numbers" do
    # Create 3 circuits on the same switchboard
    circuits = create_list(:circuit, 3, switchboard: @switchboard)
    
    # Get all serial numbers and ensure they're unique
    serials = circuits.map(&:serial)
    assert_equal serials.uniq, serials, "Expected all serial numbers to be unique"
    
    # All serials should be between 1 and 36
    assert serials.all? { |s| (1..36).cover?(s) }, "All serials should be between 1 and 36"
  end

  test "should enforce unique serial numbers per switchboard" do
    # Create a new switchboard for this test to avoid conflicts with other tests
    test_switchboard = create(:switchboard)
    
    # First, create a circuit with serial 1 on the test switchboard
    create(:circuit, switchboard: test_switchboard, serial: 1)
    
    # Try to create another circuit with the same serial on the same switchboard
    duplicate_circuit = build(:circuit, switchboard: test_switchboard, serial: 1)
    assert_not duplicate_circuit.valid?, "Should not allow duplicate serial on same switchboard"
    assert_includes duplicate_circuit.errors[:serial], "already exists"
    
    # Should be able to create on a different switchboard with the same serial
    other_switchboard = create(:switchboard)
    other_circuit = build(:circuit, switchboard: other_switchboard, serial: 1)
    assert other_circuit.valid?, "Should allow same serial on different switchboard"
  end
  
  test "should allow serial numbers from 1 to 36" do
    # Create a new switchboard for this test to avoid conflicts with other tests
    test_switchboard = create(:switchboard)
    
    # Test minimum serial number (1)
    circuit1 = build(:circuit, switchboard: test_switchboard, serial: 1)
    assert circuit1.valid?, "Circuit with serial 1 should be valid: #{circuit1.errors.full_messages}"
    
    # Test maximum serial number (36)
    circuit36 = build(:circuit, switchboard: test_switchboard, serial: 36)
    assert circuit36.valid?, "Circuit with serial 36 should be valid: #{circuit36.errors.full_messages}"
    
    # Test below range (0)
    circuit0 = build(:circuit, switchboard: test_switchboard, serial: 0)
    assert_not circuit0.valid?, "Circuit with serial 0 should not be valid"
    
    # Test above range (37)
    circuit37 = build(:circuit, switchboard: test_switchboard, serial: 37)
    assert_not circuit37.valid?, "Circuit with serial 37 should not be valid"
  end
end
