# frozen_string_literal: true
require "helpers/resource_controller_test_helper.rb"
module DocumentControl
  class IssuesControllerTest < ActionController::TestCase
    include Devise::Test::ControllerHelpers
    include ResourceControllerTestHelper

    setup do
      setup_controller_test # In test/helpers/resource_controller_test_helper.rb      

      # Set up in and out of scope instances of issue
      @resource = create(:document_control_issue, discipline: @discipline)
      @other_resource = create(:document_control_issue, discipline: @other_discipline)
    end

    private

      # Set the minimum required params for a valid resource
      def valid_resource_params
      {
          document: '' # Add valid data
            code: '' # Add valid data
            reason: '' # Add valid data
  
        }
      end

      # Set invalid resource params for tests
      def invalid_resource_params
        { }  # Set invalid value for an attribute
      end

      # Nominate an attribute to get changed during update tests
      def update_attribute_name
        # Set one attribute name
      end

      # Nominate a valid value to update the attribute to
      def updated_attribute_value
        "new_value"
      end
  end
end
