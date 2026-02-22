require "test_helper"
class SwatchTest < ActiveSupport::TestCase

  def setup
    setup_model_specific_data
  end
  
  def setup_model_specific_data
    @resource = create(:swatch)
    # Insert model specific test setup here, including relationships with other models.
    # E.g. setup electrical_demand for electrical models.
  end

  test "model specific setup should be valid" do
  assert @resource.valid?
    # Insert validity test of model specific test setup here, including relationships with other models.
    # E.g. create electrical_demand for electrical models.
  end

  test "name must be present" do
    @resource.name = nil
    refute @resource.valid?
    assert_includes @resource.errors[:name], I18n.t("errors.messages.blank")
  end

  test "bg must be present" do
    @resource.bg = nil
    refute @resource.valid?
    assert_includes @resource.errors[:bg], I18n.t("errors.messages.blank")
  end

  test "text must be present" do
    @resource.text = nil
    refute @resource.valid?
    assert_includes @resource.errors[:text], I18n.t("errors.messages.blank")
  end

  test "form_bg must be present" do
    @resource.form_bg = nil
    refute @resource.valid?
    assert_includes @resource.errors[:form_bg], I18n.t("errors.messages.blank")
  end

  test "form_field must be present" do
    @resource.form_field = nil
    refute @resource.valid?
    assert_includes @resource.errors[:form_field], I18n.t("errors.messages.blank")
  end
  test "card_bg must be present" do
    @resource.card_bg = nil
    refute @resource.valid?
    assert_includes @resource.errors[:card_bg], I18n.t("errors.messages.blank")
  end

  test "card_header_bg must be present" do
    @resource.card_header_bg = nil
    refute @resource.valid?
    assert_includes @resource.errors[:card_header_bg], I18n.t("errors.messages.blank")
  end

  test "card_border must be present" do
    @resource.card_border = nil
    refute @resource.valid?
    assert_includes @resource.errors[:card_border], I18n.t("errors.messages.blank")
  end

  test "badge_bg must be present" do
    @resource.badge_bg = nil
    refute @resource.valid?
    assert_includes @resource.errors[:badge_bg], I18n.t("errors.messages.blank")
  end

  test "badge_text must be present" do
    @resource.badge_text = nil
    refute @resource.valid?
    assert_includes @resource.errors[:badge_text], I18n.t("errors.messages.blank")
  end

  test "link_text must be present" do
    @resource.link_text = nil
    refute @resource.valid?
    assert_includes @resource.errors[:link_text], I18n.t("errors.messages.blank")
  end

  test "link_hover must be present" do
    @resource.link_hover = nil
    refute @resource.valid?
    assert_includes @resource.errors[:link_hover], I18n.t("errors.messages.blank")
  end

end