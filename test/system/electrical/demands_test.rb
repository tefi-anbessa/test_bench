require "application_system_test_case"

class Electrical::DemandsTest < ApplicationSystemTestCase
  setup do
    @light_cct = create(:light_cct, :with_demand)
    @demand = @light_cct.demand
    login_as(users(:admin))  # Assuming you have a user fixture for admin
  end

  test "visiting the index" do
    visit demands_url
    assert_selector "h1", text: "Demands"
  end

  test "should create demand" do
    visit demands_url
    click_on "New Demand"

    # Fill in the form with test data
    select @light_cct.tag.full_tag, from: "demand_demandable_id"
    select "LightCct", from: "demand_demandable_type"
    select "Power & PF", from: "Basis"
    fill_in "Basis notes", with: "Test basis notes"
    fill_in "Power (W)", with: 1000
    fill_in "Power factor", with: 0.9
    select "3-Phase 3-Wire", from: "Configuration"
    fill_in "Supply (V)", with: 400
    
    click_on "Create Demand"

    assert_text "Demand was successfully created"
    click_on "Back"
  end

  test "should update Demand" do
    visit demand_url(@demand)
    click_on "Edit", match: :first

    # Update some fields
    fill_in "Basis notes", with: "Updated basis notes"
    fill_in "Power (W)", with: 1500
    
    click_on "Update Demand"

    assert_text "Demand was successfully updated"
    click_on "Back"
  end

  test "should destroy Demand" do
    visit demand_url(@demand)
    accept_confirm do
      click_on "Delete", match: :first
    end

    assert_text "Demand was successfully destroyed"
  end
end
