require "test_helper"

class DisciplineTest < ActiveSupport::TestCase
  def setup
    @discipline = Discipline.new(code: "C", name: "Checking")
  end

  test "fixtures should be valid" do
    disciplines.each do |d|
      assert d.valid?, d.errors.full_messages.inspect
    end
  end

  test "should be valid" do
    assert @discipline.valid?
  end

  test "code should be one character" do
    @discipline.code = "AA"
    assert_not @discipline.valid?
  end

  test "code should alpha" do
    @discipline.code = "2"
    assert_not @discipline.valid?
  end

  test "name should not be blank" do
    @discipline.name = "     "
    assert_not @discipline.valid?
  end

  test "name should be maximum 50 character" do
    @discipline.name = "A" * 51
    assert_not @discipline.valid?
  end
end
