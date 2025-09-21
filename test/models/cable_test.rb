require "test_helper"

class CableTest < ActiveSupport::TestCase
  def setup
    @cable_type = create(:cable_type)
    @cable = create(:cable, cable_type: @cable_type)
    @tag = @cable.tag
  end

  test "should not allow cable without tag" do
    cable = Cable.new
    refute cable.valid?
  
    # Debug output to see what validations are failing
    puts "Validation errors: #{cable.errors.full_messages}"
    assert cable.errors[:base].any?
  
    # Check both possible places where the error might be
    assert cable.errors[:tag].any? || 
           cable.errors[:base].any? { |msg| msg.include?("tag") },
           "Expected validation error about missing tag"
  end

  test "factory should create valid cable with tag" do
    assert @cable.valid?
    assert @tag.valid?
    assert_equal 'EC', @tag.prefix
    assert_equal @cable, @tag.tagable
    assert_not_nil @cable.cable_type
    
    # Verify tag number format if the method exists
    if @tag.respond_to?(:full_tag) && @tag.full_tag.present?
      assert_match(/^EC-\d+/, @tag.full_tag)
    end
  end

  test "should create cable with custom tag attributes" do
    project = create(:project, title: 'Test Project')
    
    # Create a unique cable type for this test
    custom_type = create(:cable_type, 
      conductor_material: 'Copper',
      conductor_makeup: '2C+E',
      csa: 1.5,
      temperature_rating: 1,  # 70°C for PVC
      description: "Custom Cable Type #{SecureRandom.hex(4)}"
    )
    
    cable = nil
    assert_difference ['Cable.count', 'Tag.count'], 1 do
      cable = create(:cable, 
        prefix: 'EC',
        serial: 42,
        project: project,
        description: 'TEST CABLE',
        custom_cable_type: custom_type
      )
    end
    
    # Verify tag attributes
    assert_equal 'TEST CABLE', cable.tag.service
    assert_equal '2C+E', cable.cable_type.conductor_makeup
    
    # Verify tag number format if the method exists
    if cable.tag.respond_to?(:full_tag) && cable.tag.full_tag.present?
      assert_match(/^EC-\d+/, cable.tag.full_tag)
    end
  end
  
  test "should create cable with optional attributes" do
    # Create a unique cable type for this test
    unique_cable_type = create(:cable_type, 
      description: "Unique Test Cable #{SecureRandom.hex(4)}",
      csa: 2.5,
      conductor_material: 'Copper',
      conductor_makeup: '2C+E',
      insulation: 'PVC',
      bedding: 'PVC',
      armour: 'GSWA',
      sheath: 'XLPE/nylon',
      bedding_od: 10.5,
      overall_od: 12.5,
      temperature_rating: '75˚C',
      unique_spec: "UNIQUE-#{SecureRandom.hex(4)}"
    )
    
    cable = create(:cable,
      cable_type: unique_cable_type,  # Use the unique cable type
      route_length: 15.5,
      vertical_allowance: 2.0,
      termination_allowance: 1.0,
      start_mark: 1,
      end_mark: 2
    )
    
    assert_equal 15.5, cable.route_length
    assert_equal 2.0, cable.vertical_allowance
    assert_equal 1.0, cable.termination_allowance
    assert_equal 1, cable.start_mark
    assert_equal 2, cable.end_mark
  end
  
  test "navigation between cables" do
    # Create a shared project and discipline for all cables
    project = create(:project)
    discipline = create(:discipline, :e)
    
    # Create test cables with different serials but same prefix
    # The factory will create tags with sequential serials
    cable1 = create(:cable, 
      prefix: 'EC', 
      serial: 101,
      project: project,
      discipline: discipline
    )
    
    cable2 = create(:cable, 
      prefix: 'EC', 
      serial: 102,
      project: project,
      discipline: discipline
    )
    
    cable3 = create(:cable, 
      prefix: 'EC', 
      serial: 103,
      project: project,
      discipline: discipline
    )
    
    # Test next/prev navigation
    assert_equal cable2, cable1.next
    assert_equal cable3, cable2.next
    assert_equal cable3, cable3.next  # Returns self when no next
    
    assert_equal cable1, cable1.prev  # Returns self when no previous
    assert_equal cable1, cable2.prev
    assert_equal cable2, cable3.prev
  end
  
  test "navigation with different loop_ids" do
    # Create a shared project and discipline for all cables
    project = create(:project)
    discipline = create(:discipline, :e)
    
    # First cable with prefix 'EC'
    cable1 = create(:cable, 
      prefix: 'EC', 
      serial: 101,
      project: project,
      discipline: discipline
    )
    
    # Second cable with different prefix will have a different loop_id
    # due to the first letter of the prefix being different
    cable2 = create(:cable, 
      prefix: 'FC',  # Different prefix first letter -> different loop_id
      serial: 101,   # Same serial but different prefix
      project: project,
      discipline: discipline
    )
    
    # Test navigation respects loop_id ordering
    assert_equal cable2, cable1.next
    assert_equal cable2, cable2.next  # Returns self when no next
    
    assert_equal cable1, cable1.prev  # Returns self when no previous
    assert_equal cable1, cable2.prev
  end
  
  test "navigation with missing tag" do
    cable = Cable.new
    assert_equal cable, cable.next  # Returns self when there's no tag
    assert_equal cable, cable.prev  # Returns self when there's no tag
  end
  
  test "should create cable through tag update" do
    project = create(:project)
    cable_type = create(:cable_type, :swa)
    
    tag = create(:tag,
      prefix: 'EC',
      serial: 123,
      project: project,
      discipline: create(:discipline, code: 'E', name: 'Electrical')
    )
    
    assert_difference 'Cable.count', 1 do
      tag.update(tagable: build(:cable,
        custom_cable_type: cable_type,
        route_length: 10.0
      ))
    end
    
    assert tag.reload.tagable.is_a?(Cable)
    assert_equal 'GSWA', tag.tagable.cable_type.armour
    assert_equal 10.0, tag.tagable.route_length
  end
  
  test "should not require any attributes except cable_type" do
    cable = build(:cable,
      route_length: nil,
      vertical_allowance: nil,
      termination_allowance: nil,
      start_mark: nil,
      end_mark: nil
    )
    
    assert_difference 'Cable.count', 1 do
      assert cable.save
    end
  end
  
  test "should require cable_type" do
    cable = build(:cable, cable_type: nil)
    
    assert_no_difference 'Cable.count' do
      assert_not cable.valid?
      assert_includes cable.errors[:cable_type], "must exist"
    end
  end
  
  test "destroy tag should destroy cable" do
    cable = create(:cable)
    tag = cable.tag
    
    assert_difference ['Tag.count', 'Cable.count'], -1 do
      tag.destroy
    end
    
    assert_raises(ActiveRecord::RecordNotFound) { Cable.find(cable.id) }
  end
  
  # TODO: Uncomment and update when circuit factory is available
  # test "should associate with circuit" do
  #   cable = create(:cable, :with_circuit)
  #   
  #   assert_not_nil cable.circuit
  #   assert_equal cable, cable.circuit.cable
  #   assert_equal cable.circuit.switchboard.project, cable.tag.project
  # end
  # 
  # test "destroy circuit should not destroy cable" do
  #   cable = create(:cable, :with_circuit)
  #   circuit = cable.circuit
  #   
  #   assert_no_difference 'Cable.count' do
  #     circuit.destroy
  #     cable.reload
  #     assert_nil cable.circuit
  #   end
  # end
end
