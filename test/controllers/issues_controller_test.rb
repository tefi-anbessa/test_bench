# frozen_string_literal: true
require "test_helper"
require "helpers/controller_test_helper"
class IssuesControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers
  include ControllerTestHelper

  setup do
    @nesting = :document
    setup_projects_and_users # In test/helpers/test_setup_helpers.rb
    setup_disciplines(name: "Electrical", required_role: :designer)
    setup_accredited_users(:designer)   

    # Set up in and out of scope instances of issue
    @source_format = create(:source_format)
    @dt = create(:doc_type, discipline: @discipline)
    @document = create(:document, doc_type: @dt, discipline: @discipline)
    @resource = create(:issue, document: @document, source_format: @source_format)
    @other_dt = create(:doc_type, discipline: @other_discipline)
    @other_document = create(:document, doc_type: @other_dt, discipline: @other_discipline)
    @other_resource = create(:issue, document: @other_document, source_format: @source_format)
    @request.env["devise.mapping"] = Devise.mappings[:user]
  end

  private

    # Set the minimum required params for a valid resource
    def create_params
      { document_id: @document.id,
        issue: {
          code: 'TEST-001',
          reason: 'Test issue',
          source_format_id: @source_format.id
        }
      }
    end

    def update_params
        create_params
    end

    # Set invalid resource params for tests
    def invalid_param
      { issue: { code: nil } }
    end

    # Nominate an attribute to get changed during update tests
    def update_attribute_name
      :reason
    end

    # Nominate a valid value to update the attribute to
    def updated_attribute_value
      "Updated reason"
    end
end