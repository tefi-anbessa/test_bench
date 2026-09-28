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

    # A minimal fake importer, isolated from Import::Tags entirely, just to
    # exercise Import::Committer's own after_commit_row/error-wrapping
    # behavior (see Import::TagableBase, which relies on both).
    class FakeImporter < Base
      attr_accessor :after_commit_row_calls, :raise_in_after_commit_row

      def initialize
        @after_commit_row_calls = []
        @raise_in_after_commit_row = false
      end

      def model_class = Tag
      def column_definitions = []
      def permitted_attributes = []
      def resolve_foreign_keys(row, context:) = nil
      def authorize!(rows, pundit_user:) = nil

      def after_commit_row(row)
        raise "boom" if raise_in_after_commit_row
        after_commit_row_calls << row
      end
    end

    def fake_row(discipline)
      row = Row.new(row_number: 1, raw: {})
      row.record = build(:tag, discipline: discipline)
      row
    end

    test "after_commit_row runs once per committed row, after that row's own save" do
      importer = FakeImporter.new
      row = fake_row(@electrical)
      refute row.record.persisted?

      Committer.new(importer: importer, rows: [row], partial: false).call

      assert row.record.persisted?
      assert_equal [row], importer.after_commit_row_calls
    end

    test "a raising after_commit_row rolls back the whole commit and surfaces as InvalidRowsError" do
      importer = FakeImporter.new
      importer.raise_in_after_commit_row = true
      row = fake_row(@electrical)

      assert_raises(Committer::InvalidRowsError) do
        Committer.new(importer: importer, rows: [row], partial: false).call
      end
      refute row.record.persisted?
      assert_equal 0, Tag.where(discipline: @electrical).count
    end
  end
end
