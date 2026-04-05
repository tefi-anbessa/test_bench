# frozen_string_literal: true
require "helpers/resource_controller_test_helper.rb"
module ProjectChange
  class RequestsControllerTest < ActionController::TestCase
    include Devise::Test::ControllerHelpers
    include ResourceControllerTestHelper

    setup do
      setup_controller_test # In test/helpers/resource_controller_test_helper.rb      

      # Set up in and out of scope instances of request
      @resource = create(:project_change_request, project: @project)
      @other_resource = create(:project_change_request, project: @other_project)
    end

    private

      # Set the minimum required params for a valid resource
      def valid_create_params
        {
          title: 'Test Change Request',
          reason: 'Test reason',
          summary: 'Test summary',
          duration: 'permanent'
        }
      end

    def valid_update_params
        { 
          title: 'Updated Change Request',
          reason: 'Test reason',
          summary: 'Test summary',
          duration: 'permanent' 
        }
    end

      # Set invalid resource params for tests
      def invalid_resource_params
        { reason: nil }
      end

      # Nominate an attribute to get changed during update tests
      def update_attribute_name
        :reason
      end

      # Nominate a valid value to update the attribute to
      def updated_attribute_value
        "updated reason"
      end
  end
end
