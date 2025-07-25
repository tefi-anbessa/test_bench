require "application_system_test_case"

class Electrical::CableTypesTest < ApplicationSystemTestCase
  setup do
    @electrical_cable_type = electrical_cable_types(:one)
  end

  test "visiting the index" do
    visit electrical_cable_types_url
    assert_selector "h1", text: "Cable types"
  end

  test "should create cable type" do
    visit electrical_cable_types_url
    click_on "New cable type"

    fill_in "Armour", with: @electrical_cable_type.armour
    fill_in "Bedding", with: @electrical_cable_type.bedding
    fill_in "Bedding od", with: @electrical_cable_type.bedding_od
    fill_in "Conductor makeup", with: @electrical_cable_type.conductor_makeup
    fill_in "Conductor material", with: @electrical_cable_type.conductor_material
    fill_in "Csa", with: @electrical_cable_type.csa
    fill_in "Earth csa", with: @electrical_cable_type.earth_csa
    fill_in "Insulation", with: @electrical_cable_type.insulation
    fill_in "Neutral csa", with: @electrical_cable_type.neutral_csa
    fill_in "Overall od", with: @electrical_cable_type.overall_od
    fill_in "Sheath", with: @electrical_cable_type.sheath
    fill_in "Temperature rating", with: @electrical_cable_type.temperature_rating
    click_on "Create Cable type"

    assert_text "Cable type was successfully created"
    click_on "Back"
  end

  test "should update Cable type" do
    visit electrical_cable_type_url(@electrical_cable_type)
    click_on "Edit this cable type", match: :first

    fill_in "Armour", with: @electrical_cable_type.armour
    fill_in "Bedding", with: @electrical_cable_type.bedding
    fill_in "Bedding od", with: @electrical_cable_type.bedding_od
    fill_in "Conductor makeup", with: @electrical_cable_type.conductor_makeup
    fill_in "Conductor material", with: @electrical_cable_type.conductor_material
    fill_in "Csa", with: @electrical_cable_type.csa
    fill_in "Earth csa", with: @electrical_cable_type.earth_csa
    fill_in "Insulation", with: @electrical_cable_type.insulation
    fill_in "Neutral csa", with: @electrical_cable_type.neutral_csa
    fill_in "Overall od", with: @electrical_cable_type.overall_od
    fill_in "Sheath", with: @electrical_cable_type.sheath
    fill_in "Temperature rating", with: @electrical_cable_type.temperature_rating
    click_on "Update Cable type"

    assert_text "Cable type was successfully updated"
    click_on "Back"
  end

  test "should destroy Cable type" do
    visit electrical_cable_type_url(@electrical_cable_type)
    click_on "Destroy this cable type", match: :first

    assert_text "Cable type was successfully destroyed"
  end
end
