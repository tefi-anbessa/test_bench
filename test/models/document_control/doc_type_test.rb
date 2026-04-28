require "test_helper"
require "helpers/discipline_model_tests"

module DocumentControl
  class DocTypeTest < ActiveSupport::TestCase
    include DisciplineModelTests

    def setup
      setup_common_test_data # in discipline_model_tests.rb
      @resource = create(:document_control_doc_type, discipline: @resource_discipline, code: "DOC")
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

    test "name must be present" do
      @resource.name = nil
      refute @resource.valid?
      assert_includes @resource.errors[:name], I18n.t("errors.messages.blank")
    end

    test "name must not be too long" do
      @resource.name = "a" * 51
      refute @resource.valid?
      assert_includes @resource.errors[:name], I18n.t("errors.messages.too_long", count: 50)
    end

    test "label returns code" do
      assert_equal @resource.code, @resource.label
    end

    test "long_label returns discipline label and code" do
      expected = "#{@resource_discipline.label}: DOC"
      assert_equal expected, @resource.long_label
    end

    test "code must be unique within discipline" do
      duplicate = build(:document_control_doc_type, discipline: @resource_discipline, code: "DOC")
      refute duplicate.valid?
      assert_includes duplicate.errors[:code], I18n.t("errors.messages.taken")
    end

  end
end
