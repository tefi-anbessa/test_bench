require "test_helper"

class TagTest < ActiveSupport::TestCase

  def setup
    @tag = Tag.new(prefix: "A",
                    serial: 1,
                    suffix: "B",
                    description: "Pump sump",
                    phase: 0,
                    notes: "yadda",
                    discipline: disciplines(:a),
                    project: projects(:aa)
                  )
  end

  test "fixtures should be valid" do
    tags.each do |t|
      assert t.valid?, t.errors.full_messages.inspect
    end
  end

  test "should be valid" do
    assert @tag.valid?
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

  test "project phase should be in the range 0 to 10" do
    @tag.phase = 11
    assert_not @tag.valid?
  end

#  test "full tag method should work" do
#    assert @tag.full_tag == "A-0001.B"
#  end

end
