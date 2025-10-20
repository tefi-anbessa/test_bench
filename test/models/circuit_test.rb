require "test_helper"

class CircuitTest < ActiveSupport::TestCase
  def setup
    @project = create(:project)
    @discipline_e = create(:discipline, :e)
    @tag = create(:tag, project: @project, discipline: @discipline_e)
    @switchboard = create(:switchboard, tag: @tag)
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

    # Test factory default creates a full chain of associations
    circuit = create(:circuit)
    assert circuit.valid?
    assert circuit.switchboard.valid?
    assert circuit.switchboard.tag.valid?
    assert circuit.switchboard.tag.project.valid?
    assert circuit.switchboard.tag.discipline.valid?
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
    other_tag = create(:tag, project: @project, discipline: create(:discipline, :e))
    other_switchboard = create(:switchboard, tag: other_tag)
    other_circuit = build(:circuit, switchboard: other_switchboard, serial: test_serial)
    assert other_circuit.valid?
  end

  test "destroy circuit should nullify cable feeder reference" do
    circuit = create(:circuit, switchboard: @switchboard)
    cable_tag = create(:tag, project: @project, discipline: create(:discipline, :e), prefix: "EC")
    cable = create(:cable, tag: cable_tag, from: circuit)

    # Only the circuit count should decrease
    assert_difference 'Circuit.count', -1 do
      assert_no_difference ['Cable.count'] do
        circuit.destroy
      end
    end

    # Check that cable still exists but its from reference is nullified
    assert_nil cable.reload.from_id
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
    test_tag = create(:tag, project: @project, discipline: @discipline_e)
    test_switchboard = create(:switchboard, tag: test_tag)

    # First, create a circuit with serial 1 on the test switchboard
    create(:circuit, switchboard: test_switchboard, serial: 1)

    # Try to create another circuit with the same serial on the same switchboard
    duplicate_circuit = build(:circuit, switchboard: test_switchboard, serial: 1)
    assert_not duplicate_circuit.valid?, "Should not allow duplicate serial on same switchboard"
    assert_includes duplicate_circuit.errors[:serial], "already exists"

    # Should be able to create on a different switchboard with the same serial
    other_tag = create(:tag, project: @project, discipline: @discipline_e)
    other_switchboard = create(:switchboard, tag: other_tag)
    other_circuit = build(:circuit, switchboard: other_switchboard, serial: 1)
    assert other_circuit.valid?, "Should allow same serial on different switchboard"
  end
  
  test "should allow serial numbers from 1 to 36" do
    # Create a new switchboard for this test to avoid conflicts with other tests
    test_tag = create(:tag, project: @project, discipline: @discipline_e)
    test_switchboard = create(:switchboard, tag: test_tag)

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

   
  test "should use switchboard tag and circuit serial for label" do
    project = create(:project)
    discipline = Discipline.find_or_create_by(code: 'E')

    tag = create(:tag,
      prefix: 'EX',
      serial: 5,
      suffix: "",
      project: project,
      discipline: discipline
    )

    assert_difference 'Switchboard.count', 1 do
      tag.update(tagable: build(:switchboard,
        tag: tag,
        location: 'Gatehouse',
        ingress_protection: '22'
      ))
    end
    switchboard = tag.reload.tagable
    assert_equal "E:EX-0005", switchboard.label
    circuit = switchboard.circuits.create(
      serial: 1
    )
    assert_equal "E:EX-0005 #01", circuit.label
  end
end
