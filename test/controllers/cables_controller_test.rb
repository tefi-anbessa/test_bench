require "test_helper"

class CablesControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @cable = cables(:ec1)
    @tag = tags(:ec)
    @user = users(:valid)
    sign_in @user
  end

  test "should get index" do
    get cables_url
    assert_response :success
  end

  test "should get new" do
    get new_tag_cable_url(@tag)
    assert_response :success
  end

  test "should create cable" do
    assert_difference("Cable.count") do
      post cables_url, params: { cable: { cable_type_id: @cable.cable_type_id,
                                          end_mark: @cable.end_mark,
                                          from_id: @cable.from_id,
                                          to_id: @cable.to_id,
                                          route_length: @cable.route_length,
                                          start_mark: @cable.start_mark,
                                          termination_allowance: @cable.termination_allowance,
                                          vertical_allowance: @cable.vertical_allowance } }
    end

    assert_redirected_to cable_url(Cable.last)
  end

  test "should show cable" do
    get cable_url(@cable)
    assert_response :success
  end

  test "should get edit" do
    get edit_cable_url(@cable)
    assert_response :success
  end

  test "should update cable" do
    patch cable_url(@cable), params: { cable: { cable_type_id: @cable.cable_type_id,
                                        end_mark: @cable.end_mark,
                                        from_id: @cable.from_id,
                                        to_id: @cable.to_id,
                                        route_length: @cable.route_length,
                                        start_mark: @cable.start_mark,
                                        termination_allowance: @cable.termination_allowance,
                                        vertical_allowance: @cable.vertical_allowance } }
    assert_redirected_to cable_url(@cable)
  end

  test "should destroy cable" do
    assert_difference("Cable.count", -1) do
      delete cable_url(@cable)
    end

    assert_redirected_to cables_url
  end
end
