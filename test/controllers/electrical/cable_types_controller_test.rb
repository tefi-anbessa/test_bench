require "test_helper"
module Electrical
  class CableTypesControllerTest < ActionController::TestCase
    include Devise::Test::ControllerHelpers
    
    setup do
      @project = create(:project)
      set_current_project(@project)
      @cable_type = create(:electrical_cable_type, project: @project)

      @other_project = create(:project)
      @other_cable_type = create(:electrical_cable_type, project: @other_project)
      
      # Create base users without any roles
      @admin = create(:user)
      @regular_user = create(:user)
      @team_member = create(:user)
      @accredited_user = create(:user)
      @accredited_user_shared = create(:user)
      
      # Add global admin role
      @admin.grant(:admin)

      # Add project-specific team member roles
      @team_member.grant(:team_member, @project)
      @accredited_user.grant(:team_member, @project)
      @accredited_user_shared.grant(:team_member, @project)
      @accredited_user_shared.grant(:team_member, @other_project)

      # Add global functional role
      @accredited_user.grant(Electrical::CableType.required_role)
      @accredited_user_shared.grant(Electrical::CableType.required_role)

      # set of params for cable type creation
      @cable_type_params = {
          conductor_material: "Cu",
          csa: 4.0,  # Changed from factory value of 2.5 to make it different
          cores: 3,
          neutral_csa: 4.0,  # Changed to match csa
          earth_csa: 2.5,    # Changed from 1.5
          insulation: "XLPE",
          bedding: "PVC",
          armour: "SWA",
          sheath: "PVC",
          temperature_rating: "75˚C",
          voltage_rating: "600/1000V",
          bedding_od: 12.5,  # Changed from 10.5
          overall_od: 17.2   # Changed from 15.2
      }
      # Set up request environment
  #    @request.env['HTTP_REFERER'] = 'http://test.host/'
  #    @request.env['devise.mapping'] = Devise.mappings[:user]

      # Lemon swatch is expected for electrical models that aren't attached to a discipline
      @swatch = Swatch.create!(name: "lemon") 
    end

    # Authentication tests
    test "should redirect to sign in if not authenticated" do
      get :index, params: { project_id: @project.id }
      assert_unauthenticated
    end

    # Index tests
    test "regular user cannot view index" do
      sign_in(@regular_user)
      get :index, params: { project_id: @project.id }
      assert_forbidden
    end

    test "team member with project role can view index for current project" do
      sign_in(@team_member)
      # @request.session[:project_id] = @project.id
      get :index, params: { project_id: @project.id }
      assert_response :success
      assert_not_nil assigns(:cable_types)
    end

    # Update this test when RBAC is refactored to improve control of catalog type models.
    test "team member with project role can view index for other project but empty scope" do
      sign_in(@team_member)
      # @request.session[:project_id] = @project.id
      get :index, params: { project_id: @other_project.id }
      assert_empty assigns(:cable_types)
    end


    # Update this test when RBAC is refactored to improve control of catalog type models.
    test "user with multiple projects role can view index without project scope" do
      sign_in(@accredited_user_shared)
      get :index
      assert_response :success
      assert_not_nil assigns(:cable_types)
    end

    # Show tests
    test "regular user cannot show cable type on current project" do
      sign_in(@regular_user)
      get :show, params: { id: @cable_type.id }
      assert_forbidden
    end

    test "team member cannot show cable type on different project" do
      sign_in(@team_member)
      @project2 = create(:project)
      @cable_type2 = create(:electrical_cable_type, project: @project2)
      get :show, params: { id: @cable_type2.id }
      assert_forbidden
    end

    test "team member can show cable type on current project" do
      sign_in(@team_member)
      get :show, params: { id: @cable_type.id }
      assert_response :success
    end

    test "user with multiple projects can show cable type when current project is not set" do
      skip "Update this test when RBAC is refactored to improve control of catalog type models."
      sign_in(@accredited_user_shared)
      set_current_project(nil)
      get :show, params: { id: @other_cable_type.id }
      assert_response :success
    end

    # New tests
    test "team member cannot access new form" do
      sign_in @team_member
      get :new, params: { project_id: @project.id }
      assert_forbidden
    end

    test "accredited user can access new form" do
      sign_in @accredited_user
      get :new, params: { project_id: @project.id }
      assert_response :success
    end

    test "accredited user can access new form without project context" do
      sign_in @accredited_user
      get :new
      assert_response :success
    end

    # Create tests
    test "team member cannot create cable type" do
      sign_in @team_member
      assert_no_difference('Electrical::CableType.count') do
        post :create, params: {
                project_id: @project.id,
                electrical_cable_type: @cable_type_params
        }
      end
      assert_forbidden
    end

    test "electrical designer can create cable type" do
      sign_in @accredited_user
      assert_difference('Electrical::CableType.count') do
        post :create, params: {
                project_id: @project.id,
                electrical_cable_type: @cable_type_params
        }
      end
      assert_redirected_to electrical_cable_type_path(Electrical::CableType.last)
    end

    test "electrical designer can create cable type without current project context" do
      sign_in @accredited_user
      assert_difference('Electrical::CableType.count') do
        post :create, params: {
                electrical_cable_type: @cable_type_params.merge(project_id: @project.id) }
      end
      assert_redirected_to electrical_cable_type_path(Electrical::CableType.last)
    end

    # Edit tests
    test "team member cannot edit cable type" do
      sign_in @team_member
      get :edit, params: { id: @cable_type.id }
      assert_forbidden
    end

    test "electrical designer can edit cable type" do
      sign_in @accredited_user
      get :edit, params: { id: @cable_type.id }
      assert_response :success
    end

    # Update tests
    test "team member cannot update cable type" do
      original_material = @cable_type.conductor_material
      sign_in @team_member
      patch :update, params: {
        id: @cable_type.id,
        electrical_cable_type: { conductor_material: 'Al' }
      }
      assert_forbidden
      assert_equal original_material, @cable_type.reload.conductor_material
    end

    test "electrical designer can update cable type" do
      sign_in @accredited_user
      patch :update, params: {
        id: @cable_type.id,
        electrical_cable_type: { conductor_material: 'Al' }
      }
      assert_redirected_to electrical_cable_type_path(@cable_type)
      assert_equal 'Al', @cable_type.reload.conductor_material
    end

    # Destroy tests
    test "electrical designer cannot destroy cable type" do
      sign_in @accredited_user
      assert_no_difference('CableType.count') do
        delete :destroy, params: { id: @cable_type.id }
      end
      assert_forbidden
    end

    test "admin can destroy cable type" do
      sign_in @admin
      project = @cable_type.project
      assert_difference('Electrical::CableType.count', -1) do
        delete :destroy, params: { id: @cable_type.id }
      end
      assert_redirected_to project_electrical_cable_types_path(project)
    end
  end
end
