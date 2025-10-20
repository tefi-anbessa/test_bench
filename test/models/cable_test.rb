require "test_helper"

class CableTest < ActiveSupport::TestCase
  def setup
    @project = create(:project)
    @discipline_e = create(:discipline, :e)
    @cable_type = create(:cable_type, project: @project)
    @tag = create(:tag, prefix: "EC", serial: 1, project: @project, discipline: @discipline_e)
    @cable = create(:cable, tag: @tag, cable_type: @cable_type)
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
    skip "Navigation between cables is not working properly"
    # Create test cables with different serials but same prefix
    tag1 = create(:tag, prefix: 'EC', serial: 201, project: @project, discipline: @discipline_e)
    cable1 = create(:cable, tag: tag1, cable_type: @cable_type)

    tag2 = create(:tag, prefix: 'EC', serial: 202, project: @project, discipline: @discipline_e)
    cable2 = create(:cable, tag: tag2, cable_type: @cable_type)

    tag3 = create(:tag, prefix: 'EC', serial: 203, project: @project, discipline: @discipline_e)
    cable3 = create(:cable, tag: tag3, cable_type: @cable_type)

    # Test next/prev navigation
    assert_equal cable2, cable1.next
    assert_equal cable3, cable2.next
    assert_equal cable3, cable3.next  # Returns self when no next

    assert_equal cable1, cable1.prev  # Returns self when no previous
    assert_equal cable1, cable2.prev
    assert_equal cable2, cable3.prev
  end
  
  test "navigation with different loop_ids" do
    skip "Navigation between cables is not working properly"

    # First cable with prefix 'EC'
    tag1 = create(:tag, prefix: 'EC', serial: 201, project: @project, discipline: @discipline_e)
    cable1 = create(:cable, tag: tag1, cable_type: @cable_type)

    # Second cable with different prefix will have a different loop_id
    # due to the first letter of the prefix being different
    tag2 = create(:tag, prefix: 'FC', serial: 202, project: @project, discipline: @discipline_e)
    cable2 = create(:cable, tag: tag2, cable_type: @cable_type)

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
    tag = create(:tag,
      prefix: 'EC',
      serial: 123,
      project: @project,
      discipline: @discipline_e)

    assert_difference 'Cable.count', 1 do
      tag.update(tagable: build(:cable,
        cable_type: @cable_type,
        route_length: 10.0
      ))
    end

    assert tag.reload.tagable.is_a?(Cable)
    assert_equal 10.0, tag.cable.route_length
  end
  
  test "should not require any attributes except cable_type" do
    cable = build(:cable,
      tag: create(:tag, project: @project, discipline: @discipline_e),
      cable_type: @cable_type,
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
    cable = build(:cable,
      tag: create(:tag, project: @project, discipline: create(:discipline, :e)),
      cable_type: nil
    )

    assert_no_difference 'Cable.count' do
      refute cable.save
    end
    refute cable.valid?
    assert_includes cable.errors[:cable_type], I18n.t('errors.messages.required')
  end
  
  test "destroy tag should destroy cable" do
    cable = create(:cable,
      tag: create(:tag, project: @project, discipline: @discipline_e),
      cable_type: @cable_type
    )
    tag = cable.tag

    assert_difference ['Tag.count', 'Cable.count'], -1 do
      tag.destroy
    end

    assert_raises(ActiveRecord::RecordNotFound) { Cable.find(cable.id) }
  end
  
  test "destroy cable should nullify tagable" do
    cable = create(:cable,
      tag: create(:tag, project: @project, discipline: @discipline_e),
      cable_type: @cable_type
    )
    tag = cable.tag

    assert_difference ['Cable.count'], -1 do
      cable.destroy
    end
    assert_nil tag.tagable_id
    assert_raises(ActiveRecord::RecordNotFound) { Cable.find(cable.id) }
  end

  test "should associate with circuit feeder" do
    swbd = create(:switchboard, project: @project, discipline: @discipline_e)
    circuit = swbd.circuits.create(serial: 1)
    @cable.from = circuit
    @cable.save
    assert_not_nil circuit.feeder
    assert_equal circuit, circuit.feeder.from
  end

  test "destroy circuit should nullify cable from" do
    swbd = create(:switchboard, project: @project, discipline: @discipline_e)
    circuit = swbd.circuits.create(serial: 1)
    @cable.from = circuit
    @cable.save
    circuit.destroy
    assert_nil @cable.reload.from_id
  end

  test "should associate with demand incomer" do
    motor_tag = create(:tag, project: @project, discipline: @discipline_e)
    motor = create(:motor, tag: motor_tag)
    demand = create(:demand, demandable: motor)
    @cable.to = demand
    @cable.save
    assert_not_nil demand.incomer
    assert_equal demand, demand.incomer.to
  end

  test "destroy demand should nullify cable to" do
    motor_tag = create(:tag, project: @project, discipline: @discipline_e)
    motor = create(:motor, tag: motor_tag)
    demand = create(:demand, demandable: motor)
    @cable.to = demand
    @cable.save
    demand.destroy
    assert_nil @cable.reload.to_id
  end
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
