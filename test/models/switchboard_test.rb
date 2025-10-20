require "test_helper"

class SwitchboardTest < ActiveSupport::TestCase
  def setup
    @project = create(:project, title: 'Test Switchboards')
    @discipline_e = create(:discipline, code: 'E')
    @switchboard = create(:switchboard, project: @project, discipline: @discipline_e)
    @tag = @switchboard.tag
  end

  test "factory should create valid switchboard with tag" do
    assert @switchboard.valid?
    assert @tag.valid?

    # Check that factory creates a functional switchboard without any given parameters.
    swbd = create(:switchboard)
    assert swbd.valid?
    assert swbd.tag.valid?
    
  end

  test "should create switchboard with custom tag attributes" do
    switchboard = nil
    assert_difference ['Switchboard.count', 'Tag.count'], 1 do
      switchboard = create(:switchboard,
        location: 'Gatehouse',
        ingress_protection: '22'
      )
    end
    # Check factory default prefix
    assert_equal 'EX', switchboard.tag.prefix
    assert_match(/E:EX-\d+\.?\w*/, switchboard.tag.reload.full_tag)
    assert_equal 'Gatehouse', switchboard.location
    assert_equal '22', switchboard.ingress_protection
  end
  
  test "should create switchboard through tag update" do
    tag = create(:tag,
      prefix: 'EX',
      serial: 5,
      suffix: "",
      project: @project,
      stage: 9,
      discipline: @discipline_e
    )
    
    assert_difference 'Switchboard.count', 1 do
      tag.update(tagable: build(:switchboard,
        location: 'Gatehouse',
        ingress_protection: '22'
      ))
    end
    
    assert tag.reload.tagable.is_a?(Switchboard)
    assert_equal "E:EX-0005", tag.switchboard.label
    assert_equal 'Gatehouse', tag.tagable.location
    assert_equal '22', tag.tagable.ingress_protection
  end

  test "destroy switchboard should nullify tagable" do
    @switchboard.destroy
    @tag.reload
    assert_nil @tag.tagable_id
  end

  test "destroy tag should destroy switchboard" do
    assert_difference 'Switchboard.count', -1 do
      @tag.destroy
    end
  end

  test "destroy switchboard should destroy associated circuits" do
    # First, create a circuit associated with the switchboard
    circuit = create(:circuit, switchboard: @switchboard)
    
    # Verify the circuit was created
    assert_includes @switchboard.circuits, circuit
    
    # Now destroy the switchboard and verify the circuit is also destroyed
    assert_difference 'Circuit.count', -1 do
      @switchboard.destroy
    end
    
    # Verify the circuit was destroyed
    assert_raises(ActiveRecord::RecordNotFound) { circuit.reload }
  end
  
  test "should create switchboard with specified number of circuits" do
    switchboard = create(:switchboard, :with_circuits, circuits_count: 5)
    assert_equal 5, switchboard.circuits.count
    
    # Verify all circuits have unique serial numbers between 1 and 36
    serials = switchboard.circuits.pluck(:serial)
    assert_equal serials.uniq, serials, "All circuit serials should be unique"
    assert serials.all? { |s| (1..36).cover?(s) }, "All serials should be between 1 and 36"
  end

end
