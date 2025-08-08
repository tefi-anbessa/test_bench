require "application_system_test_case"

class LightCctsTest < ApplicationSystemTestCase
  setup do
    @light_cct = light_ccts(:one)
  end

  test "visiting the index" do
    visit light_ccts_url
    assert_selector "h1", text: "Light ccts"
  end

  test "should create light cct" do
    visit light_ccts_url
    click_on "New light cct"

    fill_in "Quantity", with: @light_cct.quantity
    fill_in "Type", with: @light_cct.type
    click_on "Create Light cct"

    assert_text "Light cct was successfully created"
    click_on "Back"
  end

  test "should update Light cct" do
    visit light_cct_url(@light_cct)
    click_on "Edit this light cct", match: :first

    fill_in "Quantity", with: @light_cct.quantity
    fill_in "Type", with: @light_cct.type
    click_on "Update Light cct"

    assert_text "Light cct was successfully updated"
    click_on "Back"
  end

  test "should destroy Light cct" do
    visit light_cct_url(@light_cct)
    click_on "Destroy this light cct", match: :first

    assert_text "Light cct was successfully destroyed"
  end
end
