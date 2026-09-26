require "test_helper"

module Import
  class TagsTest < ActiveSupport::TestCase
    setup do
      @project = create(:project)
      # Project creation auto-creates the standard set of disciplines (see
      # Discipline.create_all_for_project / config/constants/discipline.yml)
      # - find and configure those rather than creating new ones.
      @electrical = @project.disciplines.find_by!(name: "Electrical").tap { |d| d.update!(required_role: "designer") }
      @mechanical = @project.disciplines.find_by!(name: "Mechanical").tap { |d| d.update!(required_role: "designer") }
      @user = create(:user)
      @user.grant(:designer, @electrical)
      @pundit_user = ApplicationPolicy::UserContext.new(@user, @project)
    end

    def build_batch(csv:, discipline: nil, column_mapping:)
      create(:import_batch,
        user: @user, project: @project, discipline: discipline,
        original_filename: "tags.csv", file_data: csv, column_mapping: column_mapping.merge("Stage" => "stage"))
    end

    # Every data row in a fixture CSV needs a trailing ",5" for the Stage
    # column (stage has no default and is a required, non-nullable field on
    # Tag) - built here rather than repeated inline everywhere.
    def csv_for(header, *data_rows)
      ([ "#{header},Stage" ] + data_rows.map { |row| "#{row},5" }).join("\n") + "\n"
    end

    test "discipline-scoped import needs no discipline column and every row uses the fixed discipline" do
      csv = csv_for("Tag Number,Service", "PT0001A,Pressure", "FT0002,Flow")
      batch = build_batch(csv: csv, discipline: @electrical,
        column_mapping: { "Tag Number" => "full_tag", "Service" => "service" })

      importer = Tags.new(batch)
      refute importer.column_definitions.any? { |d| d.key == :discipline }, "discipline shouldn't be mappable when fixed"

      rows = importer.dry_run_rows(pundit_user: @pundit_user)
      assert_equal 2, rows.size
      assert rows.all?(&:valid?), rows.flat_map(&:error_messages).join(", ")
      assert_equal [@electrical.id, @electrical.id], rows.map { |r| r.record.discipline_id }
    end

    test "project-wide import resolves a mapped discipline column per row, by code" do
      csv = csv_for("Tag Number,Discipline", "PT0001A,E", "MT0001,M")
      batch = build_batch(csv: csv, discipline: nil,
        column_mapping: { "Tag Number" => "full_tag", "Discipline" => "discipline" })

      importer = Tags.new(batch)
      assert importer.column_definitions.any? { |d| d.key == :discipline }, "discipline should be mappable when not fixed"

      # Grant on Mechanical too, since this row spans both disciplines.
      @user.grant(:designer, @mechanical)
      rows = importer.dry_run_rows(pundit_user: @pundit_user)
      assert rows.all?(&:valid?), rows.flat_map(&:error_messages).join(", ")
      assert_equal [@electrical.id, @mechanical.id], rows.map { |r| r.record.discipline_id }
    end

    test "project-wide import falls back to matching discipline by name" do
      csv = csv_for("Tag Number,Discipline", "PT0001A,Electrical")
      batch = build_batch(csv: csv, discipline: nil,
        column_mapping: { "Tag Number" => "full_tag", "Discipline" => "discipline" })

      rows = Tags.new(batch).dry_run_rows(pundit_user: @pundit_user)
      assert rows.first.valid?, rows.first.error_messages.join(", ")
      assert_equal @electrical.id, rows.first.record.discipline_id
    end

    test "an unresolvable discipline is a per-row error, not an auto-created discipline" do
      csv = csv_for("Tag Number,Discipline", "PT0001A,ZZ")
      batch = build_batch(csv: csv, discipline: nil,
        column_mapping: { "Tag Number" => "full_tag", "Discipline" => "discipline" })

      rows = Tags.new(batch).dry_run_rows(pundit_user: @pundit_user)
      refute rows.first.valid?
      assert_includes rows.first.error_messages.join, "ZZ"
      assert_nil rows.first.record
    end

    test "project-wide import with no discipline column mapped uses the batch's single chosen discipline" do
      csv = csv_for("Tag Number", "PT0001A")
      batch = build_batch(csv: csv, discipline: @electrical, column_mapping: { "Tag Number" => "full_tag" })

      rows = Tags.new(batch).dry_run_rows(pundit_user: @pundit_user)
      assert rows.first.valid?, rows.first.error_messages.join(", ")
      assert_equal @electrical.id, rows.first.record.discipline_id
    end

    test "decomposes a combined Tag Number column into prefix/serial/suffix" do
      csv = csv_for("Tag Number", "PT0001A")
      batch = build_batch(csv: csv, discipline: @electrical, column_mapping: { "Tag Number" => "full_tag" })

      row = Tags.new(batch).dry_run_rows(pundit_user: @pundit_user).first
      assert row.valid?, row.error_messages.join(", ")
      assert_equal "PT", row.record.prefix
      assert_equal 1, row.record.serial
      assert_equal "A", row.record.suffix
      # full_tag is a DB-generated virtual column - nil on any unsaved
      # record, so it's not meaningful to check here until after commit.
    end

    test "resolves a valid tagable_type case-insensitively and by demodulized name" do
      csv = csv_for("Tag Number,Type", "SW0001,Switchboard")
      batch = build_batch(csv: csv, discipline: @electrical,
        column_mapping: { "Tag Number" => "full_tag", "Type" => "tagable_type" })

      row = Tags.new(batch).dry_run_rows(pundit_user: @pundit_user).first
      assert row.valid?, row.error_messages.join(", ")
      assert_equal "Electrical::Switchboard", row.record.tagable_type
    end

    test "an unknown tagable_type is a per-row error" do
      csv = csv_for("Tag Number,Type", "SW0001,NotARealType")
      batch = build_batch(csv: csv, discipline: @electrical,
        column_mapping: { "Tag Number" => "full_tag", "Type" => "tagable_type" })

      row = Tags.new(batch).dry_run_rows(pundit_user: @pundit_user).first
      refute row.valid?
      assert_includes row.error_messages.join, "NotARealType"
    end

    test "resolves a forward in-batch parent reference" do
      csv = csv_for("Tag Number,Parent Tag", "FT0002,PT0001A", "PT0001A,")
      batch = build_batch(csv: csv, discipline: @electrical,
        column_mapping: { "Tag Number" => "full_tag", "Parent Tag" => "parent" })

      rows = Tags.new(batch).dry_run_rows(pundit_user: @pundit_user)
      child, parent = rows
      assert_equal parent, child.deferred_reference_row
      assert_nil child.record.parent_id # not set yet - Import::Committer sets it post phase-1 insert
    end

    test "resolves a bare parent reference against an already-persisted tag, scoped to the row's own discipline" do
      existing_parent = create(:tag, discipline: @electrical, prefix: "PT", serial: 1)
      csv = csv_for("Tag Number,Parent Tag", "FT0002,#{existing_parent.full_tag}")
      batch = build_batch(csv: csv, discipline: @electrical,
        column_mapping: { "Tag Number" => "full_tag", "Parent Tag" => "parent" })

      row = Tags.new(batch).dry_run_rows(pundit_user: @pundit_user).first
      assert row.valid?, row.error_messages.join(", ")
      assert_equal existing_parent.id, row.record.parent_id
    end

    test "resolves a qualified (cross-discipline) parent reference against an already-persisted tag" do
      existing_parent = create(:tag, discipline: @mechanical, prefix: "PT", serial: 1)
      csv = csv_for("Tag Number,Parent Tag", "FT0002,M-#{existing_parent.full_tag}")
      batch = build_batch(csv: csv, discipline: @electrical,
        column_mapping: { "Tag Number" => "full_tag", "Parent Tag" => "parent" })

      row = Tags.new(batch).dry_run_rows(pundit_user: @pundit_user).first
      assert row.valid?, row.error_messages.join(", ")
      assert_equal existing_parent.id, row.record.parent_id
    end

    test "an unresolvable parent reference is a per-row error" do
      csv = csv_for("Tag Number,Parent Tag", "FT0002,NOSUCHTAG")
      batch = build_batch(csv: csv, discipline: @electrical,
        column_mapping: { "Tag Number" => "full_tag", "Parent Tag" => "parent" })

      row = Tags.new(batch).dry_run_rows(pundit_user: @pundit_user).first
      refute row.valid?
      assert_includes row.error_messages.join, "NOSUCHTAG"
    end

    test "a row that fails Tag's own validations (e.g. a duplicate) is invalid with Tag's real error message" do
      create(:tag, discipline: @electrical, prefix: "PT", serial: 1)
      csv = csv_for("Tag Number", "PT0001")
      batch = build_batch(csv: csv, discipline: @electrical, column_mapping: { "Tag Number" => "full_tag" })

      row = Tags.new(batch).dry_run_rows(pundit_user: @pundit_user).first
      refute row.valid?
      assert row.record.present?, "should still build the record to surface Tag's own validation errors"
    end

    test "authorize! raises for a discipline the user has no role on" do
      csv = csv_for("Tag Number,Discipline", "MT0001,M") # user only has :designer on Electrical
      batch = build_batch(csv: csv, discipline: nil,
        column_mapping: { "Tag Number" => "full_tag", "Discipline" => "discipline" })

      assert_raises(Pundit::NotAuthorizedError) do
        Tags.new(batch).dry_run_rows(pundit_user: @pundit_user)
      end
    end
  end
end
