require "test_helper"

class TagsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @current_project = projects(:ab) # Instead of trying to access session in tests
    @tag = tags(:pg)
    @user = users(:valid)
  end

  test "no access if not signed in" do
    get tags_url
    assert_redirected_to new_user_session_url
    assert_not flash.empty?
  end

  test "should get index" do
    sign_in @user
    @current_user = @user
    get tags_url
    assert_response :success
  end

  test "should get new" do
    sign_in @user
    @current_user = @user
    get new_tag_url
    assert_response :success
  end

  test "should create tag" do
    sign_in @user
    assert_difference("Tag.count") do
      post tags_url, params: { tag: { description: @tag.description,
                                      discipline_id: @tag.discipline_id,
                                      serial: @tag.serial + 1,
                                      notes: @tag.notes,
                                      prefix: @tag.prefix,
                                      project_id: @tag.project_id,
                                      stage: @tag.stage,
                                      suffix: @tag.suffix } }
    end

    assert_redirected_to tag_url(Tag.last)
  end

  test "should show tag" do
    sign_in @user
    get tag_url(@tag)
    assert_response :success
  end

  test "should get edit" do
    sign_in @user
    get edit_tag_url(@tag)
    assert_response :success
  end

  test "should update tag" do
    sign_in @user
    patch tag_url(@tag), params: { tag: { description: @tag.description,
                                          discipline_id: @tag.discipline_id,
                                          serial: @tag.serial,
                                          notes: @tag.notes,
                                          prefix: @tag.prefix,
                                          project_id: @tag.project_id,
                                          stage: @tag.stage,
                                          suffix: @tag.suffix } }
    assert_redirected_to tag_url(@tag)
  end

  test "should destroy tag" do
    sign_in @user
    assert_difference("Tag.count", -1) do
      delete tag_url(@tag)
    end

    assert_redirected_to tags_url
  end
end
