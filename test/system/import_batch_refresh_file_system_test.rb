require "application_system_test_case"
require "helpers/test_setup_helpers"

# Feature B of the refresh-file/create-tag-together plan: lets a user swap
# in a corrected file for a batch without restarting the whole wizard - see
# Import::BatchesController#refresh_file.
class ImportBatchRefreshFileSystemTest < ApplicationSystemTestCase
  include Devise::Test::IntegrationHelpers
  include Warden::Test::Helpers
  include TestSetupHelpers

  setup do
    setup_projects_and_users
    setup_disciplines(name: "Electrical", required_role: :designer)
    setup_accredited_users(:designer)
  end

  test "refreshing the file from the review screen re-enters mapping and completes the import" do
    sign_in @accredited_user
    ApplicationController.any_instance.stubs(:current_project).returns(@project)

    visit import_discipline_tags_path(@discipline)
    attach_file "file", Rails.root.join("test/fixtures/files/import/tags_for_refresh_bad.csv")
    click_button I18n.t("import.upload_form.submit")

    assert_current_path %r{/import/batches/\d+}
    assert_selector "select[name='column_mapping[Tag Number]']"
    click_button I18n.t("import.batches.mapping.submit")

    assert_text I18n.t("import.batches.review.some_invalid", valid: 1, invalid: 1)

    attach_file "file", Rails.root.join("test/fixtures/files/import/tags_for_refresh_corrected.csv")
    click_button I18n.t("import.batches.review.refresh_file_submit")

    assert_selector "select[name='column_mapping[Tag Number]']"
    assert_equal "full_tag", find_field("column_mapping[Tag Number]").value
    click_button I18n.t("import.batches.mapping.submit")

    assert_text I18n.t("import.batches.review.all_valid", count: 2)
    click_button I18n.t("import.batches.review.commit")

    assert_current_path discipline_tags_path(@discipline)
    assert_selector "td", text: "Pressure Transmitter"
    assert_selector "td", text: "Fixed Row"
  end

  test "refreshing with an unsupported file format re-renders review with an alert" do
    sign_in @accredited_user
    ApplicationController.any_instance.stubs(:current_project).returns(@project)

    visit import_discipline_tags_path(@discipline)
    attach_file "file", Rails.root.join("test/fixtures/files/import/tags_for_refresh_corrected.csv")
    click_button I18n.t("import.upload_form.submit")
    click_button I18n.t("import.batches.mapping.submit")

    assert_text I18n.t("import.batches.review.all_valid", count: 2)

    attach_file "file", Rails.root.join("test/fixtures/files/import/tags.pdf")
    click_button I18n.t("import.batches.review.refresh_file_submit")

    assert_text I18n.t("import.batches.review.all_valid", count: 2)
    assert_selector ".alert"
  end
end
