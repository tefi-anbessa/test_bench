require "test_helper"

class DisciplineTest < ActiveSupport::TestCase
  def setup
    @project = create(:project)
    @swatch = create(:swatch)
    @discipline = build(:discipline, project: @project, swatch: @swatch)
  end

  test "setup should be valid" do
    assert @project.valid?
    assert @swatch.valid?
    assert @discipline.valid?
  end

  test "factory default should create discipline with valid attributes" do
    discipline = build(:discipline)
    assert discipline.valid?
  end

  test "label must be present" do
    @discipline.label = ""
    refute @discipline.valid?
    assert_includes @discipline.errors[:label], I18n.t("errors.messages.blank")
  end

  test "project must be present" do
    @discipline.project = nil
    refute @discipline.valid?
  end

  test "swatch must be present" do
    @discipline.swatch = nil
    refute @discipline.valid?
  end

  test "label must be maximum 5 characters" do
    @discipline.label = "a" * 6
    refute @discipline.valid?
    assert_includes @discipline.errors[:label], I18n.t("errors.messages.too_long", count: 5)
    @discipline.label = "A"
    assert @discipline.valid?
  end

  test "label must be unique within project" do
    create(:discipline, label: "Z", name: 'Test Discipline 1', project: @project, swatch: @swatch)
    
    # Try to create another discipline with the same code but different label
    duplicate = build(:discipline, label: "Z", name: 'Test Discipline 2', project: @project, swatch: @swatch)
    refute duplicate.valid?, "Should not allow duplicate discipline codes in same project"
    assert_includes duplicate.errors[:label], I18n.t("errors.messages.taken")
  end

  test "label can repeat in different projects" do
    create(:discipline, label: "Z", name: 'Test Discipline', project: @project, swatch: @swatch)
    
    # Try to create another discipline with the same code in a new project
    duplicate = create(:discipline, label: "Z", name: 'Test Discipline', project: create(:project), swatch: @swatch)
    assert duplicate.valid?, "Should allow duplicate discipline labels in different projects"
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

  test "prefix_schema must be present" do
    @discipline.prefix_schema = ''
    refute @discipline.valid?
    assert_includes @discipline.errors[:prefix_schema], I18n.t("errors.messages.blank")
  end

  test "prefix_schema must convert to a ruby hash" do
    @discipline.prefix_schema = 'invalid json'
    refute @discipline.valid?
    assert_includes @discipline.errors[:prefix_schema], I18n.t("errors.messages.invalid")
  end

  test "prefix_schema name must be present" do
    @discipline.prefix_schema = { name: '' }
    refute @discipline.valid?
    assert_includes @discipline.errors[:prefix_schema], 
      I18n.t("activerecord.errors.jsonb_fields.blank", 
        field: I18n.t("activerecord.attributes.discipline.prefix_schema_keys.name")
      )
  end

  test "prefix_schema type must be present when name is not standard" do
    @discipline.prefix_schema = { name: 'ab_elec' }
    refute @discipline.valid?
    assert_includes @discipline.errors[:prefix_schema], 
      I18n.t("activerecord.errors.jsonb_fields.blank", 
        field: I18n.t("activerecord.attributes.discipline.prefix_schema_keys.type")
      )
  end

  test "prefix_schema type must be in the parsers list when name is not standard" do
    @discipline.prefix_schema = { name: 'ab_elec', type: 'other' }
    refute @discipline.valid?
    assert_includes @discipline.errors[:prefix_schema], 
      I18n.t("activerecord.errors.jsonb_fields.included", 
        field: I18n.t("activerecord.attributes.discipline.prefix_schema_keys.type")
      )
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
