require "application_system_test_case"
require "helpers/test_setup_helpers"

module Electrical
  class MotorsImportSystemTest < ApplicationSystemTestCase
    include Devise::Test::IntegrationHelpers
    include Warden::Test::Helpers
    include TestSetupHelpers

    def resource_class
      Electrical::Motor
    end

    setup do
      setup_projects_and_users
      setup_disciplines(name: "Electrical", required_role: :designer)
      setup_accredited_users(:designer)
      # Orphaned, Motor-typed tag - as if bulk-imported via Import::Tags
      # already, and left deliberately unassigned for this step to attach to.
      @unassigned_tag = create(:tag, :unique_tag, discipline: @discipline, prefix: "MTR", suffix: "",
        tagable_type: "Electrical::Motor")
    end

    test "uploading and committing a motor-details import attaches to the existing unassigned tag" do
      sign_in @accredited_user
      ApplicationController.any_instance.stubs(:current_project).returns(@project)

      visit import_discipline_tagables_path(@discipline, tagable_type: "Electrical::Motor")
      attach_file "file", Rails.root.join("test/fixtures/files/import/motors.csv")
      click_button I18n.t("import.upload_form.submit")

      assert_current_path %r{/import/batches/\d+}
      assert_selector "select[name='column_mapping[Tag]']"
      click_button I18n.t("import.batches.mapping.submit")

      assert_text I18n.t("import.batches.review.all_valid", count: 1)
      click_button I18n.t("import.batches.review.commit")

      assert_current_path discipline_tagables_path(@discipline, tagable_type: "Electrical::Motor")
      @unassigned_tag.reload
      assert_equal "Electrical::Motor", @unassigned_tag.tagable_type
      assert @unassigned_tag.tagable_id.present?
      assert_equal "induction", @unassigned_tag.tagable.motor_type
    end

    test "checking create missing tags creates a new tag and motor together" do
      sign_in @accredited_user
      ApplicationController.any_instance.stubs(:current_project).returns(@project)

      visit import_discipline_tagables_path(@discipline, tagable_type: "Electrical::Motor")
      attach_file "file", Rails.root.join("test/fixtures/files/import/motors_new_tag.csv")
      click_button I18n.t("import.upload_form.submit")

      assert_current_path %r{/import/batches/\d+}
      assert_selector "select[name='column_mapping[Tag]']"
      check I18n.t("import.batches.mapping.create_missing_tags_label")
      click_button I18n.t("import.batches.mapping.submit")

      assert_text I18n.t("import.batches.review.all_valid", count: 1)
      click_button I18n.t("import.batches.review.commit")

      assert_current_path discipline_tagables_path(@discipline, tagable_type: "Electrical::Motor")
      tag = Tag.find_by!(discipline: @discipline, prefix: "MTR", serial: 99)
      assert_equal "Electrical::Motor", tag.tagable_type
      assert tag.tagable_id.present?
      assert_equal "induction", tag.tagable.motor_type
    end
  end
end
