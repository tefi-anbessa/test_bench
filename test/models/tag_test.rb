require "test_helper"

class TagTest < ActiveSupport::TestCase

  def setup
    @project = projects(:ab)
    @tag = tags(:pm)
  end

  test "fixtures should be valid" do
    tags.each do |t|
      assert t.valid?, t.errors.full_messages.inspect
    end
  end

  test "setup should be valid" do
    assert @project.valid?
    assert @tag.valid?
    assert_equal @project, @tag.project
  end

  test "should be able to create new tag on project" do
    @new_tag = @project.tags.create(prefix: "A",
                    serial: 1,
                    suffix: "B",
                    description: "Pump sump",
                    stage: 0,
                    notes: "yadda",
                    discipline: disciplines(:a)
                  )
  end

  test "prefix should be present" do
    @tag.prefix = ""
    assert_not @tag.valid?
  end

  test "serial should be present" do
    @tag.serial = nil
    assert_not @tag.valid?
  end

  test "suffix should be maximum 5 characters" do
    @tag.suffix = "a" * 6
    assert_not @tag.valid?
  end

  test "description should be maximum 40 characters" do
    @tag.suffix = "a" * 41
    assert_not @tag.valid?
  end

  test "project stage should be in the range 0 to 10" do
    @tag.stage = 11
    assert_not @tag.valid?
  end

  test "full tag method should work" do
    assert_equal tags(:pg).full_tag, "A:PG-1001"
    assert_equal tags(:ec).full_tag, "B:EC-1002.A"
  end

  test "destroy tag should remove from project" do
    assert_difference '@project.tags.count', -1 do
      @tag.destroy
      assert_not_includes(@project.tags, @tag)
    end
  end
=begin
  test "destroy project should destroy tags" do
    count = @project.tags.count
    assert_difference 'Tag.count', -count do
      @project.destroy
      assert_not_includes(@project.tags, @tag)
    end
  end
=end
end
