require "test_helper"

class CircuitTest < ActiveSupport::TestCase
  def setup
    @project = create(:project)
    @discipline_e = create(:discipline, :elec, project: @project)
    @tag = create(:tag, discipline: @discipline_e)
    @switchboard = create(:electrical_switchboard, tag: @tag)
    @circuit = create(:electrical_circuit, electrical_switchboard: @switchboard)
  end

  test "setup should be valid" do
    assert @project.valid?
    assert @discipline_e.valid?
    assert_equal @project, @discipline_e.project
    assert @tag.valid?
    assert_equal @project, @tag.project
    assert_equal @discipline_e, @tag.discipline
    assert @switchboard.valid?
    assert @circuit.valid?
    assert @switchboard.electrical_circuits.include?(@circuit)
  end

  test "factory default should create valid circuit with full chain of associations" do
    circuit = create(:electrical_circuit)
    assert circuit.valid?
    assert circuit.electrical_switchboard.valid?
    assert circuit.electrical_switchboard.tag.valid?
    assert circuit.electrical_switchboard.tag.discipline.valid?
    assert circuit.electrical_switchboard.tag.discipline.project.valid?
  end

  test "should require serial number between 1 and 36" do
    @circuit.serial = 0
    refute @circuit.valid?
    #assert_includes @circuit.errors[:serial], I18n.t('errors.messages.in', count: 1..36)
    
    @circuit.serial = 37
    refute @circuit.valid?
    assert_includes @circuit.errors[:serial], I18n.t('errors.messages.in', count: 1..36)
    
    @circuit.serial = 1
    assert @circuit.valid?
    
    @circuit.serial = 36
    assert @circuit.valid?
  end

  test "should require unique serial number per switchboard" do
    # Use a unique serial number for this test to avoid conflicts with other tests
    test_serial = create(:electrical_circuit, electrical_switchboard: @switchboard, serial: 35)

    # Try to create another circuit with the same serial on the same switchboard
    duplicate_circuit = build(:electrical_circuit, electrical_switchboard: @switchboard, serial: test_serial.serial)
    refute duplicate_circuit.valid?
    assert_includes duplicate_circuit.errors[:serial], I18n.t('errors.messages.taken')

    # Should allow same serial on a different switchboard
    other_tag = create(:tag, discipline: @discipline_e)
    other_switchboard = create(:electrical_switchboard, tag: other_tag)
    other_circuit = build(:electrical_circuit, electrical_switchboard: other_switchboard, serial: test_serial.serial)
    assert other_circuit.valid?
  end

  test "destroy circuit should nullify cable feeder reference" do
    circuit = create(:electrical_circuit, electrical_switchboard: @switchboard)
    cable_tag = create(:tag, discipline: @discipline_e, prefix: "EC")
    cable = create(:electrical_cable, tag: cable_tag, from: circuit)

    # Only the circuit count should decrease
    assert_difference 'Electrical::Circuit.count', -1 do
      assert_no_difference ['Electrical::Cable.count'] do
        circuit.destroy
      end
    end

    # Check that cable still exists but its from reference is nullified
    assert_nil cable.reload.from_id
  end

  test "factory should create multiple circuits with unique serial numbers" do
    # Create 3 circuits on the same switchboard
    circuits = create_list(:electrical_circuit, 3, electrical_switchboard: @switchboard)
    
    # Get all serial numbers and ensure they're unique
    serials = circuits.map(&:serial)
    assert_equal serials.uniq, serials, "Expected all serial numbers to be unique"
    
    # All serials should be between 1 and 36
    assert serials.all? { |s| (1..36).cover?(s) }, "All serials should be between 1 and 36"
  end

  test "factory should enforce unique serial numbers per switchboard" do
    # Create a new switchboard for this test to avoid conflicts with other tests
    test_tag = create(:tag, :unique_tag, discipline: @discipline_e)
    test_switchboard = create(:electrical_switchboard, tag: test_tag)

    # First, create a circuit with serial 1 on the test switchboard
    create(:electrical_circuit, electrical_switchboard: test_switchboard, serial: 1)

    # Try to create another circuit with the same serial on the same switchboard
    duplicate_circuit = build(:electrical_circuit, electrical_switchboard: test_switchboard, serial: 1)
    refute duplicate_circuit.valid?, "Should not allow duplicate serial on same switchboard"
    assert_includes duplicate_circuit.errors[:serial], I18n.t('errors.messages.taken')

    # Should be able to create on a different switchboard with the same serial
    other_tag = create(:tag, :unique_tag, discipline: @discipline_e)
    other_switchboard = create(:electrical_switchboard, tag: other_tag)
    other_circuit = build(:electrical_circuit, electrical_switchboard: other_switchboard, serial: 1)
    assert other_circuit.valid?, "Should allow same serial on different switchboard"
  end
   
  test "should use switchboard tag and circuit serial for label" do
    # Create tag with known label components
    tag = create(:tag, prefix: 'EX', serial: 5, suffix: "Y", discipline: @discipline_e)
    assert_difference 'Electrical::Switchboard.count', 1 do
      tag.update(tagable: build(:electrical_switchboard, tag: tag))
    end
    switchboard = tag.reload.tagable
    assert_equal "EX0005Y", switchboard.label
    circuit = switchboard.electrical_circuits.create(serial: 1)
    assert_equal "#01", circuit.label
    assert_equal "EX0005Y #01", circuit.long_label
  end
end
