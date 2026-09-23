require "test_helper"
# require "helpers/model_test_patterns"
module ChangeManagement
  class RequestTest < ActiveSupport::TestCase
    # include ModelTestPatterns

    def setup
      @project = create(:project)
      @resource = create(:change_management_request)
      # Insert model specific test setup here, including relationships with other models.
      # E.g. setup electrical_demand for electrical models.
    end

    test "title must be present" do
      @resource.title = nil
      refute @resource.valid?
      assert_includes @resource.errors[:title], I18n.t("errors.messages.blank")
    end

  test "title should not be too long" do
    @resource.title = "a" * 256
    refute @resource.valid?
    assert_includes @resource.errors[:title], I18n.t("errors.messages.too_long", count: 255)
  end

    test "project must be present" do
      new_request = build(:change_management_request, project: nil)
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
  end
end
