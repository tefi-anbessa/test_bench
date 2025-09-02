require "test_helper"

class DisciplineTest < ActiveSupport::TestCase
  def setup
    @discipline = build(:discipline)
  end

  test "should be valid" do
    assert @discipline.valid?
  end

  test "code should be present" do
    @discipline.code = ""
    assert_not @discipline.valid?
  end

  test "code should be one character" do
    @discipline.code = "AA"
    assert_not @discipline.valid?
    @discipline.code = "A"
    assert @discipline.valid?
  end

  test "code should be alphabetic" do
    @discipline.code = "2"
    assert_not @discipline.valid?
    @discipline.code = "!"
    assert_not @discipline.valid?
    @discipline.code = " "
    assert_not @discipline.valid?
  end

  test "code should be unique" do
    # Create a discipline directly to avoid factory issues with DISCIPLINES
    discipline = Discipline.create!(code: 'Z', name: 'Test Discipline')
    
    # Try to create another discipline with the same code
    duplicate = Discipline.new(code: 'Z', name: 'Duplicate Discipline')
    assert_not duplicate.valid?, "Should not allow duplicate discipline codes"
    # assert_includes duplicate.errors[:code], 'already exists'
    
    # Clean up
    discipline.destroy
  end

  test "name should be present" do
    @discipline.name = "     "
    assert_not @discipline.valid?
  end

  test "name should not be too long" do
    @discipline.name = "A" * 51
    assert_not @discipline.valid?
  end

end
