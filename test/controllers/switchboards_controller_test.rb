require "test_helper"

class SwitchboardsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @switchboard = switchboards(:ex2)
  end

  test "should get index" do
    get switchboards_url
    assert_response :success
  end

  test "should get new" do
    get new_switchboard_url
    assert_response :success
  end

  test "should create switchboard" do
    assert_difference("Switchboard.count") do
      post switchboards_url, params: { switchboard: {
        busbar_fault_duration: @switchboard.busbar_fault_duration,
        busbar_fault_rating: @switchboard.busbar_fault_rating,
        busbar_rating: @switchboard.busbar_rating,
        cable_entry: @switchboard.cable_entry,
        earth_bar_connections: @switchboard.earth_bar_connections,
        metering: @switchboard.metering,
        incomer_protection: @switchboard.incomer_protection,
        ingress_protection: @switchboard.ingress_protection,
        location: @switchboard.location,
        neutral_bar_connections: @switchboard.neutral_bar_connections,
        service: @switchboard.service } }
    end

    assert_redirected_to switchboard_url(Switchboard.last)
  end

  test "should show switchboard" do
    get switchboard_url(@switchboard)
    assert_response :success
  end

  test "should get edit" do
    get edit_switchboard_url(@switchboard)
    assert_response :success
  end

  test "should update switchboard" do
    patch switchboard_url(@switchboard), params: { switchboard: {
      busbar_fault_duration: @switchboard.busbar_fault_duration,
      busbar_fault_rating: @switchboard.busbar_fault_rating,
      busbar_rating: @switchboard.busbar_rating,
      cable_entry: @switchboard.cable_entry,
      earth_bar_connections: @switchboard.earth_bar_connections,
      metering: @switchboard.metering,
      incomer_protection: @switchboard.incomer_protection,
      ingress_protection: @switchboard.ingress_protection,
      location: @switchboard.location,
      neutral_bar_connections: @switchboard.neutral_bar_connections,
      service: @switchboard.service } }
    assert_redirected_to switchboard_url(@switchboard)
  end

  test "should destroy switchboard" do
    assert_difference("Switchboard.count", -1) do
      delete switchboard_url(@switchboard)
    end

    assert_redirected_to switchboards_url
  end
end
