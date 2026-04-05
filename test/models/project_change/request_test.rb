require "test_helper"
require "helpers/model_test_patterns"
module ProjectChange
  class RequestTest < ActiveSupport::TestCase
    include ModelTestPatterns

    def setup
      setup_common_test_data
      setup_model_specific_data
    end
    
    def setup_model_specific_data
      @resource = create(:project_change_request)
      # Insert model specific test setup here, including relationships with other models.
      # E.g. setup electrical_demand for electrical models.
    end

    test "project must be present" do
      new_request = build(:project_change_request, project: nil)
      refute new_request.valid?
      assert_includes new_request.errors[:project], I18n.t("errors.messages.required")
    end

    test "reason must be present" do
      @resource.reason = nil
      refute @resource.valid?
      assert_includes @resource.errors[:reason], I18n.t("errors.messages.blank")
    end

    test "summary must be present" do
      @resource.summary = nil
      refute @resource.valid?
      assert_includes @resource.errors[:summary], I18n.t("errors.messages.blank")
    end
    
    test "duration must be present" do
      @resource.duration = nil
      refute @resource.valid?
      assert_includes @resource.errors[:duration], I18n.t("errors.messages.blank")
    end

    test "project_id is read-only after creation" do
      assert_raises(ActiveRecord::ReadonlyAttributeError) do
        @resource.update(project_id: create(:project).id)
      end
    end

    test "serial is read-only after creation" do
      assert_raises(ActiveRecord::ReadonlyAttributeError) do
        @resource.update(serial: 999)
      end
    end

    # Insert model specific tests here.
    # E.g. test electrical_demand for electrical models.

  end
end
