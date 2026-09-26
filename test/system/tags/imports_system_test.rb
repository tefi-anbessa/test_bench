require "application_system_test_case"
require "helpers/test_setup_helpers"

module Tags
  class ImportsSystemTest < ApplicationSystemTestCase
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

      visit new_discipline_tags_import_path(@discipline)
      attach_file "file", Rails.root.join("test/fixtures/files/import/tags_with_stage.csv")
      click_button I18n.t("tags.imports.new.submit")

      assert_current_path %r{/import_batches/\d+}
      assert_selector "select[name='column_mapping[Tag Number]']"

      # Auto-suggested mapping already gets this right without any manual
      # changes: "Tag Number" -> full_tag, "Service" -> service, "Notes" ->
      # notes (all label matches), and "Discipline" -> ignored (no matching
      # column in this context, since the discipline is fixed by the URL).
      assert_equal "full_tag", find_field("column_mapping[Tag Number]").value
      assert_equal "", find_field("column_mapping[Discipline]").value
      click_button I18n.t("import_batches.mapping.submit")

      assert_text I18n.t("import_batches.review.all_valid", count: 2)

      click_button I18n.t("import_batches.review.commit")

      assert_current_path discipline_tags_path(@discipline)
      assert_text I18n.t("import_batches.commit.notice", imported: 2, skipped: 0)
      assert_selector "td", text: "Pressure"
      assert_selector "td", text: "Flow"
    end
  end
end
