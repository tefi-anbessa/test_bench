require "test_helper"

class DisciplineTest < ActiveSupport::TestCase
  def setup
    @project = create(:project)
    @discipline = build(:discipline, project: @project)
  end

  test "setup should be valid" do
    assert @project.valid?
    assert @discipline.valid?
  end

  test "factory default should create discipline with valid attributes" do
    discipline = build(:discipline)
    assert discipline.valid?
  end

  test "code must be present" do
    @discipline.code = ""
    refute @discipline.valid?
    assert_includes @discipline.errors[:code], I18n.t("errors.messages.blank")
  end

  test "project must be present" do
    @discipline.project = nil
    refute @discipline.valid?
  end

  test "code must be maximum 12 characters" do
    @discipline.code = "a" * 13
    refute @discipline.valid?
    assert_includes @discipline.errors[:code], I18n.t("errors.messages.too_long", count: 12)
    @discipline.code = "A"
    assert @discipline.valid?
  end

test "code should be a valid Ruby symbol" do
  # Symbols are preferred
  [:a, :_a, :A, :a1, :A1, :a_b_c, :A_B_C].each do |code|
    @discipline.code = code
    assert @discipline.valid?, "#{code} should be a valid code"
  end

  # Strings are allowed
  ['A', 'a', '_test', 'test1', 'a_b_c'].each do |code|
    @discipline.code = code
    assert @discipline.valid?, "#{code} should be a valid code"
  end

  ['1a', '@test', 'test!', 'test-code', 'with space', ''].each do |code|
    @discipline.code = code
    refute @discipline.valid?, "#{code} should not be a valid code"
    # puts "Code: #{code}, Errors: #{@discipline.errors[:code]}"
    assert_includes @discipline.errors[:code], I18n.t("activerecord.errors.messages.invalid_symbol", 
      model: "Discipline",
      attribute: "Code"
    )
  end
end

  test "code must be unique within project" do
    discipline = create(:discipline, code: :z, label: "Z", name: 'Test Discipline', project: @project)
    
    # Try to create another discipline with the same code but different label
    duplicate = build(:discipline, code: :z, label: "ZZZ", name: 'Test Discipline', project: @project)
    refute duplicate.valid?, "Should not allow duplicate discipline codes in same project"
    assert_includes duplicate.errors[:code], I18n.t("errors.messages.taken")
  end

  test "code can repeat in different projects" do
    discipline = create(:discipline, code: :z, label: "Z", name: 'Test Discipline', project: @project)
    
    # Try to create another discipline with the same code in a new project
    duplicate = create(:discipline, code: :z, label: "XYZ", name: 'Test Discipline', project: create(:project))
    assert duplicate.valid?, "Should allow duplicate discipline codes in different projects"
  end

  test "label must be present" do
    @discipline.label = "     "
    refute @discipline.valid?
    assert_includes @discipline.errors[:label], I18n.t("errors.messages.blank")
  end

  test "label must not be too long" do
    @discipline.label = "A" * 13
    refute @discipline.valid?
    assert_includes @discipline.errors[:label], I18n.t("errors.messages.too_long", count: 12)
  end

  test "label must be unique within project" do
    discipline = create(:discipline, code: :z, label: "Z", name: 'Test Discipline', project: @project)
    
    # Try to create another discipline with different code but the same label
    duplicate = build(:discipline, code: :zzz, label: "Z", name: 'Test Discipline', project: @project)
    refute duplicate.valid?, "Should not allow duplicate discipline labels in same project"
    assert_includes duplicate.errors[:label], I18n.t("errors.messages.taken")
  end

  test "name must be present" do
    @discipline.name = "     "
    refute @discipline.valid?
    assert_includes @discipline.errors[:name], I18n.t("errors.messages.blank")
  end

  test "name must not be too long" do
    @discipline.name = "A" * 51
    refute @discipline.valid?
    assert_includes @discipline.errors[:name], I18n.t("errors.messages.too_long", count: 50)
  end
  
test "code getter and setter handle valid input types" do
  # Test string input
  @discipline.code = "test"
  assert_equal :test, @discipline.code
  assert_equal "test", @discipline[:code]

  # Test symbol input
  @discipline.code = :another_test
  assert_equal :another_test, @discipline.code
  assert_equal "another_test", @discipline[:code]

  # Test with numbers and underscores
  @discipline.code = "test_123"
  assert_equal :test_123, @discipline.code
  assert_equal "test_123", @discipline[:code]
end

  test "destroy project should destroy discipline" do
    # Create a new project with a single tag for this test
    test_project = create(:project)
    create(:discipline, project: test_project)
    
    # Verify the discipline exists
    assert_equal 1, test_project.disciplines.count, "Should have 1 discipline"
    
    # Destroy the project and verify all its disciplines are destroyed
    assert_difference('Discipline.count', -1) do
      test_project.destroy
    end
  end

end
