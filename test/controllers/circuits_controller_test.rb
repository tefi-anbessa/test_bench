require 'test_helper'

class CircuitsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers
  
  setup do
    @user = create(:user)
    @project = create(:project)
    @switchboard = create(:switchboard, tag: create(:tag, project: @project))
    @circuit = create(:circuit, switchboard: @switchboard)
    
    # Set up roles
    @user.add_role(:project_owner, @project)
    sign_in @user
  end
  
  test "should get index" do
    get switchboard_circuits_url(@switchboard)
    assert_response :success
  end
  
  test "should get new" do
    get new_switchboard_circuit_url(@switchboard)
    assert_response :success
  end
  
  test "should create circuit" do
    assert_difference('Circuit.count') do
      post switchboard_circuits_url(@switchboard), params: { 
        circuit: { 
          name: 'New Circuit', 
          circuit_number: 'C1',
          description: 'Test circuit',
          rating: '10A',
          voltage: '230V',
          phase: '1',
          breaker_size: '16A'
        } 
      }
    end

    assert_redirected_to switchboard_circuit_url(@switchboard, Circuit.last)
  end
  
  test "should show circuit" do
    get switchboard_circuit_url(@switchboard, @circuit)
    assert_response :success
  end
  
  test "should get edit" do
    get edit_switchboard_circuit_url(@switchboard, @circuit)
    assert_response :success
  end
  
  test "should update circuit" do
    patch switchboard_circuit_url(@switchboard, @circuit), params: { 
      circuit: { 
        name: 'Updated Circuit',
        description: 'Updated description'
      } 
    }
    
    assert_redirected_to switchboard_circuit_url(@switchboard, @circuit)
    @circuit.reload
    assert_equal 'Updated Circuit', @circuit.name
    assert_equal 'Updated description', @circuit.description
  end
  
  test "should destroy circuit" do
    assert_difference('Circuit.count', -1) do
      delete switchboard_circuit_url(@switchboard, @circuit)
    end

    assert_redirected_to switchboard_circuits_url(@switchboard)
  end
  
  test "should not access circuit from unauthorized project" do
    other_project = create(:project)
    other_switchboard = create(:switchboard, tag: create(:tag, project: other_project))
    other_circuit = create(:circuit, switchboard: other_switchboard)
    
    get switchboard_circuit_url(other_switchboard, other_circuit)
    assert_redirected_to root_url
    assert_equal "You are not authorized to perform this action.", flash[:alert]
  end
end
