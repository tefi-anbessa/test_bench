require "test_helper"

class CableTypesControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers
  
  setup do
    @project = create(:project)
    set_current_project(@project)
    @cable_type = create(:cable_type, project: @project)
    
    # Create base users without any roles
    @admin = create(:user)
    @regular_user = create(:user)
    @team_member = create(:user)
    @electrical_designer = create(:user)
    
    # Add global admin role
    @admin.grant(:admin)

    # Add project-specific team member roles
    @team_member.grant(:team_member, @project)
    @electrical_designer.grant(:team_member, @project)

    # Add global functional role
    @electrical_designer.grant(:electrical_designer)
  
    # Set up request environment
#    @request.env['HTTP_REFERER'] = 'http://test.host/'
#    @request.env['devise.mapping'] = Devise.mappings[:user]
  end

  # Authentication tests
  test "should redirect to sign in if not authenticated" do
    get :index
    assert_unauthenticated
  end

  # Index tests
  test "any authenticated user can view index" do
    sign_in(@regular_user)
    # @request.session[:project_id] = @project.id
    get :index
    assert_response :success
    assert_not_nil assigns(:cable_types)
  end

  # Show tests
  # TODO: Properly test the authorize call in the show action
  # Currently, the test only verifies RecordNotFound from policy_scope
  # We should also test the actual authorization in the show action
  test "team member cannot show cable type on different project" do
    sign_in(@team_member)
    @project2 = create(:project)
    @cable_type2 = create(:cable_type, project: @project2)
    assert_raises(ActiveRecord::RecordNotFound) do
      get :show, params: { id: @cable_type2.id }
    end
  end

  test "regular user cannot show cable type on current project" do
    sign_in(@regular_user)
    get :show, params: { id: @cable_type.id }
    assert_forbidden
  end

  # New tests
  test "regular user cannot access new form" do
    sign_in @regular_user
#    @request.session[:project_id] = @project.id
    get :new
    assert_forbidden
  end

  test "electrical designer can access new form" do
    sign_in @electrical_designer
    get :new
    assert_response :success
  end

  # Create tests
  test "regular user cannot create cable type" do
    sign_in @regular_user
    assert_no_difference('CableType.count') do
      post :create, params: {
        cable_type: attributes_for(:cable_type, project_id: @project.id)
      }
    end
    assert_forbidden
  end

  test "electrical designer can create cable type" do
    sign_in @electrical_designer
    assert_difference('CableType.count') do
      post :create, params: { 
        cable_type: { 
          project_id: @project.id,
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
      }
    end
    assert_redirected_to cable_type_path(CableType.last)
  end

  # Edit tests
  test "regular user cannot edit cable type" do
    sign_in @regular_user
    get :edit, params: { id: @cable_type.id }
    assert_forbidden
  end

  test "electrical designer can edit cable type" do
    sign_in @electrical_designer
    get :edit, params: { id: @cable_type.id }
    assert_response :success
  end

  # Update tests
  test "regular user cannot update cable type" do
    original_material = @cable_type.conductor_material
    sign_in @regular_user
    patch :update, params: {
      id: @cable_type.id,
      cable_type: { conductor_material: 'Al' }
    }
    assert_forbidden
    assert_equal original_material, @cable_type.reload.conductor_material
  end

  test "electrical designer can update cable type" do
    sign_in @electrical_designer
    patch :update, params: {
      id: @cable_type.id,
      cable_type: { conductor_material: 'Al' }
    }
    assert_redirected_to cable_type_path(@cable_type)
    assert_equal 'Al', @cable_type.reload.conductor_material
  end

  # Destroy tests
  test "regular user cannot destroy cable type" do
    sign_in @regular_user
    assert_no_difference('CableType.count') do
      delete :destroy, params: { id: @cable_type.id }
    end
    assert_forbidden
  end

  test "admin can destroy cable type" do
    sign_in @admin
    assert_difference('CableType.count', -1) do
      delete :destroy, params: { id: @cable_type.id }
    end
    assert_redirected_to cable_types_path
  end
end
