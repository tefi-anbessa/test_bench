require "test_helper"
require "helpers/test_setup_helpers"

class ImportBatchesControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers
  include TestSetupHelpers

  setup do
    setup_projects_and_users
    setup_disciplines(name: "Electrical", required_role: :designer)
    setup_accredited_users(:designer)
    @request.env["devise.mapping"] = Devise.mappings[:user]
    sign_in_and_set_project(@accredited_user, @project)
  end

  def csv_for(header, *data_rows)
    ([ "#{header},Stage" ] + data_rows.map { |row| "#{row},5" }).join("\n") + "\n"
  end

  def build_batch(csv:, discipline: @discipline, column_mapping: {})
    create(:import_batch,
      user: @accredited_user, project: @project, discipline: discipline,
      original_filename: "tags.csv", file_data: csv, column_mapping: column_mapping)
  end

  test "show renders the mapping form for a freshly-uploaded batch" do
    batch = build_batch(csv: csv_for("Tag Number", "PT0001A"))
    get :show, params: { id: batch.id }
    assert_response :success
    assert_select "select[name='column_mapping[Tag Number]']"
  end

  test "another user's batch is not found" do
    other_user = create(:user)
    batch = build_batch(csv: csv_for("Tag Number", "PT0001A"))
    batch.update!(user: other_user)
    assert_raises(ActiveRecord::RecordNotFound) { get :show, params: { id: batch.id } }
  end

  test "update confirms the mapping, advances status, and saves a mapping preset" do
    batch = build_batch(csv: csv_for("Tag Number", "PT0001A"))
    patch :update, params: { id: batch.id, column_mapping: { "Tag Number" => "full_tag", "Stage" => "stage" } }

    batch.reload
    assert batch.mapped?
    assert_equal({ "Tag Number" => "full_tag", "Stage" => "stage" }, batch.column_mapping)
    assert_redirected_to import_batch_path(batch)

    preset = Import::MappingPreset.find_by(user: @accredited_user, importer_key: "tags")
    assert_equal({ "Tag Number" => "full_tag", "Stage" => "stage" }, preset.column_mapping)
  end

  test "show renders the dry-run review once mapped" do
    batch = build_batch(csv: csv_for("Tag Number", "PT0001A"), column_mapping: { "Tag Number" => "full_tag", "Stage" => "stage" })
    batch.update!(status: :mapped)

    get :show, params: { id: batch.id }
    assert_response :success
    assert_select ".alert-success"
  end

  test "commit persists valid rows and redirects with a summary" do
    batch = build_batch(
      csv: csv_for("Tag Number", "PT0001A", "FT0002"),
      column_mapping: { "Tag Number" => "full_tag", "Stage" => "stage" }
    )
    batch.update!(status: :mapped)

    assert_difference("Tag.count", 2) do
      post :commit, params: { id: batch.id }
    end
    batch.reload
    assert batch.imported?
    assert_equal 2, batch.row_count
    assert_redirected_to discipline_tags_path(@discipline)
  end

  test "commit in strict mode re-renders the review with nothing committed when a row is invalid" do
    create(:tag, discipline: @discipline, prefix: "PT", serial: 1)
    batch = build_batch(
      csv: csv_for("Tag Number", "PT0001"), # duplicates the existing tag
      column_mapping: { "Tag Number" => "full_tag", "Stage" => "stage" }
    )
    batch.update!(status: :mapped)

    assert_no_difference("Tag.count") do
      post :commit, params: { id: batch.id }
    end
    assert_response :unprocessable_content
    refute batch.reload.imported?
  end

  test "commit in partial mode imports the valid rows and skips the rest" do
    create(:tag, discipline: @discipline, prefix: "PT", serial: 1)
    batch = build_batch(
      csv: csv_for("Tag Number", "PT0001", "FT0002"), # PT0001 duplicates, FT0002 is fine
      column_mapping: { "Tag Number" => "full_tag", "Stage" => "stage" }
    )
    batch.update!(status: :mapped)

    assert_difference("Tag.count", 1) do
      post :commit, params: { id: batch.id, partial: "1" }
    end
    assert batch.reload.imported?
    assert_equal 1, batch.row_count
  end

  test "commit cannot be re-run on an already-imported batch" do
    batch = build_batch(csv: csv_for("Tag Number", "PT0001A"), column_mapping: { "Tag Number" => "full_tag", "Stage" => "stage" })
    batch.update!(status: :imported)

    assert_no_difference("Tag.count") do
      post :commit, params: { id: batch.id }
    end
    assert_response :conflict
  end

  test "destroy aborts the batch without deleting it" do
    batch = build_batch(csv: csv_for("Tag Number", "PT0001A"))
    delete :destroy, params: { id: batch.id }
    assert batch.reload.aborted?
    assert_redirected_to discipline_tags_path(@discipline)
  end
end
