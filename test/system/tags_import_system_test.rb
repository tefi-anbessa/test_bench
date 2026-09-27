require "application_system_test_case"
require "helpers/test_setup_helpers"

class TagsImportSystemTest < ApplicationSystemTestCase
  include Devise::Test::IntegrationHelpers
  include Warden::Test::Helpers
  include TestSetupHelpers

  def resource_class
    Tag
  end

  setup do
    setup_projects_and_users
    setup_disciplines(name: "Electrical", required_role: :designer)
    setup_accredited_users(:designer)
  end

  test "uploading, mapping, reviewing and committing a discipline-scoped tag import" do
    sign_in @accredited_user
    ApplicationController.any_instance.stubs(:current_project).returns(@project)

    visit import_discipline_tags_path(@discipline)
    attach_file "file", Rails.root.join("test/fixtures/files/import/tags_with_stage.csv")
    click_button I18n.t("import.upload_form.submit")

    assert_current_path %r{/import/batches/\d+}
    assert_selector "select[name='column_mapping[Tag Number]']"

    # Auto-suggested mapping already gets this right without any manual
    # changes: "Tag Number" -> full_tag, "Service" -> service, "Notes" ->
    # notes (all label matches), and "Discipline" -> ignored (no matching
    # column in this context, since the discipline is fixed by the URL).
    assert_equal "full_tag", find_field("column_mapping[Tag Number]").value
    assert_equal "", find_field("column_mapping[Discipline]").value
    click_button I18n.t("import.batches.mapping.submit")

    assert_text I18n.t("import.batches.review.all_valid", count: 2)

    click_button I18n.t("import.batches.review.commit")

    assert_current_path discipline_tags_path(@discipline)
    assert_text I18n.t("import.batches.commit.notice", imported: 2, skipped: 0)
    assert_selector "td", text: "Pressure"
    assert_selector "td", text: "Flow"
  end

  test "a blank spacer column in the sheet doesn't break the mapping form" do
    sign_in @accredited_user
    ApplicationController.any_instance.stubs(:current_project).returns(@project)

    visit import_discipline_tags_path(@discipline)
    attach_file "file", Rails.root.join("test/fixtures/files/import/tags_with_blank_column.csv")
    click_button I18n.t("import.upload_form.submit")

    assert_current_path %r{/import/batches/\d+}
    assert_selector "select[name='column_mapping[Tag Number]']"
    click_button I18n.t("import.batches.mapping.submit")

    assert_text I18n.t("import.batches.review.all_valid", count: 2)
    click_button I18n.t("import.batches.review.commit")

    assert_current_path discipline_tags_path(@discipline)
    assert_selector "td", text: "Pressure"
  end

  test "uploading a multi-sheet file prompts for a worksheet before mapping columns" do
    sign_in @accredited_user
    ApplicationController.any_instance.stubs(:current_project).returns(@project)

    visit import_discipline_tags_path(@discipline)
    attach_file "file", Rails.root.join("test/fixtures/files/import/tags_multi_sheet.xlsx")
    click_button I18n.t("import.upload_form.submit")

    assert_current_path %r{/import/batches/\d+}
    assert_text I18n.t("import.batches.select_sheet.help")
    assert_selector "option", text: "Electrical"
    assert_selector "option", text: "Mechanical"

    select "Mechanical", from: "sheet_name"
    click_button I18n.t("import.batches.select_sheet.submit")

    assert_selector "select[name='column_mapping[Tag Number]']"
    assert_equal "full_tag", find_field("column_mapping[Tag Number]").value
    click_button I18n.t("import.batches.mapping.submit")

    assert_text I18n.t("import.batches.review.all_valid", count: 1)
    click_button I18n.t("import.batches.review.commit")

    assert_current_path discipline_tags_path(@discipline)
    assert_selector "td", text: "Flow Transmitter"
    assert_no_selector "td", text: "Pressure Transmitter"
  end

  test "cancelling from the mapping screen falls back to worksheet selection, not a full abort" do
    sign_in @accredited_user
    ApplicationController.any_instance.stubs(:current_project).returns(@project)

    visit import_discipline_tags_path(@discipline)
    attach_file "file", Rails.root.join("test/fixtures/files/import/tags_multi_sheet.xlsx")
    click_button I18n.t("import.upload_form.submit")
    assert_current_path %r{/import/batches/\d+}
    batch_id = current_path[%r{/import/batches/(\d+)}, 1]

    select "Mechanical", from: "sheet_name"
    click_button I18n.t("import.batches.select_sheet.submit")
    assert_selector "select[name='column_mapping[Tag Number]']"

    click_link I18n.t("actions.cancel")

    assert_selector "select[name='sheet_name']"
    refute Import::Batch.find(batch_id).aborted?
    assert_nil Import::Batch.find(batch_id).sheet_name

    select "Electrical", from: "sheet_name"
    click_button I18n.t("import.batches.select_sheet.submit")
    assert_selector "select[name='column_mapping[Tag Number]']"
  end

  test "discarding from the mapping screen aborts the batch and imports nothing" do
    sign_in @accredited_user
    ApplicationController.any_instance.stubs(:current_project).returns(@project)

    visit import_discipline_tags_path(@discipline)
    attach_file "file", Rails.root.join("test/fixtures/files/import/tags_with_stage.csv")
    click_button I18n.t("import.upload_form.submit")
    assert_current_path %r{/import/batches/\d+}
    batch_id = current_path[%r{/import/batches/(\d+)}, 1]

    accept_confirm { click_link I18n.t("actions.cancel") }

    assert_current_path discipline_tags_path(@discipline)
    assert_text I18n.t("import.batches.destroy.notice")
    assert Import::Batch.find(batch_id).aborted?
    assert_no_selector "td", text: "Pressure"
  end

  test "discarding from the review screen aborts the batch and imports nothing" do
    sign_in @accredited_user
    ApplicationController.any_instance.stubs(:current_project).returns(@project)

    visit import_discipline_tags_path(@discipline)
    attach_file "file", Rails.root.join("test/fixtures/files/import/tags_with_stage.csv")
    click_button I18n.t("import.upload_form.submit")
    assert_current_path %r{/import/batches/\d+}
    batch_id = current_path[%r{/import/batches/(\d+)}, 1]
    click_button I18n.t("import.batches.mapping.submit")

    assert_text I18n.t("import.batches.review.all_valid", count: 2)
    accept_confirm { click_link I18n.t("actions.cancel") }

    assert_current_path discipline_tags_path(@discipline)
    assert Import::Batch.find(batch_id).aborted?
    assert_no_selector "td", text: "Pressure"
  end
end
