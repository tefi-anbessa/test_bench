require "test_helper"

class SocketCctsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @socket_cct = socket_ccts(:es)
  end

  test "should get index" do
    get socket_ccts_url
    assert_response :success
  end

  test "should get new" do
    get new_socket_cct_url
    assert_response :success
  end

  test "should create socket_cct" do
    assert_difference("SocketCct.count") do
      post socket_ccts_url, params: { socket_cct: { quantity: @socket_cct.quantity, type: @socket_cct.type } }
    end

    assert_redirected_to socket_cct_url(SocketCct.last)
  end

  test "should show socket_cct" do
    get socket_cct_url(@socket_cct)
    assert_response :success
  end

  test "should get edit" do
    get edit_socket_cct_url(@socket_cct)
    assert_response :success
  end

  test "should update socket_cct" do
    patch socket_cct_url(@socket_cct), params: { socket_cct: { quantity: @socket_cct.quantity, type: @socket_cct.type } }
    assert_redirected_to socket_cct_url(@socket_cct)
  end

  test "should destroy socket_cct" do
    assert_difference("SocketCct.count", -1) do
      delete socket_cct_url(@socket_cct)
    end

    assert_redirected_to socket_ccts_url
  end
end
