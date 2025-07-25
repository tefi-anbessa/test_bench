require "test_helper"

class CableTypesControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @cable_type = cable_types(:one)
    @user = users(:valid)
    sign_in @user
  end
  test "should get index" do
    get cable_types_url
    assert_response :success
  end

  test "should get new" do
    get new_cable_type_url
    assert_response :success
  end

  test "should create cable_type" do
    assert_difference("CableType.count") do
      post cable_types_url, params: { cable_type: { armour: @cable_type.armour, bedding: @cable_type.bedding, bedding_od: @cable_type.bedding_od, conductor_makeup: @cable_type.conductor_makeup, conductor_material: @cable_type.conductor_material, csa: @cable_type.csa, earth_csa: @cable_type.earth_csa, insulation: @cable_type.insulation, neutral_csa: @cable_type.neutral_csa, overall_od: @cable_type.overall_od, sheath: @cable_type.sheath, temperature_rating: @cable_type.temperature_rating } }
    end
    assert_redirected_to cable_type_url(CableType.last)
  end

  test "should show cable_type" do
    get cable_type_url(@cable_type)
    assert_response :success
  end

  test "should get edit" do
    get edit_cable_type_url(@cable_type)
    assert_response :success
  end

  test "should update cable_type" do
    patch cable_type_url(@cable_type), params: { cable_type: { armour: @cable_type.armour, bedding: @cable_type.bedding, bedding_od: @cable_type.bedding_od, conductor_makeup: @cable_type.conductor_makeup, conductor_material: @cable_type.conductor_material, csa: @cable_type.csa, earth_csa: @cable_type.earth_csa, insulation: @cable_type.insulation, neutral_csa: @cable_type.neutral_csa, overall_od: @cable_type.overall_od, sheath: @cable_type.sheath, temperature_rating: @cable_type.temperature_rating } }
    assert_redirected_to cable_type_url(@cable_type)
  end

  test "should destroy cable_type" do
    assert_difference("CableType.count", -1) do
      delete cable_type_url(@cable_type)
    end
    assert_redirected_to cable_types_url
  end
  
=begin
=end
end
