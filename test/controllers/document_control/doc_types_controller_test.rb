# frozen_string_literal: true
require "helpers/resource_controller_test_helper.rb"
module DocumentControl
  class DocTypesControllerTest < ActionController::TestCase
    include Devise::Test::ControllerHelpers
    include ResourceControllerTestHelper

    setup do
      setup_controller_test # In test/helpers/resource_controller_test_helper.rb

      # Set up in and out of scope instances of doc_type
      @resource = create(:document_control_doc_type, discipline: @discipline)
      @other_resource = create(:document_control_doc_type, discipline: @other_discipline)
    end

    private

      # Set the minimum required params for a valid resource
      def valid_resource_params
        {
          discipline_id: @discipline.id,  
          code: 'SCH', 
          label: 'Schematic' 
        }
      end

      # Set invalid resource params for tests
      def invalid_resource_params
        { code: "1234567"}  # Exceeds maximum length
      end

      # Nominate an attribute to get changed during update tests
      def update_attribute_name
        :code
      end

      # Nominate a valid value to update the attribute to
      def updated_attribute_value
        "NEW"
      end

    # Helper methods
      def assert_successful_creation_flash_message(resource = @resource)
        assert_equal I18n.t("flash.create.notice", resource: resource.model_name.human), flash[:notice]
      end

  end
end
