require "test_helper"
require "helpers/test_setup_helpers"
class IssueTest < ActiveSupport::TestCase
  include TestSetupHelpers

  def setup
    @project = create(:project, title: "Issue Model Test")
    @discipline = @project.disciplines.find_by(name: "Electrical") || @project.disciplines.first
    setup_model_specific_data
  end
  
  def setup_model_specific_data
    @dt = create(:doc_type, discipline: @discipline, code: "DOC", name: "Test Issue Type")
    @document = create(:document, doc_type: @dt, discipline: @discipline)
    @resource = create(:issue, document: @document)
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
