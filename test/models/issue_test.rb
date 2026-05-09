require "test_helper"
require "helpers/model_test_patterns"
class IssueTest < ActiveSupport::TestCase
    include ModelTestPatterns

    def setup
      setup_common_test_data
      setup_model_specific_data
    end
    
    def setup_model_specific_data
      @resource = create(:issue)
      # Insert model specific test setup here, including relationships with other models.
      # E.g. setup electrical_demand for electrical models.
    end

    test "document must be present" do
      @resource.document = nil
      refute @resource.valid?
      assert_includes @resource.errors[:document], I18n.t("errors.messages.required")
    end

    test "code must be present" do
      @resource.code = nil
      refute @resource.valid?
      assert_includes @resource.errors[:code], I18n.t("errors.messages.blank")
    end

    test "reason must be present" do
      @resource.reason = nil
      refute @resource.valid?
      assert_includes @resource.errors[:reason], I18n.t("errors.messages.blank")
    end

    test "code must not be too long" do
      @resource.code = "a" * 11
      refute @resource.valid?
      assert_includes @resource.errors[:code], I18n.t("errors.messages.too_long", count: 10)
    end

    test "reason must not be too long" do
      @resource.reason = "a" * 51
      refute @resource.valid?
      assert_includes @resource.errors[:reason], I18n.t("errors.messages.too_long", count: 50)
    end

  end
