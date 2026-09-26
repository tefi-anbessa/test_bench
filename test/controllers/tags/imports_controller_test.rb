require "test_helper"
require "helpers/test_setup_helpers"

module Tags
  class ImportsControllerTest < ActionController::TestCase
    include Devise::Test::ControllerHelpers
    include TestSetupHelpers

    setup do
      setup_projects_and_users
      setup_disciplines(name: "Electrical", required_role: :designer)
      setup_accredited_users(:designer)
      @request.env["devise.mapping"] = Devise.mappings[:user]
    end

    def csv_upload(filename = "tags.csv")
      fixture_file_upload(Rails.root.join("test/fixtures/files/import/tags.csv"), "text/csv")
    end

    test "accredited user can reach the discipline-scoped upload form" do
      sign_in_and_set_project(@accredited_user, @project)
      get :new, params: { discipline_id: @discipline.id }
      assert_response :success
    end

    test "team member without a role on the discipline cannot reach the upload form" do
      sign_in_and_set_project(@team_member, @project)
      get :new, params: { discipline_id: @discipline.id }
      assert_response :forbidden
    end

    test "uploading a valid file creates a batch and redirects to it" do
      sign_in_and_set_project(@accredited_user, @project)
      assert_difference("Import::Batch.count", 1) do
        post :create, params: { discipline_id: @discipline.id, file: csv_upload }
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
        post :create, params: { discipline_id: @discipline.id, file: bad_file }
      end
      assert_response :unprocessable_content
    end

    test "project-wide upload creates a batch with no discipline set" do
      sign_in_and_set_project(@accredited_user, @project)
      assert_difference("Import::Batch.count", 1) do
        post :create, params: { project_id: @project.id, file: csv_upload }
      end
      assert_nil Import::Batch.last.discipline
    end
  end
end
