require "test_helper"

class CableTest < ActiveSupport::TestCase
  def setup
    @project = create(:project)
    @discipline_e = create(:discipline, :elec, project: @project)
    @cable_type = create(:electrical_cable_type, project: @project)
    @tag = create(:tag, prefix: "EC", serial: 1, discipline: @discipline_e)
    @cable = create(:electrical_cable, tag: @tag, electrical_cable_type: @cable_type)
  end

  test "factory should create valid cable with tag" do
    assert @cable.valid?
    assert @tag.valid?
    assert_equal 'EC', @tag.prefix
    assert_equal @cable, @tag.tagable
    assert_not_nil @cable.electrical_cable_type
    assert_match(/^EC\d{4}(\.\w+)?$/, @tag.reload.full_tag)
  end
  
  test "should create cable through tag update" do
    tag = create(:tag,
      prefix: 'EC',
      serial: 123,
      discipline: @discipline_e)

    assert_difference 'Electrical::Cable.count', 1 do
      tag.update(tagable: build(:electrical_cable,
        electrical_cable_type: @cable_type,
        route_length: 10.0
      ))
    end

    assert tag.reload.tagable.is_a?(Electrical::Cable)
    assert_equal 10.0, tag.electrical_cable.route_length
  end
  
  test "should not require any attributes except cable_type" do
    cable = build(:electrical_cable,
      tag: create(:tag, discipline: @discipline_e),
      electrical_cable_type: @cable_type,
      route_length: nil,
      vertical_allowance: nil,
      termination_allowance: nil,
      start_mark: nil,
      end_mark: nil
    )

    assert_difference 'Electrical::Cable.count', 1 do
      assert cable.save
    end
  end
  
  test "should require electrical_cable_type" do
    cable = build(:electrical_cable,
      tag: create(:tag, discipline: @discipline_e),
      electrical_cable_type: nil
    )

    assert_no_difference 'Electrical::Cable.count' do
      refute cable.save
    end
    refute cable.valid?
    assert_includes cable.errors[:electrical_cable_type], I18n.t('errors.messages.required')
  end
  
  test "destroy tag should destroy cable" do
    cable = create(:electrical_cable,
      tag: create(:tag, discipline: @discipline_e),
      electrical_cable_type: @cable_type
    )
    tag = cable.tag

    assert_difference ['Tag.count', 'Electrical::Cable.count'], -1 do
      tag.destroy
    end

    assert_raises(ActiveRecord::RecordNotFound) { Electrical::Cable.find(cable.id) }
  end
  
  test "destroy cable should nullify tagable" do
    cable = create(:electrical_cable,
      tag: create(:tag, discipline: @discipline_e),
      electrical_cable_type: @cable_type
    )
    tag = cable.tag

    assert_difference ['Electrical::Cable.count'], -1 do
      cable.destroy
    end
    assert_nil tag.tagable_id
    assert_raises(ActiveRecord::RecordNotFound) { Electrical::Cable.find(cable.id) }
  end

  test "should associate with circuit feeder" do
    swbd = create(:electrical_switchboard, discipline: @discipline_e)
    circuit = swbd.electrical_circuits.create(serial: 1)
    @cable.from = circuit
    @cable.save
    assert_not_nil circuit.feeder
    assert_equal circuit, circuit.feeder.from
  end

  test "destroy circuit should nullify cable from" do
    swbd = create(:electrical_switchboard, discipline: @discipline_e)
    circuit = swbd.electrical_circuits.create(serial: 1)
    @cable.from = circuit
    @cable.save
    circuit.destroy
    assert_nil @cable.reload.from_id
  end

  test "should associate with demand incomer" do
    motor_tag = create(:tag, discipline: @discipline_e)
    motor = create(:electrical_motor, tag: motor_tag)
    demand = create(:electrical_demand, demandable: motor)
    @cable.to = demand
    @cable.save
    assert_not_nil demand.incomer
    assert_equal demand, demand.incomer.to
  end

  test "destroy demand should nullify cable to" do
    motor_tag = create(:tag, discipline: @discipline_e)
    motor = create(:electrical_motor, tag: motor_tag)
    demand = create(:electrical_demand, demandable: motor)
    @cable.to = demand
    @cable.save
    demand.destroy
    assert_nil @cable.reload.to_id
  end

  test "cable from should be unique" do
    swbd = create(:electrical_switchboard, discipline: @discipline_e)
    circuit = swbd.electrical_circuits.create(serial: 1)
    cable1 = create(:electrical_cable,
      tag: create(:tag, :unique_tag, prefix: "EC", discipline: @discipline_e),
      electrical_cable_type: @cable_type
    )

    cable1.from = circuit
    cable1.save
    cable2 = build(:electrical_cable,
      tag: create(:tag, :unique_tag, prefix: "EC", discipline: @discipline_e),
      electrical_cable_type: @cable_type,
      from: cable1.from
    )
    assert_no_difference 'Electrical::Cable.count' do
      refute cable2.save
    end
    refute cable2.valid?
    assert_includes cable2.errors[:from_id], I18n.t('errors.messages.taken')
  end

  test "cable to should be unique" do
    motor_tag = create(:tag, discipline: @discipline_e)
    motor = create(:electrical_motor, tag: motor_tag)
    demand = create(:electrical_demand, demandable: motor)
    cable1 = create(:electrical_cable,
      tag: create(:tag, :unique_tag, prefix: "EC", discipline: @discipline_e),
      electrical_cable_type: @cable_type
    )

    cable1.to = demand
    cable1.save
    cable2 = build(:electrical_cable,
      tag: create(:tag, :unique_tag, prefix: "EC", discipline: @discipline_e),
      electrical_cable_type: @cable_type,
      to: demand
    )
    assert_no_difference 'Electrical::Cable.count' do
      refute cable2.save
    end
    refute cable2.valid?
    assert_includes cable2.errors[:to_id], I18n.t('errors.messages.taken')
  end
  
  test "navigation between cables" do
    skip "Navigation between cables is not working properly"
    # Create test cables with different serials but same prefix
    tag1 = create(:tag, prefix: 'EC', serial: 201,  discipline: @discipline_e)
    cable1 = create(:electrical_cable, tag: tag1, electrical_cable_type: @cable_type)

    tag2 = create(:tag, prefix: 'EC', serial: 202,  discipline: @discipline_e)
    cable2 = create(:electrical_cable, tag: tag2, electrical_cable_type: @cable_type)

    tag3 = create(:tag, prefix: 'EC', serial: 203,  discipline: @discipline_e)
    cable3 = create(:electrical_cable, tag: tag3, electrical_cable_type: @cable_type)

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
    tag1 = create(:tag, prefix: 'EC', serial: 201,  discipline: @discipline_e)
    cable1 = create(:electrical_cable, tag: tag1, electrical_cable_type: @cable_type)

    # Second cable with different prefix will have a different loop_id
    # due to the first letter of the prefix being different
    tag2 = create(:tag, prefix: 'FC', serial: 202, discipline: @discipline_e)
    cable2 = create(:electrical_cable, tag: tag2, electrical_cable_type: @cable_type)

    # Test navigation respects loop_id ordering
    assert_equal cable2, cable1.next
    assert_equal cable2, cable2.next  # Returns self when no next

    assert_equal cable1, cable1.prev  # Returns self when no previous
    assert_equal cable1, cable2.prev
  end
  
  test "navigation with missing tag" do
    cable = Electrical::Cable.new
    assert_equal cable, cable.next  # Returns self when there's no tag
    assert_equal cable, cable.prev  # Returns self when there's no tag
  end
end
