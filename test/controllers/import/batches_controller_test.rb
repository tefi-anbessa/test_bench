require "test_helper"
require "helpers/test_setup_helpers"

module Import
  class BatchesControllerTest < ActionController::TestCase
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

    def build_motor_batch(csv:, column_mapping: {})
      create(:import_batch,
        user: @accredited_user, project: @project, discipline: @discipline,
        importer_key: "electrical/motors", original_filename: "motors.csv",
        file_data: csv, column_mapping: column_mapping)
    end

    def build_multi_sheet_batch(discipline: @discipline, sheet_name: nil, column_mapping: {})
      file_data = Rails.root.join("test/fixtures/files/import/tags_multi_sheet.xlsx").binread
      create(:import_batch,
        user: @accredited_user, project: @project, discipline: discipline,
        original_filename: "tags_multi_sheet.xlsx", file_data: file_data,
        sheet_name: sheet_name, column_mapping: column_mapping)
    end

    test "show renders a worksheet selector for a freshly-uploaded multi-sheet file" do
      batch = build_multi_sheet_batch
      get :show, params: { id: batch.id }
      assert_response :success
      assert_select "select[name='sheet_name']"
      assert_select "option", "Electrical"
      assert_select "option", "Mechanical"
    end

    test "update sets the chosen sheet and leaves the batch awaiting column mapping" do
      batch = build_multi_sheet_batch
      patch :update, params: { id: batch.id, sheet_name: "Mechanical" }

      batch.reload
      assert_equal "Mechanical", batch.sheet_name
      assert batch.uploaded?
      assert_redirected_to import_batch_path(batch)
    end

    test "update clears the chosen sheet, sending the batch back to worksheet selection" do
      batch = build_multi_sheet_batch(sheet_name: "Mechanical")
      patch :update, params: { id: batch.id, sheet_name: "" }

      batch.reload
      assert_nil batch.sheet_name
      assert batch.uploaded?
      assert_redirected_to import_batch_path(batch)

      get :show, params: { id: batch.id }
      assert_select "select[name='sheet_name']"
    end

    test "show renders the mapping form, using the chosen sheet's headers, once a sheet is set" do
      batch = build_multi_sheet_batch(sheet_name: "Mechanical")
      get :show, params: { id: batch.id }
      assert_response :success
      assert_select "select[name='column_mapping[Tag Number]']"
      assert_select "td", text: "Service"
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

    test "update persists the create_missing_tags checkbox for an importer that supports it" do
      batch = build_motor_batch(csv: "Tag,Motor Type,Frame Size\nMTR0099,induction,100\n")
      patch :update, params: { id: batch.id,
        column_mapping: { "Tag" => "full_tag", "Motor Type" => "motor_type", "Frame Size" => "frame_size" },
        create_missing_tags: "1" }

      assert batch.reload.create_missing_tags?
    end

    test "update ignores create_missing_tags for an importer that doesn't support it" do
      batch = build_batch(csv: csv_for("Tag Number", "PT0001A"))
      patch :update, params: { id: batch.id,
        column_mapping: { "Tag Number" => "full_tag", "Stage" => "stage" },
        create_missing_tags: "1" }

      refute batch.reload.create_missing_tags?
    end

    test "back_to_mapping sends a mapped batch back to the mapping form without touching its data" do
      batch = build_batch(csv: csv_for("Tag Number", "PT0001A"), column_mapping: { "Tag Number" => "full_tag", "Stage" => "stage" })
      batch.update!(status: :mapped)

      patch :back_to_mapping, params: { id: batch.id }

      assert_redirected_to import_batch_path(batch)
      batch.reload
      assert batch.uploaded?
      assert_equal({ "Tag Number" => "full_tag", "Stage" => "stage" }, batch.column_mapping)

      get :show, params: { id: batch.id }
      assert_response :success
      assert_select "select[name='column_mapping[Tag Number]']"
    end

    test "back_to_mapping is rejected on a batch still awaiting its first mapping" do
      batch = build_batch(csv: csv_for("Tag Number", "PT0001A"))
      patch :back_to_mapping, params: { id: batch.id }
      assert_response :conflict
    end

    test "back_to_mapping is rejected on an already-imported batch" do
      batch = build_batch(csv: csv_for("Tag Number", "PT0001A"), column_mapping: { "Tag Number" => "full_tag", "Stage" => "stage" })
      batch.update!(status: :imported)
      patch :back_to_mapping, params: { id: batch.id }
      assert_response :conflict
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

    # Tempfile unlinks its underlying file when the object itself is
    # garbage-collected, regardless of whether fixture_file_upload still
    # holds its path - keep a live reference for the life of the test.
    def csv_upload(content)
      file = Tempfile.new(["refresh", ".csv"])
      file.write(content)
      file.flush
      (@csv_uploads ||= []) << file
      fixture_file_upload(file.path, "text/csv")
    end

    test "refresh_file is rejected while the batch is still awaiting mapping" do
      batch = build_batch(csv: csv_for("Tag Number", "PT0001A"))
      patch :refresh_file, params: { id: batch.id, file: csv_upload(csv_for("Tag Number", "PT0002A")) }
      assert_response :conflict
    end

    test "refresh_file is rejected on an already-imported batch" do
      batch = build_batch(csv: csv_for("Tag Number", "PT0001A"), column_mapping: { "Tag Number" => "full_tag", "Stage" => "stage" })
      batch.update!(status: :imported)
      patch :refresh_file, params: { id: batch.id, file: csv_upload(csv_for("Tag Number", "PT0002A")) }
      assert_response :conflict
    end

    test "refresh_file is rejected on an aborted batch" do
      batch = build_batch(csv: csv_for("Tag Number", "PT0001A"), column_mapping: { "Tag Number" => "full_tag", "Stage" => "stage" })
      batch.update!(status: :aborted)
      patch :refresh_file, params: { id: batch.id, file: csv_upload(csv_for("Tag Number", "PT0002A")) }
      assert_response :conflict
    end

    test "refresh_file with an unsupported format re-renders review and leaves the batch untouched" do
      batch = build_batch(csv: csv_for("Tag Number", "PT0001A"), column_mapping: { "Tag Number" => "full_tag", "Stage" => "stage" })
      batch.update!(status: :mapped)
      bad_file = fixture_file_upload(Rails.root.join("test/fixtures/files/import/tags.pdf"), "application/pdf")

      patch :refresh_file, params: { id: batch.id, file: bad_file }

      assert_response :unprocessable_content
      assert_select ".alert"
      batch.reload
      assert batch.mapped?
      assert_equal({ "Tag Number" => "full_tag", "Stage" => "stage" }, batch.column_mapping)
    end

    test "refresh_file replaces the file and resets the batch back to mapping" do
      batch = build_batch(csv: csv_for("Tag Number", "PT0001A"), column_mapping: { "Tag Number" => "full_tag", "Stage" => "stage" })
      batch.update!(status: :mapped)
      old_expiry = batch.expires_at
      new_content = csv_for("Tag Number", "PT0002A")

      patch :refresh_file, params: { id: batch.id, file: csv_upload(new_content) }

      assert_redirected_to import_batch_path(batch)
      batch.reload
      assert batch.uploaded?
      assert_nil batch.sheet_name
      assert_equal({}, batch.column_mapping)
      assert batch.expires_at > old_expiry
      assert_equal new_content, batch.file_data
    end

    test "refresh_file on another user's batch is not found" do
      other_user = create(:user)
      batch = build_batch(csv: csv_for("Tag Number", "PT0001A"), column_mapping: { "Tag Number" => "full_tag", "Stage" => "stage" })
      batch.update!(status: :mapped, user: other_user)
      assert_raises(ActiveRecord::RecordNotFound) do
        patch :refresh_file, params: { id: batch.id, file: csv_upload(csv_for("Tag Number", "PT0002A")) }
      end
    end

    test "destroy aborts the batch without deleting it" do
      batch = build_batch(csv: csv_for("Tag Number", "PT0001A"))
      delete :destroy, params: { id: batch.id }
      assert batch.reload.aborted?
      assert_redirected_to discipline_tags_path(@discipline)
    end
  end
end
