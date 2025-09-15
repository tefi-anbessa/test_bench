require "test_helper"

class SwitchboardTest < ActiveSupport::TestCase
  def setup
    @switchboard = create(:switchboard)
    @tag = @switchboard.tag
  end

  test "factory should create valid switchboard with tag" do
    assert @switchboard.valid?
    assert @tag.valid?
    # Explicitly set the prefix to EX for the test
    @tag.update(prefix: 'EX')
    assert_equal 'EX', @tag.reload.prefix
    assert_equal @switchboard, @tag.tagable
  end

  test "should create switchboard with custom tag attributes" do
    project = create(:project, title: 'Test Project')
    
    switchboard = nil
    assert_difference ['Switchboard.count', 'Tag.count'], 1 do
      switchboard = create(:switchboard, :with_tag,
        location: 'Gatehouse',
        ingress_protection: 'IP22'
      )
      # Explicitly set the prefix after creation
      switchboard.tag.update(prefix: 'EX')
    end
    
    assert_match(/E:EX-\d+\.?\w*/, switchboard.tag.reload.full_tag)
    assert_equal 'Gatehouse', switchboard.location
    assert_equal 'IP22', switchboard.ingress_protection
    assert_equal 'EX', switchboard.tag.prefix
  end
  
  test "should create switchboard through tag update" do
    project = create(:project)
    discipline = Discipline.find_or_create_by(code: 'E') do |d|
      d.name = 'Electrical' if d.new_record?
    end
    
    tag = create(:tag,
      prefix: 'EX',
      serial: 5,
      project: project,
      discipline: discipline
    )
    
    assert_difference 'Switchboard.count', 1 do
      tag.update(tagable: build(:switchboard,
        location: 'Gatehouse',
        ingress_protection: 'IP22'
      ))
    end
    
    assert tag.reload.tagable.is_a?(Switchboard)
    assert_equal 'Gatehouse', tag.tagable.location
    assert_equal 'IP22', tag.tagable.ingress_protection
  end

  test "destroy switchboard should nullify tagable" do
    @switchboard.destroy
    @tag.reload
    assert_nil @tag.tagable
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
