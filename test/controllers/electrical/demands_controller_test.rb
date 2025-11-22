require "test_helper"
module Electrical
  class DemandsControllerTest < ActionController::TestCase
    include Devise::Test::ControllerHelpers

    setup do

      @project = create(:project)
      @other_project = create(:project)
      # Set the current project for all tests that need it
      set_current_project(@project) if defined?(set_current_project)

      # Set in and out of project disciplines
      @discipline = create(:discipline, code: :elec, name: 'Electrical', project: @project)
      @other_discipline = create(:discipline, code: :elec, name: 'Electrical', project: @other_project)

      @admin = create(:user)
      @admin.grant(:admin)

      @project_manager = create(:user)
      @project_manager.grant(:project_manager, @project) # Project manager role

      @team_member = create(:user)
      @team_member.grant(:team_member, @project) # Project team member role

      @accredited_team_member = create(:user)
      @accredited_team_member.grant(:electrical_designer) # Global electrical designer role
      @accredited_team_member.grant(:team_member, @project) # Project team member role

      @regular_user = create(:user)   # No roles
      
      # Create tags for a circuit and load connected with a cable
      @swbd_tag = create(:tag, prefix: 'EX', serial: 1001, discipline: @discipline)
      @cable_tag = create(:tag, prefix: 'EC', serial: 1001, discipline: @discipline)
      @motor_tag = create(:tag, prefix: 'EM', serial: 1001, discipline: @discipline)

      # Create out of project tags
      @other_motor_tag = create(:tag, prefix: 'EX', serial: 1002, discipline: @other_discipline)
      
      # Create tagables with the tags
      @switchboard = create(:electrical_switchboard, tag: @swbd_tag)
      @circuit = create(:electrical_circuit, electrical_switchboard: @switchboard)
      @motor = create(:electrical_motor, tag: @motor_tag)
      @other_motor = create(:electrical_motor, tag: @other_motor_tag)
      @cable = create(:electrical_cable, tag: @cable_tag)

      # Create loads for in and out of project loads
      @demand = create(:electrical_demand, demandable: @motor, config: 'three_3c')
      @other_demand = create(:electrical_demand, demandable: @other_motor, config: 'three_3c')

      # Create unassigned tag for building new demand
      @unassigned_tag = create(:tag, :unique_tag, discipline: @discipline)
      @unassigned_tag.update(tagable: create(:electrical_light_cct, tag: @unassigned_tag))

      @request.env["devise.mapping"] = Devise.mappings[:user]
    end

    # Index action tests
    test "unauthenticated users should be redirected to sign in" do
      get :index 
      assert_unauthenticated 
    end

    test "regular user cannot get index" do
      sign_in @regular_user
      get :index
      assert_response :forbidden
    end

    test "should get index for user with role on current project" do
      sign_in @team_member
      get :index
      assert_response :success
    end

    # Show action tests
    test "user cannot view demand details without a project role" do
      sign_in @regular_user
      get :show, params: { id: @demand.id }
      assert_response :forbidden
    end

    test "team member can view demand details" do
      sign_in @team_member
      get :show, params: { id: @demand.id }
      assert_response :success
    end

    # New Action Tests
    test "team member cannot access new form" do
      sign_in @team_member
      get :new, params: { tag_id: @unassigned_tag.id }
      assert_response :forbidden
    end

    test "accredited team member can access new form for existing unassigned tag" do
      sign_in @accredited_team_member
      get :new, params: { tag_id: @unassigned_tag.id }
      assert_response :success
    end

    # Create Action Tests - Success Cases
    test "accredited team member can create with existing unassigned tag" do
      sign_in @accredited_team_member
      assert_difference('Electrical::Demand.count', 1) do
        post :create, params: { tag_id: @unassigned_tag.id ,
                                electrical_demand: { 
                                  basis: 'power_pf',
                                  basis_notes: 'test basis notes',
                                  config: 'one',
                                  supply: 240.0,
                                  power: 100.0,
                                  power_factor: 0.95,
                                  duty: 0.1,
                                  notes: 'test notes'
                                } 
                              }
      end
      assert_equal I18n.t('flash.create.notice', 
                    resource_name: I18n.t('activerecord.models.electrical.demand')), 
                    flash[:success]
      assert_redirected_to electrical_demand_path(@unassigned_tag.tagable.electrical_demand)
    end

    # Create Action Tests - Failure Cases
    test "accredited team member cannot create with existing unassigned tag and invalid data" do
      sign_in @accredited_team_member
      assert_no_difference('Electrical::Demand.count') do
        post :create, params: { tag_id: @unassigned_tag.id,
                                electrical_demand: {
                                  basis: 'power_pf',
                                  basis_notes: 'test basis notes',
                                  config: '',
                                  supply: 240.0,
                                  power: 100.0,
                                  power_factor: 0.95,
                                  duty: 0.1,
                                  notes: 'test notes'
                                } }
      end
      assert_response :unprocessable_content
      assert_template :new
      assert flash.now[:alert].present?
    end

  # Edit Action Tests
    test "team member cannot access edit form" do
      sign_in @team_member
      get :edit, params: { id: @demand.id }
      assert_forbidden
    end

    test "accredited team member can access edit form" do
      sign_in @accredited_team_member
      get :edit, params: { id: @demand.id }
      assert_response :success
    end

  # Update Action Tests
    test "team member cannot update" do
      sign_in @team_member
      @demand.update(power: 100.0)
      patch :update, params: { id: @demand.id,
                               electrical_demand: { 
                                 power: 200.0
                               } }
      assert_forbidden
      assert_equal 100.0, @demand.reload.power
    end

  # Update Action Tests
    test "accredited team member can update" do
      sign_in @accredited_team_member
      @demand.update(power: 100.0)
      patch :update, params: { id: @demand.id,
                               electrical_demand: { 
                                 power: 200.0
                               } }
      assert_redirected_to electrical_demand_path(@demand)
      assert_equal I18n.t('flash.update.notice', 
                    resource_name: @demand.model_name.human), 
                    flash[:success]
      assert_equal 200.0, @demand.reload.power
    end

  # Destroy Action Tests
    test "accredited team member cannot destroy" do
      sign_in @accredited_team_member
      assert_no_difference("Electrical::Demand.count") do
        delete :destroy, params: { id: @demand.id }
      end
      assert_forbidden
    end

    test "admin can destroy" do
      sign_in @admin
      assert_difference("Electrical::Demand.count", -1) do
        delete :destroy, params: { id: @demand.id }
      end
      assert_redirected_to electrical_demands_path
      assert_equal I18n.t('flash.destroy.notice', 
                    resource_name: @demand.model_name.human), 
                    flash[:success]
    end
  end
end