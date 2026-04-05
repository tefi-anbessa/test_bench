require "test_helper"
require "helpers/model_test_patterns"

module DocumentControl
  class DocTypeTest < ActiveSupport::TestCase
    include ModelTestPatterns

    def setup
      setup_common_test_data # in model_test_patterns.rb
      setup_model_specific_data
    end
    
    def setup_model_specific_data
      @resource = create(:document_control_doc_type, discipline: @resource_discipline, 
                        code: "DOC", label: "Test Document Type")
    end

    test "code must be present" do
      @resource.code = nil
      refute @resource.valid?
      assert_includes @resource.errors[:code], I18n.t("errors.messages.blank")
    end

    test "code must not be too long" do
      @resource.code = "a" * 7
      refute @resource.valid?
      assert_includes @resource.errors[:code], I18n.t("errors.messages.too_long", count: 6)
    end

    test "label must be present" do
      @resource.label = nil
      refute @resource.valid?
      assert_includes @resource.errors[:label], I18n.t("errors.messages.blank")
    end

    test "label must not be too long" do
      @resource.label = "a" * 51
      refute @resource.valid?
      assert_includes @resource.errors[:label], I18n.t("errors.messages.too_long", count: 50)
    end

    test "code must be unique within discipline" do
      duplicate = build(:document_control_doc_type, discipline: @resource_discipline, code: "DOC")
      refute duplicate.valid?
      assert_includes duplicate.errors[:code], I18n.t("errors.messages.taken")
    end

  end
end
