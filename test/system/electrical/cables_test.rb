require "application_system_test_case"

class Electrical::CablesTest < ApplicationSystemTestCase
  setup do
    @electrical_cable = electrical_cables(:one)
  end

  test "visiting the index" do
    visit electrical_cables_url
    assert_selector "h1", text: "Cables"
  end

  test "should create cable" do
    visit electrical_cables_url
    click_on "New cable"

    fill_in "Cable type", with: @electrical_cable.cable_type_id
    fill_in "End mark", with: @electrical_cable.end_mark
    fill_in "From", with: @electrical_cable.from
    fill_in "Route length", with: @electrical_cable.route_length
    fill_in "Start mark", with: @electrical_cable.start_mark
    fill_in "Termination allowance", with: @electrical_cable.termination_allowance
    fill_in "To", with: @electrical_cable.to
    fill_in "Vertical allowance", with: @electrical_cable.vertical_allowance
    click_on "Create Cable"

    assert_text "Cable was successfully created"
    click_on "Back"
  end

  test "should update Cable" do
    visit electrical_cable_url(@electrical_cable)
    click_on "Edit this cable", match: :first

    fill_in "Cable type", with: @electrical_cable.cable_type_id
    fill_in "End mark", with: @electrical_cable.end_mark
    fill_in "From", with: @electrical_cable.from
    fill_in "Route length", with: @electrical_cable.route_length
    fill_in "Start mark", with: @electrical_cable.start_mark
    fill_in "Termination allowance", with: @electrical_cable.termination_allowance
    fill_in "To", with: @electrical_cable.to
    fill_in "Vertical allowance", with: @electrical_cable.vertical_allowance
    click_on "Update Cable"

    assert_text "Cable was successfully updated"
    click_on "Back"
  end

  test "should destroy Cable" do
    visit electrical_cable_url(@electrical_cable)
    click_on "Destroy this cable", match: :first

    assert_text "Cable was successfully destroyed"
  end
end
