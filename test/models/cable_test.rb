require "test_helper"

class CableTest < ActiveSupport::TestCase
  def setup
    @project = create(:project)
    @cable_type = create(:cable_type, project: @project)
    @cable = create(:cable, cable_type: @cable_type)
    @tag = @cable.tag # Cable factory defaults cable tag to "E:EC-NNNN"
  end

  test "factory should create valid cable with tag" do
    assert @cable.valid?
    assert @tag.valid?
    assert_equal 'EC', @tag.prefix
    assert_equal @cable, @tag.tagable
    assert_not_nil @cable.cable_type
    assert_match(/^E:EC-\d{4}(\.\w+)?$/, @tag.reload.full_tag)
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
    cable_type = create(:cable_type)
    
    tag = create(:tag,
      prefix: 'EC',
      serial: 123,
      project: project,
      discipline: create(:discipline, code: 'E', name: 'Electrical')
    )
    
    assert_difference 'Cable.count', 1 do
      tag.update(tagable: build(:cable,
        cable_type: cable_type,
        route_length: 10.0
      ))
    end
    
    assert tag.reload.tagable.is_a?(Cable)
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
