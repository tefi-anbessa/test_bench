require "application_system_test_case"

class Electrical::LoadsTest < ApplicationSystemTestCase
  setup do
    @electrical_load = electrical_loads(:one)
  end

  test "visiting the index" do
    visit electrical_loads_url
    assert_selector "h1", text: "Loads"
  end

  test "should create load" do
    visit electrical_loads_url
    click_on "New load"

    fill_in "Basis", with: @electrical_load.basis
    fill_in "Basis notes", with: @electrical_load.basis_notes
    fill_in "Cable", with: @electrical_load.cable_id
    fill_in "Current", with: @electrical_load.current
    fill_in "Duty", with: @electrical_load.duty
    fill_in "Phases", with: @electrical_load.phases
    fill_in "Power", with: @electrical_load.power
    fill_in "Power factor", with: @electrical_load.power_factor
    fill_in "Supply v", with: @electrical_load.supply_v
    fill_in "Vector", with: @electrical_load.vector
    click_on "Create Load"

    assert_text "Load was successfully created"
    click_on "Back"
  end

  test "should update Load" do
    visit electrical_load_url(@electrical_load)
    click_on "Edit this load", match: :first

    fill_in "Basis", with: @electrical_load.basis
    fill_in "Basis notes", with: @electrical_load.basis_notes
    fill_in "Cable", with: @electrical_load.cable_id
    fill_in "Current", with: @electrical_load.current
    fill_in "Duty", with: @electrical_load.duty
    fill_in "Phases", with: @electrical_load.phases
    fill_in "Power", with: @electrical_load.power
    fill_in "Power factor", with: @electrical_load.power_factor
    fill_in "Supply v", with: @electrical_load.supply_v
    fill_in "Vector", with: @electrical_load.vector
    click_on "Update Load"

    assert_text "Load was successfully updated"
    click_on "Back"
  end

  test "should destroy Load" do
    visit electrical_load_url(@electrical_load)
    click_on "Destroy this load", match: :first

    assert_text "Load was successfully destroyed"
  end
end
