require "test_helper"

class DisciplineTest < ActiveSupport::TestCase
  def setup
    @project = create(:project) # Create project also creates standard disciplines.
    @swatch = create(:swatch)
    # new discipline for testing
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

  test "code must be present" do
    @discipline.code = ""
    refute @discipline.valid?
    assert_includes @discipline.errors[:code], I18n.t("errors.messages.blank")
  end

  test "project must be present" do
    @discipline.project = nil
    refute @discipline.valid?
  end

  test "code must be maximum 5 characters" do
    @discipline.code = "a" * 6
    refute @discipline.valid?
    assert_includes @discipline.errors[:code], I18n.t("errors.messages.too_long", count: 5)
  end

  test "code must be unique within project" do
    duplicate = build(:discipline, code: "E", name: 'Test Discipline 1', project: @project, swatch: @swatch)
    refute duplicate.valid?, "Should not allow duplicate discipline.codes in same project"
    assert_includes duplicate.errors[:code], I18n.t("errors.messages.taken")
  end

  test "code can repeat in different projects" do
    create(:discipline, code: "Z", name: 'Test Discipline', project: @project, swatch: @swatch)
    
    # Try to create another discipline with the same code in a new project
    duplicate = create(:discipline, code: "Z", name: 'Test Discipline', project: create(:project), swatch: @swatch)
    assert duplicate.valid?, "Should allow duplicate discipline.codes in different projects"
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

  test "name must be unique within project" do
    duplicate = build(:discipline, code: "TEST", name: 'Electrical', project: @project, swatch: @swatch)
    refute duplicate.valid?, "Should not allow duplicate discipline names in same project"
    assert_includes duplicate.errors[:name], I18n.t("errors.messages.taken")
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

  test "custom_schema? should be false for a standard named schema" do
    @discipline.prefix_schema = { name: 'isa51' }
    refute @discipline.custom_schema?
  end

  test "custom_schema? should be true for a schema whose name is not a standard constant" do
    @discipline.prefix_schema = { name: 'my_custom', type: 'dim1', prefix: { 'A' => 'Alpha' } }
    assert @discipline.custom_schema?
  end

  test "custom_schema? should be false when prefix_schema is blank" do
    @discipline.prefix_schema = nil
    refute @discipline.custom_schema?
  end

  test "isa51_type_schema? should be true for the standard isa51 schema" do
    @discipline.prefix_schema = { name: 'isa51' }
    assert @discipline.isa51_type_schema?
  end

  test "isa51_type_schema? should be true for a custom schema of type isa51" do
    @discipline.prefix_schema = { name: 'my_isa51_variant', type: 'isa51' }
    assert @discipline.isa51_type_schema?
  end

  test "isa51_type_schema? should be false for a custom schema of a different type" do
    @discipline.prefix_schema = { name: 'my_custom', type: 'dim1', prefix: { 'A' => 'Alpha' } }
    refute @discipline.isa51_type_schema?
  end

  test "isa51_type_schema? should be false for a different standard schema" do
    @discipline.prefix_schema = { name: 'default' }
    refute @discipline.isa51_type_schema?
  end

  test "default_prefix_schema_name should return the schema's own name when present" do
    @discipline.prefix_schema = { name: 'isa51' }
    assert_equal 'isa51', @discipline.default_prefix_schema_name
  end

  test "default_prefix_schema_name should fall back to project and code when prefix_schema is blank" do
    @discipline.prefix_schema = nil
    expected = "#{@discipline.project&.label}_#{@discipline.code}".parameterize.underscore
    assert_equal expected, @discipline.default_prefix_schema_name
  end

  test "schema_for_form should return an empty hash when prefix_schema is blank" do
    @discipline.prefix_schema = nil
    assert_equal({}, @discipline.schema_for_form)
  end

  test "schema_for_form should return the full constant for a standard named schema" do
    @discipline.prefix_schema = { name: 'isa51' }
    assert_equal Constants.prefix_schemata[:isa51], @discipline.schema_for_form
  end

  test "schema_for_form should return the schema itself for a custom schema" do
    custom = { 'name' => 'my_custom', 'type' => 'dim1', 'prefix' => { 'A' => 'Alpha' } }
    @discipline.prefix_schema = custom
    assert_equal custom, @discipline.schema_for_form
  end

  test "required_role must be a valid discipline role" do
    @discipline.required_role = "invalid_role"
    refute @discipline.valid?
    assert_includes @discipline.errors[:required_role], I18n.t("errors.messages.inclusion")
  end

  test "required_role accepts all valid discipline roles" do
    Role.all_resource_roles[:discipline].each do |role|
      @discipline.required_role = role
      assert @discipline.valid?, "Should be valid with role: #{role}"
    end
  end

  test "destroy project should destroy discipline" do
    # Create a new project with a single tag for this test
    test_project = create(:project)
    standard_count = test_project.disciplines.count
    assert_difference('test_project.disciplines.count', 1) do
      create(:discipline, project: test_project)
    end
    
    # Destroy the project and verify all its disciplines are destroyed
    assert_difference('Discipline.count', -(standard_count + 1)) do
      test_project.destroy
    end
  end

  test "registry_entry finds the standard entry for a module-backed code" do
    electrical = @project.disciplines.find_by(code: "E")
    assert_equal "Electrical", electrical.registry_entry[:name]
  end

  test "registry_entry is nil for a project-defined, non-standard code" do
    assert_nil @discipline.registry_entry
  end

  test "module_name and backing_module resolve for a module-backed discipline" do
    electrical = @project.disciplines.find_by(code: "E")
    assert_equal "Electrical", electrical.module_name
    assert_equal Electrical::Base, electrical.backing_module
    assert electrical.module_backed?
  end

  test "module_name and backing_module are nil for a discipline with no module yet" do
    process = @project.disciplines.find_by(code: "P")
    assert_nil process.module_name
    assert_nil process.backing_module
    refute process.module_backed?
  end

  test "module_name and backing_module are nil for a project-defined discipline" do
    assert_nil @discipline.module_name
    assert_nil @discipline.backing_module
    refute @discipline.module_backed?
  end

  test "default_required_role and default_catalog_required_role come from the registry" do
    electrical = @project.disciplines.find_by(code: "E")
    assert_equal "designer", electrical.default_required_role
    assert_equal "custodian", electrical.default_catalog_required_role
  end

  test "default_required_role is nil for a project-defined discipline" do
    assert_nil @discipline.default_required_role
    assert_nil @discipline.default_catalog_required_role
  end

  test "display_name translates an unrenamed standard discipline" do
    electrical = @project.disciplines.find_by(code: "E")
    assert_equal I18n.t("discipline.name.E"), electrical.display_name
  end

  test "display_name shows the raw name once a standard discipline is renamed" do
    electrical = @project.disciplines.find_by(code: "E")
    electrical.update!(name: "Power Systems")
    assert_equal "Power Systems", electrical.display_name
  end

  test "display_name shows the raw name for a project-defined discipline" do
    assert_equal @discipline.name, @discipline.display_name
  end

  test "standard_options lists the registry keyed by code" do
    options = Discipline.standard_options
    assert_equal "Electrical", options[:E][:name]
    assert_nil options[:P][:module]
  end

  test "create_selected_for_project only creates the requested codes" do
    project = create(:project, discipline_codes: [])
    assert_difference("project.disciplines.count", 2) do
      Discipline.create_selected_for_project(project, codes: ["E", "J"])
    end
    assert_equal %w[E J], project.disciplines.order(:code).pluck(:code)
  end

  test "create_selected_for_project does nothing if the project already has disciplines" do
    assert_no_difference("@project.disciplines.count") do
      Discipline.create_selected_for_project(@project, codes: ["E"])
    end
  end

  test "create_selected_for_project ignores codes not in the registry" do
    project = create(:project, discipline_codes: [])
    assert_difference("project.disciplines.count", 1) do
      Discipline.create_selected_for_project(project, codes: ["E", "NOT_REAL"])
    end
  end
end
