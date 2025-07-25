require "application_system_test_case"

class Electrical::ProtectionsTest < ApplicationSystemTestCase
  setup do
    @electrical_protection = electrical_protections(:one)
  end

  test "visiting the index" do
    visit electrical_protections_url
    assert_selector "h1", text: "Protections"
  end

  test "should create protection" do
    visit electrical_protections_url
    click_on "New protection"

    fill_in "Curve", with: @electrical_protection.curve
    fill_in "Device", with: @electrical_protection.device
    fill_in "Elcb", with: @electrical_protection.elcb
    fill_in "Notes", with: @electrical_protection.notes
    fill_in "Poles", with: @electrical_protection.poles
    fill_in "Rating", with: @electrical_protection.rating
    click_on "Create Protection"

    assert_text "Protection was successfully created"
    click_on "Back"
  end

  test "should update Protection" do
    visit electrical_protection_url(@electrical_protection)
    click_on "Edit this protection", match: :first

    fill_in "Curve", with: @electrical_protection.curve
    fill_in "Device", with: @electrical_protection.device
    fill_in "Elcb", with: @electrical_protection.elcb
    fill_in "Notes", with: @electrical_protection.notes
    fill_in "Poles", with: @electrical_protection.poles
    fill_in "Rating", with: @electrical_protection.rating
    click_on "Update Protection"

    assert_text "Protection was successfully updated"
    click_on "Back"
  end

  test "should destroy Protection" do
    visit electrical_protection_url(@electrical_protection)
    click_on "Destroy this protection", match: :first

    assert_text "Protection was successfully destroyed"
  end
end
