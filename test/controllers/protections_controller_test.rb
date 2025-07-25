require "test_helper"

class ProtectionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @protection = protections(:pm)
  end

  test "should get index" do
    get protections_url
    assert_response :success
  end

  test "should get new" do
    get new_protection_url
    assert_response :success
  end

  test "should create protection" do
    assert_difference("Protection.count") do
      post protections_url, params: { protection: { curve: @protection.curve, device: @protection.device, elcb: @protection.elcb, notes: @protection.notes, poles: @protection.poles, rating: @protection.rating } }
    end

    assert_redirected_to protection_url(Protection.last)
  end

  test "should show protection" do
    get protection_url(@protection)
    assert_response :success
  end

  test "should get edit" do
    get edit_protection_url(@protection)
    assert_response :success
  end

  test "should update protection" do
    patch protection_url(@protection), params: { protection: { curve: @protection.curve, device: @protection.device, elcb: @protection.elcb, notes: @protection.notes, poles: @protection.poles, rating: @protection.rating } }
    assert_redirected_to protection_url(@protection)
  end

  test "should destroy protection" do
    assert_difference("Protection.count", -1) do
      delete protection_url(@protection)
    end

    assert_redirected_to protections_url
  end
end
