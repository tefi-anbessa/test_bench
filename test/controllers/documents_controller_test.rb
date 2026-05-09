# frozen_string_literal: true
require "test_helper"
require "helpers/controller_test_helper"
class DocumentsControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers
  include ControllerTestHelper

  setup do
    # setup_controller_test
    # Cannot use standard setup because Document class has no module to define discipline
    setup_projects_and_users
    setup_disciplines(name: "Electrical", required_role: :designer)
    setup_accredited_users(:designer)
    setup_model_specific_data
  end

  def setup_model_specific_data
    # Set up an instance of document
    @dt = create(:doc_type, discipline: @discipline)
    @resource = create(:document, discipline: @discipline, doc_type: @dt)
    # Set up an out of scope instance of document
    @other_dt = create(:doc_type, discipline: @other_discipline)
    @other_resource = create(:document, discipline: @other_discipline, doc_type: @other_dt)
  end

  private

    # Required for nested routes
    def new_nesting_params
      { discipline_id: @discipline.id }
    end

    # Required for nested routes
    def index_nesting_params
      new_nesting_params
    end
  
    # Set the expected params for a valid create
    def create_params
        { document: 
          { 
          title: 'Test Document', 
          discipline_id: @discipline.id, 
          doc_type_id: @dt.id,
          notes: 'Test document notes'
          } 
        }
    end

    # Some models have read only attributes, these need to be excluded from update tests
    # to avoid validation errors
    def update_params
        { document: 
          { 
          title: 'Test Document',
          notes: 'Test document notes'
          } 
        }
    end

    # Set an invalid resource param to test controller response
    def invalid_param
      { document: { title: "A"*51 } }
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
