# frozen_string_literal: true
require "test_helper"
require "helpers/controller_test_helper"
class TagsControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers
  include ControllerTestHelper

  setup do
    @nesting = :discipline
    setup_projects_and_users # In test/helpers/test_login_helpers.rb
    setup_disciplines(name: "Electrical", required_role: :designer) 
    setup_accredited_users(:designer)
    setup_discipline_resources
    @request.env["devise.mapping"] = Devise.mappings[:user]
  end

  # === Spreadsheet import (see app/controllers/concerns/importable.rb) ===

  def csv_upload
    fixture_file_upload(Rails.root.join("test/fixtures/files/import/tags.csv"), "text/csv")
  end

  test "accredited user can reach the discipline-scoped import form" do
    sign_in_and_set_project(@accredited_user, @project)
    get :import, params: { discipline_id: @discipline.id }
    assert_response :success
  end

  test "team member without a role on the discipline cannot reach the import form" do
    sign_in_and_set_project(@team_member, @project)
    get :import, params: { discipline_id: @discipline.id }
    assert_response :forbidden
  end

  test "uploading a valid file creates a batch and redirects to it" do
    sign_in_and_set_project(@accredited_user, @project)
    assert_difference("Import::Batch.count", 1) do
      post :create_import, params: { discipline_id: @discipline.id, file: csv_upload }
    end
    batch = Import::Batch.last
    assert_equal @accredited_user, batch.user
    assert_equal @discipline, batch.discipline
    assert_equal "tags", batch.importer_key
    assert_redirected_to import_batch_path(batch)
  end

  test "uploading an unsupported file type is rejected before creating a batch" do
    sign_in_and_set_project(@accredited_user, @project)
    bad_file = fixture_file_upload(Rails.root.join("test/fixtures/files/import/tags.pdf"), "application/pdf")

    assert_no_difference("Import::Batch.count") do
      post :create_import, params: { discipline_id: @discipline.id, file: bad_file }
    end
    assert_response :unprocessable_content
  end

  test "project-wide upload creates a batch with no discipline set" do
    sign_in_and_set_project(@accredited_user, @project)
    assert_difference("Import::Batch.count", 1) do
      post :create_import, params: { project_id: @project.id, file: csv_upload }
    end
    assert_nil Import::Batch.last.discipline
  end

  private

    # Set the minimum required params for a valid resource
    def create_params
      { discipline_id: @discipline.id,
        tag: {
          prefix: "T",
          serial: 1111,
          suffix: "",
          stage: 1,
          service: 'Test service',
          location: "Test location",
          notes: "Test notes"
        }
    }
    end

    def update_params
      create_params
    end

    # Set invalid resource params for tests
    def invalid_param
      { tag: { prefix: "22" } }
    end

    # Nominate an attribute to get changed during update tests
    def update_attribute_name
      :service
    end

    # Nominate a valid value to update the attribute to
    def updated_attribute_value
      "Updated service"
    end
end
