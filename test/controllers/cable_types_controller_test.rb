require "test_helper"

class CableTypesControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @cable_type = cable_types(:one)
    @user = users(:valid)
    @ee = users(:ee)
  end

  test "no access if not signed in" do
    get cable_types_url
    assert_redirected_to new_user_session_url
    assert_not flash.empty?
  end

  test "should get index" do
    sign_in @user
    get cable_types_url
    assert_response :success
  end

  test "should not get new if user does not have creator role on cable types" do
    sign_in @user
    get new_cable_type_url
    assert_redirected_to root_path
  end

  test "should get new if user has creator role on cable types" do
    sign_in @ee
    @ee.grant :creator, CableType
    get new_cable_type_url
    assert_response :success
  end

  test "should not create cable_type when not authorized" do
    sign_in @user
    assert_no_difference("CableType.count") do
      post cable_types_url, params: { cable_type: { armour: @cable_type.armour, bedding: @cable_type.bedding, bedding_od: @cable_type.bedding_od, conductor_makeup: @cable_type.conductor_makeup, conductor_material: @cable_type.conductor_material, csa: @cable_type.csa, earth_csa: @cable_type.earth_csa, insulation: @cable_type.insulation, neutral_csa: @cable_type.neutral_csa, overall_od: @cable_type.overall_od, sheath: @cable_type.sheath, temperature_rating: @cable_type.temperature_rating } }
    end
    assert_redirected_to root_path
  end

  test "should create cable_type when authorized" do
    sign_in @ee
    @ee.grant :creator, CableType
    assert_difference("CableType.count") do
      post cable_types_url, params: { cable_type: { armour: @cable_type.armour, bedding: @cable_type.bedding, bedding_od: @cable_type.bedding_od, conductor_makeup: @cable_type.conductor_makeup, conductor_material: @cable_type.conductor_material, csa: @cable_type.csa, earth_csa: @cable_type.earth_csa, insulation: @cable_type.insulation, neutral_csa: @cable_type.neutral_csa, overall_od: @cable_type.overall_od, sheath: @cable_type.sheath, temperature_rating: @cable_type.temperature_rating } }
    end
    assert_redirected_to cable_type_url(CableType.last)
  end

  test "should show cable_type" do
    sign_in @user
    get cable_type_url(@cable_type)
    assert_response :success
  end

  test "should not get edit when not authorized" do
    sign_in @user
    get edit_cable_type_url(@cable_type)
    assert_redirected_to root_path
  end

  test "should get edit" do
    sign_in @ee
    @ee.grant :creator, CableType
    get edit_cable_type_url(@cable_type)
    assert_response :success
  end

  test "should not update cable_type when not authorized" do
    sign_in @user
    patch cable_type_url(@cable_type), params: { cable_type: { armour: @cable_type.armour, bedding: @cable_type.bedding, bedding_od: @cable_type.bedding_od, conductor_makeup: @cable_type.conductor_makeup, conductor_material: @cable_type.conductor_material, csa: @cable_type.csa, earth_csa: @cable_type.earth_csa, insulation: @cable_type.insulation, neutral_csa: @cable_type.neutral_csa, overall_od: @cable_type.overall_od, sheath: @cable_type.sheath, temperature_rating: @cable_type.temperature_rating } }
    assert_redirected_to root_path
  end

  test "should update cable_type" do
    sign_in @ee
    @ee.grant :creator, CableType
    patch cable_type_url(@cable_type), params: { cable_type: { armour: @cable_type.armour, bedding: @cable_type.bedding, bedding_od: @cable_type.bedding_od, conductor_makeup: @cable_type.conductor_makeup, conductor_material: @cable_type.conductor_material, csa: @cable_type.csa, earth_csa: @cable_type.earth_csa, insulation: @cable_type.insulation, neutral_csa: @cable_type.neutral_csa, overall_od: @cable_type.overall_od, sheath: @cable_type.sheath, temperature_rating: @cable_type.temperature_rating } }
    assert_redirected_to cable_type_url(@cable_type)
  end

  test "should not destroy cable_type when not authorized" do
    sign_in @user
    assert_no_difference("CableType.count") do
      delete cable_type_url(@cable_type)
    end
    assert_redirected_to root_path
  end

  test "should destroy cable_type" do
    sign_in @ee
    @ee.grant :creator, CableType
    assert_difference("CableType.count", -1) do
      delete cable_type_url(@cable_type)
    end
    assert_redirected_to cable_types_url
  end

=begin
=end
end
