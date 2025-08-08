require "test_helper"

class LightCctsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @light_cct = light_ccts(:one)
  end

  test "should get index" do
    get light_ccts_url
    assert_response :success
  end

  test "should get new" do
    get new_light_cct_url
    assert_response :success
  end

  test "should create light_cct" do
    assert_difference("LightCct.count") do
      post light_ccts_url, params: { light_cct: { quantity: @light_cct.quantity, type: @light_cct.type } }
    end

    assert_redirected_to light_cct_url(LightCct.last)
  end

  test "should show light_cct" do
    get light_cct_url(@light_cct)
    assert_response :success
  end

  test "should get edit" do
    get edit_light_cct_url(@light_cct)
    assert_response :success
  end

  test "should update light_cct" do
    patch light_cct_url(@light_cct), params: { light_cct: { quantity: @light_cct.quantity, type: @light_cct.type } }
    assert_redirected_to light_cct_url(@light_cct)
  end

  test "should destroy light_cct" do
    assert_difference("LightCct.count", -1) do
      delete light_cct_url(@light_cct)
    end

    assert_redirected_to light_ccts_url
  end
end
