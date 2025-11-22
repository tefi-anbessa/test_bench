require 'test_helper'
module Electrical
  class CircuitsControllerTest < ActionController::TestCase
    include Devise::Test::ControllerHelpers

    setup do

      @project = create(:project)
      # Set the current project for all tests that need it
      set_current_project(@project) if defined?(set_current_project)
      # Out of scope project
      @other_project = create(:project)

      @discipline = create(:discipline, project: @project, code: :elec, label: "E", name: 'Electrical')
      @other_discipline = create(:discipline, project: @other_project)

      @admin = create(:user)
      @admin.grant(:admin)

      @project_manager = create(:user)
      @project_manager.grant(:project_manager, @project) # Project manager role

      @team_member = create(:user)
      @team_member.grant(:team_member, @project) # Project team member role

      @electrical_designer = create(:user)
      @electrical_designer.grant(:electrical_designer) # Global electrical designer role
      @electrical_designer.grant(:team_member, @project) # Project team member role

      @regular_user = create(:user)   # No roles
      
      # Create tags
      @swbd_tag = create(:tag, prefix: 'EX', serial: 1001, discipline: @discipline)
      @swbd_tag2 = create(:tag, prefix: 'EX', serial: 1002, discipline: @discipline)
      
      # Create switchboard with the switchboard tag
      @switchboard = create(:electrical_switchboard, tag: @swbd_tag)
      @swbd2 = create(:electrical_switchboard, tag: @swbd_tag2)
      
      # Create circuit for the switchboard 
      @circuit = create(:electrical_circuit, electrical_switchboard: @switchboard)

      # Create cable type for the project
      @cable_type = create(:electrical_cable_type, project: @project)    
      # Create tags
      @cable_tag1 = create(:tag, prefix: 'EC', serial: 1001, discipline: @discipline)
      @cable_tag2 = create(:tag, prefix: 'EC', serial: 1002, discipline: @discipline)
          
      # Create cables with the cable tags
      @cable1 = create(:electrical_cable, tag: @cable_tag1, electrical_cable_type: @cable_type)
      @cable2 = create(:electrical_cable, tag: @cable_tag2, electrical_cable_type: @cable_type)

      # Create another switchboard to use as a load
      @swbd_tag3 = create(:tag, prefix: 'EX', serial: 1003, discipline: @discipline)
      @swbd3 = create(:electrical_switchboard, tag: @swbd_tag3)
      @swbd3_demand = create(:electrical_demand, demandable: @swbd3)

      @request.env["devise.mapping"] = Devise.mappings[:user]
    end

    # Index action tests
    test "unauthenticated users should be redirected to sign in" do
      get :index, params: { switchboard_id: @switchboard.id } 
      assert_unauthenticated
    end

    test "regular user cannot get index" do
      sign_in @regular_user
      get :index, params: { switchboard_id: @switchboard.id }
      assert_forbidden
    end

    test "should get index for user with role on current project" do
      sign_in @team_member
      get :index, params: { switchboard_id: @switchboard.id }
      assert_response :success
    end

    # Show action tests
    test "user cannot view circuit details without a project role" do
      sign_in @regular_user
      get :show, params: { id: @circuit.id }
      assert_forbidden
    end

    test "team member can view project circuit details" do
      sign_in @team_member
      get :show, params: { id: @circuit.id }
      assert_response :success
    end

    # New action tests
    test "team member cannot access new circuit form" do
      sign_in @team_member
      get :new, params: { switchboard_id: @switchboard.id }
      assert_forbidden
    end

    test "electrical designer can access new circuit form for existing switchboard" do
      sign_in @electrical_designer
      get :new, params: { switchboard_id: @switchboard.id }
      assert_response :success
    end

    # Create action tests
    # Fail to create
    test "team member cannot create circuit" do
      sign_in @team_member
      assert_difference('Electrical::Circuit.count', 0) do
        post :create, params: {
          switchboard_id: @switchboard.id,
          electrical_circuit: {
            serial: 9
          }
        }
      end
      assert_forbidden
    end

    test "electrical designer can create circuit" do
      sign_in @electrical_designer
      new_serial = (@switchboard.electrical_circuits.maximum(:serial) || 0) + 1  
      assert_difference('Electrical::Circuit.count', 1) do
        post :create, params: {
          switchboard_id: @switchboard.id,
          electrical_circuit: {
            serial: new_serial,
            phase: "L1",
            device: "MCCB",
            poles: 4,
            curve: "C",
            rating: 32,
            elcb: "other",
            contactor: false,
            notes: "CIRCUIT NOTES"
          }
        }
      end
      new_circuit = Electrical::Circuit.find_by(electrical_switchboard: @switchboard,
       serial: new_serial)
      assert_redirected_to new_circuit
      expected = I18n.t('flash.actions.create.notice', resource_name: Electrical::Circuit.model_name.human)
      assert_flash_message :success, expected
    end

    test "electrical designer can create circuit with feeder and demand" do
      sign_in @electrical_designer
      new_serial = (@switchboard.electrical_circuits.maximum(:serial) || 0) + 1
      assert_difference('Electrical::Circuit.count', 1) do
        post :create, params: {
          switchboard_id: @switchboard.id,
          electrical_circuit: {
            serial: new_serial,
            phase: "L1",
            device: "MCCB",
            poles: 4,
            curve: "C",
            rating: 32,
            elcb: "other",
            contactor: false,
            notes: "CIRCUIT NOTES"
          },
          cable: {
            from_id: @cable1.id,
            to_id: @swbd3_demand.id
          }
        }
      end
      new_circuit = Electrical::Circuit.find_by(electrical_switchboard: @switchboard,
       serial: new_serial)
      assert_equal @cable1, new_circuit.feeder
      assert_equal @swbd3_demand, new_circuit.demand
      assert_redirected_to new_circuit
      expected_messages = [
        I18n.t('flash.actions.create.notice', resource_name: Electrical::Circuit.model_name.human),
        I18n.t('flash.assigned', resource_name: Electrical::Circuit.human_attribute_name(:feeder)),
        I18n.t('flash.assigned', resource_name: Electrical::Circuit.human_attribute_name(:demand))
      ]
      assert_flash_messages :success, expected_messages
    end

    # Edit action tests
    test "team member cannot access edit circuit form" do
      sign_in @team_member
      get :edit, params: { id: @circuit.id }
      assert_forbidden
    end

    test "electrical designer can access edit circuit form" do
      sign_in @electrical_designer
      get :edit, params: { id: @circuit.id }
      assert_response :success
    end

    # Update action tests
    test "team member cannot update circuit" do
      sign_in @team_member
      patch :update, params: { 
        id: @circuit.id,
        electrical_circuit: { serial: 3 }
      }
      assert_forbidden
    end

    test "electrical designer can update circuit" do
      sign_in @electrical_designer
      patch :update, params: { 
        id: @circuit.id,
        electrical_circuit: {serial: @circuit.serial + 1}
      }
      assert_redirected_to @circuit
      expected = I18n.t('flash.actions.update.notice', resource_name: Electrical::Circuit.model_name.human)
      assert_flash_message :success, expected
    end

    # Destroy action tests
    test "electrical designer cannot destroy circuit" do
      sign_in @electrical_designer
      assert_no_difference('Electrical::Circuit.count') do
        delete :destroy, params: { id: @circuit.id }
      end
      assert_forbidden
    end

    test "admin can destroy circuit" do
      sign_in @admin
      switchboard = @circuit.electrical_switchboard
      assert_difference('Electrical::Circuit.count', -1) do
        delete :destroy, params: { id: @circuit.id }
      end
      assert_redirected_to electrical_switchboard_circuits_path(switchboard)
      expected = I18n.t('flash.actions.destroy.notice', resource_name: Electrical::Circuit.model_name.human)
      assert_flash_message :success, expected
    end

    test "electrical designer can assign feeder to circuit" do
      sign_in @electrical_designer
      patch :update, params: { 
        id: @circuit.id,
        cable: {from_id: @cable1.id},
        electrical_circuit: {notes: "TEST assign feeder"}
      }
      assert_redirected_to @circuit
      expected = I18n.t('flash.assigned', resource_name: Electrical::Circuit.human_attribute_name(:feeder))
      assert_flash_message :success, expected
    end

    test "electrical designer can assign feeder and demand to circuit through feeder" do
      sign_in @electrical_designer
      patch :update, params: { 
        id: @circuit.id,
        electrical_circuit: { notes: "TEST assign feeder and demand to circuit" },
        cable: { from_id: @cable1.id, to_id: @swbd3_demand.id }
      }
      expected_messages = [
        I18n.t('flash.actions.update.notice', resource_name: Electrical::Circuit.model_name.human),
        I18n.t('flash.assigned', resource_name: Electrical::Circuit.human_attribute_name(:feeder)),
        I18n.t('flash.assigned', resource_name: Electrical::Circuit.human_attribute_name(:demand))
      ]
      assert_flash_messages :success, expected_messages
      assert_redirected_to @circuit
    end

    test "electrical designer cannot assign invalid feeder to circuit" do
      sign_in @electrical_designer
      # Set up an "out of scope" cable
      @project2 = create(:project)
      @cable3 = create(:electrical_cable, project: @project2)
      patch :update, params: { 
        id: @circuit.id,
        cable: {from_id: @cable3.id},
        electrical_circuit: {notes: "TEST invalid feeder"}
      }
      assert_redirected_to @circuit
      expected = I18n.t('flash.not_found', resource_name: Electrical::Circuit.human_attribute_name(:feeder))
      assert_flash_message :alert, expected
    end

    test "electrical designer cannot assign already assigned feeder to circuit" do
      sign_in @electrical_designer

      # set up an existing circuit - feeder - load
      @circuit2 = create(:electrical_circuit, electrical_switchboard: @switchboard, serial: 2)
      @cable2.update(from: @circuit2)
      @cable2.update(to: @swbd3_demand)
      
      # Try to assign the feeder which is already assigned to another circuit
      patch :update, params: { 
        id: @circuit.id,
        cable: {from_id: @cable2.id},
        electrical_circuit: {notes: "TEST already assigned feeder"}
      }
      assert_redirected_to @circuit
      expected = I18n.t('flash.already_assigned', resource_name: Electrical::Circuit.human_attribute_name(:feeder))
      assert_flash_message :alert, expected
    end

    test "electrical designer cannot assign demand without feeder" do
      sign_in @electrical_designer
      patch :update, params: { 
        id: @circuit.id,
        cable: {to_id: @swbd3_demand.id},
        electrical_circuit: {notes: "TEST cannot assign demand without feeder"}
      }
      assert_redirected_to @circuit
      expected = I18n.t('flash.required', resource_name: Electrical::Circuit.human_attribute_name(:feeder))
      assert_flash_message :alert, expected
    end

    test "electrical designer cannot assign already assigned demand" do
      sign_in @electrical_designer

      # Set up existing circuit with feeder and demand
      @circuit2 = create(:electrical_circuit, electrical_switchboard: @switchboard, serial: 2)
      @cable2.update(from: @circuit2)
      @cable2.update(to: @swbd3_demand)

      # Set up feeder on our test circuit
      @cable1.update(from: @circuit)

      # Try to assign the same demand - should fail
      patch :update, params: { 
        id: @circuit.id,
        cable: {to_id: @swbd3_demand.id},
        electrical_circuit: {notes: "TEST already assigned demand"}
      }
      assert_redirected_to @circuit
      expected = I18n.t('flash.already_assigned', resource_name: Circuit.human_attribute_name(:demand))
      assert_flash_message :alert, expected
    end

    test "electrical designer cannot assign demand from out of scope" do
      sign_in @electrical_designer
      # Set up an "out of scope" demand
      @swbd_tag3.update(discipline: @other_discipline)
      # Set up feeder on the test circuit
      @cable1.update(from: @circuit)
      patch :update, params: { 
        id: @circuit.id,
        cable: {to_id: @swbd3_demand.id},
        electrical_circuit: {notes: "TEST demand from out of scope"}
      }
      assert_redirected_to @circuit
      expected = I18n.t('flash.not_found', resource_name: Electrical::Circuit.human_attribute_name(:demand))
      assert_flash_message :alert, expected
    end
  end
end