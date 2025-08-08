require "application_system_test_case"

class SocketCctsTest < ApplicationSystemTestCase
  setup do
    @socket_cct = socket_ccts(:one)
  end

  test "visiting the index" do
    visit socket_ccts_url
    assert_selector "h1", text: "Socket ccts"
  end

  test "should create socket cct" do
    visit socket_ccts_url
    click_on "New socket cct"

    fill_in "Quantity", with: @socket_cct.quantity
    fill_in "Type", with: @socket_cct.type
    click_on "Create Socket cct"

    assert_text "Socket cct was successfully created"
    click_on "Back"
  end

  test "should update Socket cct" do
    visit socket_cct_url(@socket_cct)
    click_on "Edit this socket cct", match: :first

    fill_in "Quantity", with: @socket_cct.quantity
    fill_in "Type", with: @socket_cct.type
    click_on "Update Socket cct"

    assert_text "Socket cct was successfully updated"
    click_on "Back"
  end

  test "should destroy Socket cct" do
    visit socket_cct_url(@socket_cct)
    click_on "Destroy this socket cct", match: :first

    assert_text "Socket cct was successfully destroyed"
  end
end
