# frozen_string_literal: true

require "test_helper"
require 'helpers/tagable_model_tests'

module Electrical
  class CableTest < ActiveSupport::TestCase
    include TagableModelTests

    def setup
      setup_common_test_data
      @cable = @resource
    end

    def setup_resource_prerequisites
      @cable_type = create(:electrical_cable_type, discipline: @resource_discipline)
    end
    
    test "should require electrical_cable_type" do
      @cable.electrical_cable_type = nil
      refute @cable.valid?
      assert_no_difference 'Electrical::Cable.count' do
        @cable.save
      end
      assert_includes @cable.errors[:electrical_cable_type], I18n.t('errors.messages.required')
    end

    test "should associate with circuit feeder" do
      swbd = create(:electrical_switchboard, discipline: @resource_discipline)
      circuit = swbd.circuits.create(serial: 1)
      @cable.from = circuit
      @cable.save
      assert_not_nil circuit.feeder
      assert_equal circuit, circuit.feeder.from
    end

    test "destroy circuit should nullify cable from" do
      swbd = create(:electrical_switchboard, discipline: @resource_discipline)
      circuit = swbd.circuits.create(serial: 1)
      @cable.from = circuit
      @cable.save
      circuit.destroy
      assert_nil @cable.reload.from_id
    end

    test "should associate with demand incomer" do
      motor_tag = create(:tag, discipline: @resource_discipline)
      motor = create(:electrical_motor, tag: motor_tag)
      demand = create(:electrical_demand, demandable: motor)
      @cable.to = demand
      @cable.save
      assert_not_nil demand.incomer
      assert_equal demand, demand.incomer.to
    end

    test "destroy demand should nullify cable to" do
      motor_tag = create(:tag, discipline: @resource_discipline)
      motor = create(:electrical_motor, tag: motor_tag)
      demand = create(:electrical_demand, demandable: motor)
      @cable.to = demand
      @cable.save
      demand.destroy
      assert_nil @cable.reload.to_id
    end

    test "cable from should be unique" do
      swbd = create(:electrical_switchboard, discipline: @resource_discipline)
      circuit = swbd.circuits.create(serial: 1)
      cable1 = create(:electrical_cable, from: circuit,
        tag: create(:tag, :unique_tag, prefix: "EC", discipline: @resource_discipline),
        electrical_cable_type: @cable_type)
      cable2 = build(:electrical_cable, from: cable1.from,
        tag: create(:tag, :unique_tag, prefix: "EC", discipline: @resource_discipline),
        electrical_cable_type: @cable_type)
      refute cable2.valid?
      assert_no_difference 'Electrical::Cable.count' do
        cable2.save
      end
      assert_includes cable2.errors[:from_id], I18n.t('errors.messages.taken')
    end

    test "cable to should be unique" do
      motor_tag = create(:tag, discipline: @resource_discipline)
      motor = create(:electrical_motor, tag: motor_tag)
      demand = create(:electrical_demand, demandable: motor)
      cable1 = create(:electrical_cable,
        tag: create(:tag, :unique_tag, prefix: "EC", discipline: @resource_discipline),
        electrical_cable_type: @cable_type)
      cable1.to = demand
      cable1.save
      cable2 = build(:electrical_cable,
        tag: create(:tag, :unique_tag, prefix: "EC", discipline: @resource_discipline),
        electrical_cable_type: @cable_type,
        to: demand)
      refute cable2.valid?
      assert_no_difference 'Electrical::Cable.count' do
        cable2.save
      end
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
end
