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

  # === Parent search (remote Tom Select endpoint - see
  # TagsController#parent_search and
  # app/javascript/controllers/tom_select_controller.js) ===

  test "accredited user can search prospective parents by full_tag" do
    sign_in_and_set_project(@accredited_user, @project)
    candidate = create(:tag, discipline: @discipline, prefix: "ZZ")
    get :parent_search, params: { discipline_id: @discipline.id, q: candidate.full_tag }
    assert_response :success
    assert_includes JSON.parse(response.body).map { |h| h["id"] }, candidate.id
  end

  test "search results include discipline code (via long_label) and service" do
    sign_in_and_set_project(@accredited_user, @project)
    candidate = create(:tag, discipline: @discipline, prefix: "ZZ", service: "Candidate service text")
    get :parent_search, params: { discipline_id: @discipline.id, q: candidate.full_tag }
    assert_response :success
    result = JSON.parse(response.body).find { |h| h["id"] == candidate.id }
    assert_equal candidate.long_label, result["long_label"]
    assert_equal "Candidate service text", result["service"]
  end

  test "a tag's own descendants are excluded from its prospective parents" do
    sign_in_and_set_project(@accredited_user, @project)
    child = create(:tag, discipline: @discipline, parent: @resource, prefix: "ZZ")
    get :parent_search, params: { discipline_id: @discipline.id, tag_id: @resource.id, q: child.full_tag }
    assert_response :success
    assert_not_includes JSON.parse(response.body).map { |h| h["id"] }, child.id
  end

  test "results are scoped to the current project" do
    sign_in_and_set_project(@accredited_user, @project)
    get :parent_search, params: { discipline_id: @discipline.id, q: @other_resource.full_tag }
    assert_response :success
    assert_not_includes JSON.parse(response.body).map { |h| h["id"] }, @other_resource.id
  end

  test "a team member with only a project role can still search, unlike import" do
    sign_in_and_set_project(@team_member, @project)
    get :parent_search, params: { discipline_id: @discipline.id, q: @resource.full_tag }
    assert_response :success
  end

  test "a user with no project role at all cannot search" do
    # Rejected even earlier than authorize Tag, :index? - set_parent_for_import
    # can't resolve @discipline at all for this user (policy_scope(Discipline)
    # is .none), same as e.g. "user cannot view project details without a
    # project role" in projects_controller_test.rb.
    sign_in_and_set_project(@regular_user, @project)
    get :parent_search, params: { discipline_id: @discipline.id, q: @resource.full_tag }
    assert_response :conflict
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
