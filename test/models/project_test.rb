require "test_helper"

class ProjectTest < ActiveSupport::TestCase
  def setup
    @project = create(:project)
  end

  test "create new project" do
    assert_difference 'Project.count', 1 do
      create(:project)
    end
  end

  # Rolify setup
  test "rolify resourcify is applied" do
    assert Rolify.resource_types.include?('Project')
  end

  # Callbacks
  test "code is upcased before save" do
    project = create(:project, code: 'aa')
    assert_equal 'AA', project.code
  end

  test "standard disciplines are created" do
    project = create(:project)
    assert_equal Constants.disciplines.count, project.disciplines.count
  end

  # Associations
  test "belongs to optional swatch" do
    assert_respond_to @project, :swatch
    @project.swatch = nil
    assert @project.valid?
  end

  test "has disciplines association with dependent destroy" do
    assert_respond_to @project, :disciplines
    assert_kind_of ActiveRecord::Associations::CollectionProxy, @project.disciplines
    assert_difference "Discipline.count", -Constants.disciplines.count do
      @project.destroy
    end
  end

  test "has tags through disciplines" do
    assert_respond_to @project, :tags
    assert_kind_of ActiveRecord::Associations::CollectionProxy, @project.tags
  end

  test "has change requests with dependent destroy" do
    assert_respond_to @project, :change_requests
    assert_kind_of ActiveRecord::Associations::CollectionProxy, @project.change_management_requests
  end

  # Validations
  test "default factory should be valid" do
    assert @project.valid?
  end

  test "code should be present" do
    @project.code = ""
    refute @project.valid?
    assert_includes @project.errors[:code], I18n.t("errors.messages.blank")
  end

  test "code should be 2 upper case characters" do
    @project.code = "A"
    refute @project.valid?
    assert_includes @project.errors[:code], I18n.t("errors.messages.wrong_length", count: 2)
    @project.code = "A" * 3
    refute @project.valid?
    assert_includes @project.errors[:code], I18n.t("errors.messages.wrong_length", count: 2)
    @project.code = "A1"
    refute @project.valid?
    @project.code = "A!"
    refute @project.valid?
  end

  test "code should be unique" do
    create(:project, code: 'ZZ')
    duplicate_project = build(:project, code: 'ZZ')
    refute duplicate_project.valid?
    assert_includes duplicate_project.errors[:code], I18n.t("errors.messages.taken")
  end

  test "title should be present" do
    @project.title = "     "
    refute @project.valid?
    assert_includes @project.errors[:title], I18n.t("errors.messages.blank")
  end

  test "title should not be too long" do
    @project.title = "a" * 256
    refute @project.valid?
    assert_includes @project.errors[:title], I18n.t("errors.messages.too_long", count: 50)
  end
  
  test "description can be blank" do
    @project.description = ""
    assert @project.valid?
  end
  
  test "description can be very long" do
    @project.description = "a" * 5000
    assert @project.valid?
  end
  
  # Methods
  test "label method returns code" do
    assert_equal @project.code, @project.label
  end
  
  test "long_label method returns code and title" do
    assert_equal "#{@project.code}: #{@project.title}", @project.long_label
  end

  test "ordered scope sorts by code" do
    Project.destroy_all
    project_z = create(:project, code: 'ZZ', title: 'Zulu')
    project_a = create(:project, code: 'AA', title: 'Alpha')
    project_m = create(:project, code: 'MM', title: 'Mike')

    ordered_projects = Project.ordered

    assert_equal [project_a, project_m, project_z], ordered_projects.to_a
  end
  
  # Actions
  test "destroy project" do
    assert_difference 'Project.count', -1 do
      @project.destroy
    end
  end
  
end
