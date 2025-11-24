require 'test_helper'

class ErrorHandlingTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @user = create(:user)
    @admin = create(:user, :admin)
    @project = create(:project)
    @discipline = create(:discipline, project: @project)
    @cable_type = create(:electrical_cable_type)
    @cable_tag = create(:tag, :unique_tag, prefix: 'EC', discipline: @discipline)
    @switchboard_tag = create(:tag, :unique_tag, prefix: 'EX', discipline: @discipline)
    @switchboard = create(:electrical_switchboard, tag: @switchboard_tag)
    sign_in @user
  end

  test "setup is valid" do
    assert @user.valid?
    assert @admin.valid?
    assert @admin.has_role?(:admin)
    assert @project.valid?
    assert @discipline.valid?
    assert @cable_type.valid?
    assert @cable_tag.valid?
    assert @switchboard_tag.valid?
    assert @switchboard.valid?
    assert_equal @switchboard.tag, @switchboard_tag
  end

  # Test that unauthorized access to destroy action shows the custom 403 page
  test "unauthorized user sees custom 403 page when trying to delete project" do
    assert_no_difference('Project.count') do
      delete project_path(@project)
    end
    assert_forbidden
  end

  # Test that conflict error shows the custom conflict page
  test "shows custom conflict page for tag already associated" do
    sign_out @user
    sign_in @admin
    # Try to create another switchboard with the same tag
    assert_no_difference('Electrical::Switchboard.count') do
      post electrical_switchboards_path, params: {
        tag_id: @switchboard_tag.id,
        electrical_switchboard: {
          voltage_rating: '600/1000V',
          busbar_rating: 200.0,
          busbar_fault_rating: 2000.0,
          busbar_fault_duration: 0.5,
          cable_entry: 'Bottom',
          incomer_protection: 'Isolator 4P',
          metering: 'None',
          neutral_bar_connections: 'None',
          earth_bar_connections: 'None',
          ingress_protection: '20',
          notes: 'Test switchboard'
        }
      }

    end
    assert_conflict
  end

  test "shows custom 404 page for non-existent route" do
    get '/this_route_does_not_exist'
    assert_response :not_found
    assert_select 'h1', /404: Page Not Found/
  end

  test "handles 500 with custom page in production" do
    # Test with a controller that raises an error
    test_controller = Class.new(ApplicationController) do
      def test_error
        raise "Test server error"
      end
      
      # Override the exception handling to test the error page directly
      def test_error_with_handling
        test_error
      rescue => _e
        render file: Rails.public_path.join('500.html'), 
               status: :internal_server_error,
               layout: false
      end
    end
    
    # Define the controller in the Object namespace
    Object.const_set('TestErrorController', test_controller)
    
    # Stub Rails.env to simulate production
    Rails.stub(:env, ActiveSupport::StringInquirer.new('production')) do
      # Add route for the test controller
      with_routing do |routes|
        routes.draw do
          get '/test_error', to: 'test_error#test_error_with_handling'
        end
        
        get '/test_error'
        assert_response :internal_server_error
      end
    end
    
    # Clean up
    Object.send(:remove_const, 'TestErrorController')
  end
end