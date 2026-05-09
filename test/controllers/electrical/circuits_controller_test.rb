#frozen_string_literal: true

require "test_helper"
require "helpers/controller_test_helper"
module Electrical
  class CircuitsControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers
  include ControllerTestHelper

    setup do
      setup_controller_test
      setup_model_specific_data
    end

    def setup_model_specific_data
      # Create switchboard tag
      @switchboard_tag = create(:tag, prefix: 'EX', serial: 1001, discipline: @discipline)      
      # Create switchboard with the switchboard tag
      @switchboard = create(:electrical_switchboard, tag: @switchboard_tag)      
      # Create circuit for the switchboard 
      @circuit = create(:electrical_circuit, serial: 1, switchboard: @switchboard)
      @resource = @circuit

      # Create switchboard tag on other project
      @other_switchboard_tag = create(:tag, prefix: 'EX', serial: 1001, discipline: @other_discipline)      
      # Create switchboard with the switchboard tag on other project
      @other_switchboard = create(:electrical_switchboard, tag: @other_switchboard_tag)      
      # Create circuit for the switchboard on other project
      @other_circuit = create(:electrical_circuit, serial: 1, switchboard: @other_switchboard)
      @other_resource = @other_circuit

      # Create cable type for the project
      @cable_type = create(:electrical_cable_type, discipline: @discipline)    
      # Create cable tags
      @cable_tag1 = create(:tag, prefix: 'EC', serial: 1001, discipline: @discipline)
      @cable_tag2 = create(:tag, prefix: 'EC', serial: 1002, discipline: @discipline)
      # Create cables with the cable tags
      @cable1 = create(:electrical_cable, tag: @cable_tag1, electrical_cable_type: @cable_type)
      @cable2 = create(:electrical_cable, tag: @cable_tag2, electrical_cable_type: @cable_type)
      # Assign @cable1 as the feeder for @circuit. @cable2 remains unassigned.
      @cable1.update(from: @circuit)
      # Create out of scope cable type and cable
      @other_cable_type = create(:electrical_cable_type, discipline: @other_discipline)
      @other_cable_tag = create(:tag, prefix: 'EC', serial: 1003, discipline: @other_discipline)
      @other_cable = create(:electrical_cable, tag: @other_cable_tag, electrical_cable_type: @other_cable_type)
      
      # Create another switchboard to use as an existing load
      @switchboard2_tag = create(:tag, prefix: 'EX', serial: 1003, discipline: @discipline)
      @switchboard2 = create(:electrical_switchboard, tag: @switchboard2_tag)
      @switchboard2_demand = create(:electrical_demand, basis: 'summation', demandable: @switchboard2)
      # Assign @switchboard2_demand as the load for @circuit, through @cable1
      @cable1.update(to: @switchboard2_demand)
      
      # Create a motor to use as a load assignment
      @motor_tag = create(:tag, prefix: 'EX', serial: 1004, discipline: @discipline)
      @motor = create(:electrical_motor, tag: @motor_tag)
      @motor_demand = create(:electrical_demand, basis: 'summation', demandable: @motor)
    end

    test "model specific setup is valid" do
      assert @switchboard_tag.valid?
      assert @switchboard_tag.persisted?
      assert @switchboard.valid?
      assert @switchboard.persisted?
      assert @circuit.valid?
      assert @circuit.persisted?

      assert @other_switchboard_tag.valid?
      assert @other_switchboard_tag.persisted?
      assert @other_switchboard.valid?
      assert @other_switchboard.persisted?
      assert @other_circuit.valid?
      assert @other_circuit.persisted?
      assert @cable_type.valid?
      assert @cable_type.persisted?

      assert @cable1.valid?
      assert @cable1.persisted?
      assert @cable2.valid?
      assert @cable2.persisted?
      assert @switchboard2.valid?
      assert @switchboard2.persisted?
      assert @switchboard2_demand.valid?
      assert @switchboard2_demand.persisted?

      assert @motor_tag.valid?
      assert @motor_tag.persisted?
      assert @motor.valid?
      assert @motor.persisted?
      assert @motor_demand.valid?
      assert @motor_demand.persisted?

      assert_equal @circuit, @cable1.from
      assert_equal @switchboard2_demand, @cable1.to
      assert_equal @circuit.feeder, @cable1
      assert_equal @circuit.demand, @switchboard2_demand
      assert_nil @motor_demand.incomer
    end


    # Override the delete redirect test
    def test_admin_can_destroy
      sign_in_and_set_project @admin, @project
      assert_difference('Electrical::Circuit.count', -1) do
        delete :destroy, params: { id: @circuit.id }
      end
      # Redirect to project-level index since we're testing that route
      assert_redirected_to electrical_switchboard_circuits_path(@switchboard)
    end

    test "accredited user can create circuit with feeder and demand" do
      sign_in_and_set_project @accredited_user, @project
      new_serial = (@switchboard.circuits.maximum(:serial) || 0) + 1
      assert_difference('Electrical::Circuit.count', 1) do
        post :create, params: new_nesting_params.merge(
          create_params.deep_merge(electrical_circuit: { serial: new_serial })
        ).merge({ electrical_cable: { from_id: @cable2.id, to_id: @motor_demand.id } })
      end
      new_circuit = Electrical::Circuit.find_by(switchboard: @switchboard,
       serial: new_serial)
      assert_equal @cable2, new_circuit.feeder
      assert_equal @motor_demand, new_circuit.demand
      assert_redirected_to new_circuit
      expected_messages = [
        I18n.t('flash.create.notice', resource_name: I18n.t("activerecord.models.electrical.circuit.one")),
        I18n.t('flash.assigned', resource_name: I18n.t("activerecord.attributes.electrical.circuit.feeder")),
        I18n.t('flash.assigned', resource_name: I18n.t("activerecord.attributes.electrical.circuit.demand"))
      ]
      assert_flash_messages :success, expected_messages
    end

    test "accredited user can assign new feeder to circuit" do
      sign_in_and_set_project @accredited_user, @project
      patch :update, params: update_params.merge(id: @circuit.id).merge(
        { electrical_cable: { from_id: @cable2.id } })
      assert_redirected_to @circuit
      expected_messages = [
        I18n.t('flash.update.notice', resource_name: I18n.t("activerecord.models.electrical.circuit.one")),
        I18n.t('flash.assigned', resource_name: I18n.t("activerecord.attributes.electrical.circuit.feeder"))
      ]
      assert_flash_messages :success, expected_messages
    end

    test "accredited user can update feeder and demand to circuit through feeder" do
      sign_in_and_set_project @accredited_user, @project
      patch :update, params: update_params.merge(id: @circuit.id).merge(
        { electrical_cable: { from_id: @cable2.id, to_id: @motor_demand.id } })
      expected_messages = [
        I18n.t('flash.update.notice', resource_name: I18n.t("activerecord.models.electrical.circuit.one")),
        I18n.t('flash.assigned', resource_name: I18n.t("activerecord.attributes.electrical.circuit.feeder")),
        I18n.t('flash.assigned', resource_name: I18n.t("activerecord.attributes.electrical.circuit.demand"))
      ]
      assert_flash_messages :success, expected_messages
      assert_redirected_to @circuit
    end

    test "accredited user cannot assign invalid feeder to circuit" do
      sign_in_and_set_project @accredited_user, @project
      patch :update, params: update_params.merge(id: @circuit.id).merge(
        { electrical_cable: { from_id: @other_cable.id } })
      assert_conflict
    end

    test "accredited user can re-assign feeder to circuit" do
      sign_in_and_set_project @accredited_user, @project
      # set up another circuit - feeder - load
      new_serial = (@switchboard.circuits.maximum(:serial) || 0) + 1
      @new_circuit = create(:electrical_circuit, switchboard: @switchboard, serial: new_serial)
      @cable2.update(from: @new_circuit)
      @cable2.update(to: @motor_demand)
      # Re-assign the @circuit feeder to @cable2
      # This should nullify @cable1 :from
      patch :update, params: update_params.merge(id: @circuit.id).merge(
        { electrical_cable: { from_id: @cable2.id } })
      @cable1.reload
      @cable2.reload
      assert_equal @cable2, @circuit.feeder
      assert_nil @cable1.from
      assert_redirected_to @circuit
      expected_messages = [
        I18n.t('flash.update.notice', resource_name: I18n.t("activerecord.models.electrical.circuit.one")),
        I18n.t('flash.assigned', resource_name: I18n.t("activerecord.attributes.electrical.circuit.feeder"))
      ]
      assert_flash_messages :success, expected_messages
    end

    test "accredited user cannot assign demand without feeder" do
      sign_in_and_set_project @accredited_user, @project
      # set up another circuit with no feeder
      new_serial = (@switchboard.circuits.maximum(:serial) || 0) + 1
      @new_circuit = create(:electrical_circuit, switchboard: @switchboard, serial: new_serial)
      patch :update, params: update_params.merge(
        id: @new_circuit.id).deep_merge(
          electrical_circuit: { serial: new_serial }).merge(
            { electrical_cable: { to_id: @motor_demand.id } })
      assert_template :edit
      assert_response :unprocessable_content
      expected = I18n.t('flash.required', 
        resource_name: I18n.t("activerecord.attributes.electrical.circuit.feeder"))
      assert_flash_message :alert, expected
    end

    test "accredited user can re-assign demand" do
      sign_in_and_set_project @accredited_user, @project
      # Set up another circuit with feeder and demand
      new_serial = (@switchboard.circuits.maximum(:serial) || 0) + 1
      @new_circuit = create(:electrical_circuit, switchboard: @switchboard, serial: new_serial)
      @cable2.update(from: @new_circuit)
      @cable2.update(to: @motor_demand)

      # Assign this already assigned demand to the first circuit. 
      patch :update, params: update_params.merge(id: @circuit.id).merge(
        { electrical_cable: { to_id: @motor_demand.id } })
      @cable1.reload
      @cable2.reload
      assert_equal @circuit.demand, @motor_demand
      assert_nil @cable2.to
      assert_redirected_to @circuit
      expected_messages = [
        I18n.t('flash.update.notice', resource_name: I18n.t("activerecord.models.electrical.circuit.one")),
        I18n.t('flash.assigned', resource_name: I18n.t("activerecord.attributes.electrical.circuit.feeder"))
      ]
      assert_flash_messages :success, expected_messages
    end

    test "accredited user cannot assign demand from out of scope" do
      sign_in_and_set_project @accredited_user, @project
      # Set up an "out of scope" demand
      @motor_tag.update(discipline: @other_discipline)
      patch :update, params: update_params.merge(id: @circuit.id).merge(
        { electrical_cable: { to_id: @motor_demand.id } })
      assert_conflict
    end
    
    private

      # Required for nested routes
      def new_nesting_params
        { switchboard_id: @switchboard.id }
      end

      # Required for nested routes
      def index_nesting_params
        { switchboard_id: @switchboard.id }
      end

      # Set the expected params for a valid resource create
      # Note that the test has already created serial 1 on the switchboard
      def create_params
        { electrical_circuit: 
          {
          serial: 2,
          phase: 'L1',
          device: 'MCB',
          poles: 1,
          curve: 'B',
          rating: 16.0,
          elcb: 'None',
          contactor: true,
          notes: "TEST"
          }
        }
      end
      
      # No read only attributes
      # Tests should modify the created resource, serial must match otherwise it will
      # be an attempt to duplicate a serial number.
      def update_params
        create_params.deep_merge(electrical_circuit: { serial: 1 })
      end

      # Set one invalid resource param for tests
      def invalid_param
        { electrical_circuit: { poles: 0 } }
      end

      # Nominate an attribute to get changed during update tests
      def update_attribute_name
        :poles
      end

      # Nominate a valid value to update the attribute to
      def updated_attribute_value
        6
      end
  end
end