require "test_helper"

class SiteControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers
  
  test "should get home" do
    get site_home_url
    assert_response :success
  end

  test "should get help" do
    get site_help_url
    assert_response :success
  end

  test "should get about" do
    get site_about_url
    assert_response :success
  end

  test "should get contact" do
    get site_contact_url
    assert_response :success
  end
end
