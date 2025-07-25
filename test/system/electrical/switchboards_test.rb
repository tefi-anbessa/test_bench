require "application_system_test_case"

class Electrical::SwitchboardsTest < ApplicationSystemTestCase
  setup do
    @electrical_switchboard = electrical_switchboards(:one)
  end

  test "visiting the index" do
    visit electrical_switchboards_url
    assert_selector "h1", text: "Switchboards"
  end

  test "should create switchboard" do
    visit electrical_switchboards_url
    click_on "New switchboard"

    fill_in "Busbar fault duration", with: @electrical_switchboard.busbar_fault_duration
    fill_in "Busbar fault rating", with: @electrical_switchboard.busbar_fault_rating
    fill_in "Busbar rating", with: @electrical_switchboard.busbar_rating
    fill_in "Cable entry", with: @electrical_switchboard.cable_entry
    fill_in "Earth bar connections", with: @electrical_switchboard.earth_bar_connections
    fill_in "Incomer metering", with: @electrical_switchboard.incomer_metering
    fill_in "Incomer protection", with: @electrical_switchboard.incomer_protection
    fill_in "Ingress protection", with: @electrical_switchboard.ingress_protection
    fill_in "Location", with: @electrical_switchboard.location
    fill_in "Neutral bar connections", with: @electrical_switchboard.neutral_bar_connections
    fill_in "Service", with: @electrical_switchboard.service
    click_on "Create Switchboard"

    assert_text "Switchboard was successfully created"
    click_on "Back"
  end

  test "should update Switchboard" do
    visit electrical_switchboard_url(@electrical_switchboard)
    click_on "Edit this switchboard", match: :first

    fill_in "Busbar fault duration", with: @electrical_switchboard.busbar_fault_duration
    fill_in "Busbar fault rating", with: @electrical_switchboard.busbar_fault_rating
    fill_in "Busbar rating", with: @electrical_switchboard.busbar_rating
    fill_in "Cable entry", with: @electrical_switchboard.cable_entry
    fill_in "Earth bar connections", with: @electrical_switchboard.earth_bar_connections
    fill_in "Incomer metering", with: @electrical_switchboard.incomer_metering
    fill_in "Incomer protection", with: @electrical_switchboard.incomer_protection
    fill_in "Ingress protection", with: @electrical_switchboard.ingress_protection
    fill_in "Location", with: @electrical_switchboard.location
    fill_in "Neutral bar connections", with: @electrical_switchboard.neutral_bar_connections
    fill_in "Service", with: @electrical_switchboard.service
    click_on "Update Switchboard"

    assert_text "Switchboard was successfully updated"
    click_on "Back"
  end

  test "should destroy Switchboard" do
    visit electrical_switchboard_url(@electrical_switchboard)
    click_on "Destroy this switchboard", match: :first

    assert_text "Switchboard was successfully destroyed"
  end
end
