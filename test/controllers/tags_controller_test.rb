require "test_helper"

class TagsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @tag = tags(:pg)
  end

  test "should get index" do
    get tags_url
    assert_response :success
  end

  test "should get new" do
    get new_tag_url
    assert_response :success
  end

  test "should create tag" do
    assert_difference("Tag.count") do
      post tags_url, params: { tag: { description: @tag.description,
                                      discipline: @tag.discipline,
                                      serial: @tag.serial,
                                      notes: @tag.notes,
                                      prefix: @tag.prefix,
                                      project_id: @tag.project_id,
                                      phase: @tag.phase,
                                      suffix: @tag.suffix } }
    end

    assert_redirected_to tag_url(Tag.last)
  end

  test "should show tag" do
    get tag_url(@tag)
    assert_response :success
  end

  test "should get edit" do
    get edit_tag_url(@tag)
    assert_response :success
  end

  test "should update tag" do
    patch tag_url(@tag), params: { tag: { description: @tag.description,
                                          discipline_id: @tag.discipline_id,
                                          serial: @tag.serial,
                                          notes: @tag.notes,
                                          prefix: @tag.prefix,
                                          project_id: @tag.project_id,
                                          phase: @tag.project_phase,
                                          suffix: @tag.suffix } }
    assert_redirected_to tag_url(@tag)
  end

  test "should destroy tag" do
    assert_difference("Tag.count", -1) do
      delete tag_url(@tag)
    end

    assert_redirected_to tags_url
  end
end
