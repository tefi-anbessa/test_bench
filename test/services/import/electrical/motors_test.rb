require "test_helper"

# Hand-written unit tests for the reference tagable importer,
# Import::Electrical::Motors (see app/services/import/electrical/motors.rb).
# Every other tagable importer's own generated tests mirror this file's
# structure - see test/services/import/electrical/heaters_test.rb for a
# generator-produced example.
class Electrical::MotorsTest < ActiveSupport::TestCase
  setup do
    @project = create(:project)
    # Project creation auto-creates the standard set of disciplines (see
    # Discipline.create_all_for_project) - find and configure one rather
    # than creating a new one.
    @electrical = @project.disciplines.find_by!(name: "Electrical").tap { |d| d.update!(required_role: "designer") }
    @user = create(:user)
    @user.grant(:designer, @electrical)
    @pundit_user = ApplicationPolicy::UserContext.new(@user, @project)
  end

  # An existing, persisted, unassigned tag of the right type - as if
  # bulk-imported via Import::Tags already, with tagable_type set and
  # deliberately left unassigned for this importer to attach to.
  def orphaned_tag(prefix: "MTR", serial: 1)
    create(:tag, :unique_tag, discipline: @electrical, prefix: prefix, serial: serial, suffix: "", tagable_type: "Electrical::Motor")
  end

  def build_batch(csv:, column_mapping:, create_missing_tags: false)
    create(:import_batch,
      user: @user, project: @project, discipline: @electrical,
      original_filename: "motors.csv", file_data: csv, column_mapping: column_mapping,
      create_missing_tags: create_missing_tags)
  end

  def default_mapping
    { "Tag" => "full_tag", "Motor Type" => "motor_type", "Frame Size" => "frame_size" }
  end

  # Tag#stage has no allow_nil on its numericality validation, so creating a
  # brand-new Tag (unlike attaching to one that already exists) always needs
  # it mapped from somewhere.
  def create_mapping
    default_mapping.merge("Stage" => "tag_stage")
  end

  test "resolves an existing, unassigned, correctly-typed tag by bare full_tag" do
    tag = orphaned_tag
    csv = "Tag,Motor Type,Frame Size\n#{tag.full_tag},induction,100\n"
    batch = build_batch(csv: csv, column_mapping: default_mapping)

    importer = Import::Electrical::Motors.new(batch)
    rows = importer.dry_run_rows(pundit_user: @pundit_user)

    assert_equal 1, rows.size
    assert rows.all?(&:valid?), rows.flat_map(&:error_messages).join(", ")
  end

  test "a spreadsheet-cased enum value still coerces to the correct enum key" do
    tag = orphaned_tag
    csv = "Tag,Motor Type,Frame Size\n#{tag.full_tag},Induction,100\n"
    batch = build_batch(csv: csv, column_mapping: default_mapping)

    rows = Import::Electrical::Motors.new(batch).dry_run_rows(pundit_user: @pundit_user)

    assert rows.all?(&:valid?), rows.flat_map(&:error_messages).join(", ")
    assert_equal "induction", rows.first.record.motor_type
  end

  test "tag not found is a hard per-row error" do
    csv = "Tag,Motor Type,Frame Size\nNOPE9999,induction,100\n"
    batch = build_batch(csv: csv, column_mapping: default_mapping)

    rows = Import::Electrical::Motors.new(batch).dry_run_rows(pundit_user: @pundit_user)
    refute rows.first.valid?
    assert_match "not found", rows.first.error_messages.join
  end

  test "a tag already assigned to another tagable is a hard per-row error" do
    tag = orphaned_tag
    create(:electrical_motor, tag: tag)
    csv = "Tag,Motor Type,Frame Size\n#{tag.full_tag},induction,100\n"
    batch = build_batch(csv: csv, column_mapping: default_mapping)

    rows = Import::Electrical::Motors.new(batch).dry_run_rows(pundit_user: @pundit_user)
    refute rows.first.valid?
    assert_match "already assigned", rows.first.error_messages.join
  end

  test "a tag registered as the wrong tagable_type is a hard per-row error" do
    tag = create(:tag, :unique_tag, discipline: @electrical, prefix: "MTR", serial: 2, suffix: "", tagable_type: "Electrical::Heater")
    csv = "Tag,Motor Type,Frame Size\n#{tag.full_tag},induction,100\n"
    batch = build_batch(csv: csv, column_mapping: default_mapping)

    rows = Import::Electrical::Motors.new(batch).dry_run_rows(pundit_user: @pundit_user)
    refute rows.first.valid?
    assert_match "registered as", rows.first.error_messages.join
  end

  test "authorize! rejects a user without a role on the resolved tag's discipline" do
    tag = orphaned_tag
    other_user = create(:user)
    other_pundit_user = ApplicationPolicy::UserContext.new(other_user, @project)
    csv = "Tag,Motor Type,Frame Size\n#{tag.full_tag},induction,100\n"
    batch = build_batch(csv: csv, column_mapping: default_mapping)

    assert_raises(Pundit::NotAuthorizedError) { Import::Electrical::Motors.new(batch).dry_run_rows(pundit_user: other_pundit_user) }
  end

  test "commit links the tagable to the resolved tag" do
    tag = orphaned_tag
    csv = "Tag,Motor Type,Frame Size\n#{tag.full_tag},induction,100\n"
    batch = build_batch(csv: csv, column_mapping: default_mapping)
    importer = Import::Electrical::Motors.new(batch)
    rows = importer.dry_run_rows(pundit_user: @pundit_user)

    Import::Committer.new(importer: importer, rows: rows, partial: false).call

    tag.reload
    assert_equal "Electrical::Motor", tag.tagable_type
    assert tag.tagable_id.present?
  end

  test "commit also sets any mapped Tag-level fields (Service/Stage/Location/Tag Notes) on the resolved tag" do
    tag = orphaned_tag
    csv = "Tag,Service,Stage,Motor Type,Frame Size\n#{tag.full_tag},RIVER WATER LIFTING PUMP,3,induction,100\n"
    batch = build_batch(csv: csv, column_mapping: default_mapping.merge("Service" => "tag_service", "Stage" => "tag_stage"))
    importer = Import::Electrical::Motors.new(batch)
    rows = importer.dry_run_rows(pundit_user: @pundit_user)

    Import::Committer.new(importer: importer, rows: rows, partial: false).call

    tag.reload
    assert_equal "RIVER WATER LIFTING PUMP", tag.service
    assert_equal 3, tag.stage
  end

  test "a blank mapped Tag-level cell does not overwrite an existing Tag value" do
    tag = orphaned_tag
    tag.update!(service: "EXISTING SERVICE")
    csv = "Tag,Service,Motor Type,Frame Size\n#{tag.full_tag},,induction,100\n"
    batch = build_batch(csv: csv, column_mapping: default_mapping.merge("Service" => "tag_service"))
    importer = Import::Electrical::Motors.new(batch)
    rows = importer.dry_run_rows(pundit_user: @pundit_user)

    Import::Committer.new(importer: importer, rows: rows, partial: false).call

    tag.reload
    assert_equal "EXISTING SERVICE", tag.service
  end

  test "create_missing_tags off still hard-errors on a tag that doesn't exist (regression)" do
    csv = "Tag,Motor Type,Frame Size\nMTR0099,induction,100\n"
    batch = build_batch(csv: csv, column_mapping: default_mapping, create_missing_tags: false)

    rows = Import::Electrical::Motors.new(batch).dry_run_rows(pundit_user: @pundit_user)
    refute rows.first.valid?
    assert_match "not found", rows.first.error_messages.join
  end

  test "create_missing_tags on builds a new, unsaved tag for a reference that doesn't exist" do
    csv = "Tag,Motor Type,Frame Size,Stage\nMTR0099,induction,100,5\n"
    batch = build_batch(csv: csv, column_mapping: create_mapping, create_missing_tags: true)

    rows = Import::Electrical::Motors.new(batch).dry_run_rows(pundit_user: @pundit_user)

    assert rows.first.valid?, rows.first.error_messages.join(", ")
    refute Tag.exists?(discipline: @electrical, prefix: "MTR", serial: 99)
  end

  test "create_missing_tags on still rejects a malformed tag reference" do
    csv = "Tag,Motor Type,Frame Size,Stage\nNOT-A-TAG,induction,100,5\n"
    batch = build_batch(csv: csv, column_mapping: create_mapping, create_missing_tags: true)

    rows = Import::Electrical::Motors.new(batch).dry_run_rows(pundit_user: @pundit_user)
    refute rows.first.valid?
    assert_match "isn't a valid tag format", rows.first.error_messages.join
  end

  test "create_missing_tags on rejects two rows referencing the same new tag" do
    csv = "Tag,Motor Type,Frame Size,Stage\nMTR0099,induction,100,5\nMTR0099,induction,112,5\n"
    batch = build_batch(csv: csv, column_mapping: create_mapping, create_missing_tags: true)

    rows = Import::Electrical::Motors.new(batch).dry_run_rows(pundit_user: @pundit_user)
    assert rows.first.valid?, rows.first.error_messages.join(", ")
    refute rows.second.valid?
    assert_match "referenced by more than one row", rows.second.error_messages.join
  end

  test "create_missing_tags on still hard-errors on a tag that exists but is already assigned" do
    tag = orphaned_tag
    create(:electrical_motor, tag: tag)
    csv = "Tag,Motor Type,Frame Size\n#{tag.full_tag},induction,100\n"
    batch = build_batch(csv: csv, column_mapping: default_mapping, create_missing_tags: true)

    rows = Import::Electrical::Motors.new(batch).dry_run_rows(pundit_user: @pundit_user)
    refute rows.first.valid?
    assert_match "already assigned", rows.first.error_messages.join
  end

  test "create_missing_tags on creates and links a brand-new tag at commit" do
    csv = "Tag,Motor Type,Frame Size,Stage\nMTR0099,induction,100,5\n"
    batch = build_batch(csv: csv, column_mapping: create_mapping, create_missing_tags: true)
    importer = Import::Electrical::Motors.new(batch)
    rows = importer.dry_run_rows(pundit_user: @pundit_user)

    assert_difference("Tag.count", 1) do
      Import::Committer.new(importer: importer, rows: rows, partial: false).call
    end

    tag = Tag.find_by!(discipline: @electrical, prefix: "MTR", serial: 99)
    assert_equal "Electrical::Motor", tag.tagable_type
    assert tag.tagable_id.present?
  end

  test "create_missing_tags on rolls back cleanly if the same tag is created elsewhere before commit" do
    csv = "Tag,Motor Type,Frame Size,Stage\nMTR0099,induction,100,5\n"
    batch = build_batch(csv: csv, column_mapping: create_mapping, create_missing_tags: true)
    importer = Import::Electrical::Motors.new(batch)
    rows = importer.dry_run_rows(pundit_user: @pundit_user)

    # Simulate someone else creating the exact same tag via the ordinary
    # manual UI between dry-run (review) and commit.
    create(:tag, discipline: @electrical, prefix: "MTR", serial: 99, suffix: "")

    assert_no_difference("Electrical::Motor.count") do
      assert_raises(Import::Committer::InvalidRowsError) do
        Import::Committer.new(importer: importer, rows: rows, partial: false).call
      end
    end
  end

  test "a race where the tag is claimed between dry-run and commit fails the whole commit cleanly" do
    tag = orphaned_tag
    csv = "Tag,Motor Type,Frame Size\n#{tag.full_tag},induction,100\n"
    batch = build_batch(csv: csv, column_mapping: default_mapping)
    importer = Import::Electrical::Motors.new(batch)
    rows = importer.dry_run_rows(pundit_user: @pundit_user)

    # Simulate someone else claiming the tag via the ordinary manual UI
    # between dry-run (review) and commit.
    create(:electrical_motor, tag: tag)

    assert_raises(Import::Committer::InvalidRowsError) do
      Import::Committer.new(importer: importer, rows: rows, partial: false).call
    end
  end
end
