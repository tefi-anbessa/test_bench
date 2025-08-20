require "application_system_test_case"

class Electrical::DemandsTest < ApplicationSystemTestCase
  setup do
    @demand = demands(:one)
  end

  test "visiting the index" do
    visit demands_url
    assert_selector "h1", text: "Demands"
  end

  test "should create demand" do
    visit demands_url
    click_on "New demand"

    fill_in "Basis", with: @demand.basis
    fill_in "Basis notes", with: @demand.basis_notes
    fill_in "Circuit", with: @demand.circuit_id
    fill_in "Current", with: @demand.current
    fill_in "Duty", with: @demand.duty
    fill_in "Config", with: @demand.config
    fill_in "Power", with: @demand.power
    fill_in "Power factor", with: @demand.power_factor
    fill_in "Supply", with: @demand.supply
    click_on "Create Demand"

    assert_text "Demand was successfully created"
    click_on "Back"
  end

  test "should update Demand" do
    visit demand_url(@demand)
    click_on "Edit this demand", match: :first

    fill_in "Basis", with: @demand.basis
    fill_in "Basis notes", with: @demand.basis_notes
    fill_in "Circuit", with: @demand.circuit_id
    fill_in "Current", with: @demand.current
    fill_in "Duty", with: @demand.duty
    fill_in "Config", with: @demand.config
    fill_in "Power", with: @demand.power
    fill_in "Power factor", with: @demand.power_factor
    fill_in "Supply", with: @demand.supply
    click_on "Update Demand"

    assert_text "Demand was successfully updated"
    click_on "Back"
  end

  test "should destroy Demand" do
    visit demand_url(@demand)
    click_on "Destroy this demand", match: :first

    assert_text "Demand was successfully destroyed"
  end
end
