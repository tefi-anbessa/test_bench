# test/controllers/errors_controller_test.rb
require 'test_helper'

class ErrorsControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers

  setup do
    @user = create(:user)
    @request.env['devise.mapping'] = Devise.mappings[:user]
  end

  test "should get forbidden" do
    get :forbidden
    assert_response :forbidden
    assert_template 'errors/forbidden'
  end

  test "should get conflict" do
    get :conflict
    assert_response :conflict
    assert_template 'errors/conflict'
  end

  test "forbidden includes exception details when available" do
    exception = StandardError.new("Test exception")
    @request.env['action_dispatch.exception'] = exception
    get :forbidden
    assert_response :forbidden
    assert_match /Test exception/, @response.body
  end

  test "conflict includes exception details when available" do
    exception = StandardError.new("Test conflict")
    @request.env['action_dispatch.exception'] = exception
    get :conflict
    assert_response :conflict
    assert_match /Test conflict/, @response.body
  end

  test "forbidden shows user info when signed in" do
    sign_in @user
    get :forbidden
    assert_match /#{@user.email}/, @response.body
  end

  test "conflict shows user info when signed in" do
    sign_in @user
    get :conflict
    assert_match /#{@user.email}/, @response.body
  end

  test "forbidden returns JSON when requested" do
    @request.env['HTTP_ACCEPT'] = 'application/json'
    get :forbidden
    assert_response :forbidden
    assert_match 'application/json', @response.content_type
    json = JSON.parse(@response.body)
    assert_equal 'Forbidden', json['error']
  end

  test "conflict returns JSON when requested" do
    @request.env['HTTP_ACCEPT'] = 'application/json'
    @request.env['action_dispatch.exception'] = StandardError.new("Test conflict")
    get :conflict
    assert_response :conflict
    assert_match 'application/json', @response.content_type
    json = JSON.parse(@response.body)
    assert_equal 'Test conflict', json['error']
  end
end