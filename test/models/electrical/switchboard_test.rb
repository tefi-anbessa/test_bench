# frozen_string_literal: true
require "test_helper"
require 'helpers/tagable_model_tests'

module Electrical
  class SwitchboardTest < ActiveSupport::TestCase
    include TagableModelTests

    def setup
      setup_common_test_data
      @resource.electrical_demand = create(:electrical_demand, demandable: @resource)
      @circuit = create(:electrical_circuit, switchboard: @resource)
    end

    test "circuit setup must be valid" do
      assert @circuit.valid?
      assert_equal @resource.circuits.count, 1
      assert_equal @resource, @circuit.switchboard
    end

    test "voltage rating must be present" do
      @resource.voltage_rating = nil
      refute @resource.valid?
      assert_includes @resource.errors[:voltage_rating], I18n.t("errors.messages.blank")
    end

    test "busbar rating must be present" do
      @resource.busbar_rating = nil
      refute @resource.valid?
      assert_includes @resource.errors[:busbar_rating], I18n.t("errors.messages.blank")
    end

    test "switchboard label should be tag label" do
      assert_equal @resource.label, @tag.label
      assert_equal @resource.long_label, @tag.long_label
    end

    test "should create switchboard with custom tag attributes" do
      switchboard = nil
      assert_difference ['Electrical::Switchboard.count', 'Tag.count'], 1 do
        switchboard = create(:electrical_switchboard,
          ingress_protection: '22'
        )
      end
      # Check factory default prefix
      assert_equal '22', switchboard.ingress_protection
    end

    test "should create new switchboard through tag update" do
      tag = create(:tag,
        prefix: 'EX',
        serial: 5,
        suffix: "X",
        stage: 9,
        discipline: @resource_discipline
      )

      assert_difference 'Electrical::Switchboard.count', 1 do
        tag.update(tagable: create(:electrical_switchboard, tag: tag,
          ingress_protection: '22'
        ))
      end

      assert tag.tagable.class == Electrical::Switchboard
      assert_equal '22', tag.tagable.ingress_protection
    end

    test "destroy switchboard should destroy associated circuits" do
      # Destroy the switchboard and verify the circuit is also destroyed
      assert_difference 'Electrical::Circuit.count', -1 do
        @resource.destroy
      end
      # Verify the circuit was destroyed
      assert_raises(ActiveRecord::RecordNotFound) { @circuit.reload }
    end

    # Circuit tests
    test "should create switchboard with specified number of circuits" do
      switchboard = create(:electrical_switchboard, :with_circuits, circuits_count: 5)
      assert_equal 5, switchboard.circuits.count

      # Verify all circuits have unique serial numbers between 1 and 36
      serials = switchboard.circuits.pluck(:serial)
      assert_equal serials.uniq, serials, "All circuit serials should be unique"
      assert serials.all? { |s| (1..36).cover?(s) }, "All serials should be between 1 and 36"
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
      test_serial = create(:electrical_circuit, switchboard: @resource, serial: 35)

      # Try to create another circuit with the same serial on the same switchboard
      duplicate_circuit = build(:electrical_circuit, switchboard: @resource, serial: test_serial.serial)
      refute duplicate_circuit.valid?
      assert_includes duplicate_circuit.errors[:serial], I18n.t('errors.messages.taken')

      # Should allow same serial on a different switchboard
      other_tag = create(:tag, discipline: @resource_discipline)
      other_switchboard = create(:electrical_switchboard, tag: other_tag)
      other_circuit = build(:electrical_circuit, switchboard: other_switchboard, serial: test_serial.serial)
      assert other_circuit.valid?
    end

    test "destroy circuit should nullify cable feeder reference" do
      circuit = create(:electrical_circuit, switchboard: @resource)
      cable_tag = create(:tag, discipline: @resource_discipline, prefix: "EC")
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
      circuits = create_list(:electrical_circuit, 3, switchboard: @resource)
      
      # Get all serial numbers and ensure they're unique
      serials = circuits.map(&:serial)
      assert_equal serials.uniq, serials, "Expected all serial numbers to be unique"
      
      # All serials should be between 1 and 36
      assert serials.all? { |s| (1..36).cover?(s) }, "All serials should be between 1 and 36"
    end
  end
end
