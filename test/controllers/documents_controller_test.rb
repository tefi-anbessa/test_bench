# frozen_string_literal: true
require "test_helper"
require_relative "../helpers/resource_controller_test_helper"
class DocumentsControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers
  include ResourceControllerTestHelper

  setup do
    setup_controller_test
    setup_model_specific_data
  end

  def setup_model_specific_data
    # Set up an instance of document
    @dt = create(:document_control_doc_type, discipline: @discipline)
    @resource = create(:document, discipline: @discipline, doc_type: @dt)
    @other_resource = create(:document, discipline: @other_discipline, doc_type: @dt)
  end

  private

    # Set the minimum required params for a valid resource
    def valid_create_params
        { title: 'Test Document', discipline_id: @discipline.id, doc_type_id: @dt.id }
    end

    def valid_update_params
        { title: 'Updated Document' }
    end

    # Set invalid resource params for tests
    def invalid_resource_params
      { title: "A"*51 }
    end

    # Nominate an attribute to get changed during update tests
    def update_attribute_name
      :title
    end

    # Nominate a valid value to update the attribute to
    def updated_attribute_value
      "Revised Title"
    end
end
