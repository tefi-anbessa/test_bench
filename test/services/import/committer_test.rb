require "test_helper"

module Import
  class CommitterTest < ActiveSupport::TestCase
    setup do
      @project = create(:project)
      @electrical = @project.disciplines.find_by!(name: "Electrical").tap { |d| d.update!(required_role: "designer") }
      @user = create(:user)
      @user.grant(:designer, @electrical)
      @pundit_user = ApplicationPolicy::UserContext.new(@user, @project)
    end

    def csv_for(header, *data_rows)
      ([ "#{header},Stage" ] + data_rows.map { |row| "#{row},5" }).join("\n") + "\n"
    end

    def dry_run(csv, column_mapping)
      batch = create(:import_batch,
        user: @user, project: @project, discipline: @electrical,
        original_filename: "tags.csv", file_data: csv, column_mapping: column_mapping.merge("Stage" => "stage"))
      importer = Tags.new(batch)
      [importer, importer.dry_run_rows(pundit_user: @pundit_user)]
    end

    test "strict mode commits every row when all are valid" do
      csv = csv_for("Tag Number", "PT0001A", "FT0002")
      importer, rows = dry_run(csv, { "Tag Number" => "full_tag" })

      result = Committer.new(importer: importer, rows: rows, partial: false).call
      assert_equal 2, result.imported_count
      assert_equal 0, result.skipped_count
      assert_equal 2, Tag.where(discipline: @electrical).count
    end

    test "strict mode raises and commits nothing when any row is invalid" do
      create(:tag, discipline: @electrical, prefix: "PT", serial: 1)
      csv = csv_for("Tag Number", "PT0001", "FT0002") # PT0001 duplicates the existing tag
      importer, rows = dry_run(csv, { "Tag Number" => "full_tag" })

      assert_raises(Committer::InvalidRowsError) do
        Committer.new(importer: importer, rows: rows, partial: false).call
      end
      # Only the pre-existing tag - FT0002 was never saved despite being valid.
      assert_equal 1, Tag.where(discipline: @electrical).count
    end

    test "partial mode commits only the valid rows" do
      create(:tag, discipline: @electrical, prefix: "PT", serial: 1)
      csv = csv_for("Tag Number", "PT0001", "FT0002") # PT0001 duplicates the existing tag
      importer, rows = dry_run(csv, { "Tag Number" => "full_tag" })

      result = Committer.new(importer: importer, rows: rows, partial: true).call
      assert_equal 1, result.imported_count
      assert_equal 1, result.skipped_count
      assert_equal 2, Tag.where(discipline: @electrical).count # the pre-existing one plus FT0002
    end

    test "two-phase commit links an in-batch forward parent reference to the real persisted id" do
      csv = csv_for("Tag Number,Parent Tag", "FT0002,PT0001A", "PT0001A,")
      importer, rows = dry_run(csv, { "Tag Number" => "full_tag", "Parent Tag" => "parent" })

      Committer.new(importer: importer, rows: rows, partial: false).call

      child = Tag.find_by!(discipline: @electrical, prefix: "FT", serial: 2)
      parent = Tag.find_by!(discipline: @electrical, prefix: "PT", serial: 1)
      assert_equal parent.id, child.parent_id
    end

    test "partial mode cascades a skip to a row whose in-batch parent reference was itself invalid" do
      create(:tag, discipline: @electrical, prefix: "PT", serial: 1) # makes the batch's own PT0001 a true duplicate (same prefix/serial/blank suffix)
      csv = csv_for("Tag Number,Parent Tag", "FT0002,PT0001", "PT0001,")
      importer, rows = dry_run(csv, { "Tag Number" => "full_tag", "Parent Tag" => "parent" })

      result = Committer.new(importer: importer, rows: rows, partial: true).call
      # The batch's own PT0001 row is invalid (duplicate); FT0002 references
      # it in-batch, so it must be skipped too, not committed with no parent.
      assert_equal 0, result.imported_count
      assert_equal 2, result.skipped_count
      assert_equal 1, Tag.where(discipline: @electrical).count # only the pre-existing PT0001
    end
  end
end
