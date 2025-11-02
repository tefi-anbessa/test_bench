require "test_helper"

class ProjectTest < ActiveSupport::TestCase
  def setup
    @project = create(:project)
  end

  test "should be valid" do
    assert @project.valid?
  end

  test "create new project" do
    assert_difference 'Project.count', 1 do
      create(:project)
    end
  end

  test "code should be present" do
    @project.code = ""
    refute @project.valid?
    assert_includes @project.errors[:code], I18n.t("errors.messages.blank")
  end

  test "code should be 2 upper case characters" do
    @project.code = "aa"
    refute @project.valid?
    assert_includes @project.errors[:code], I18n.t("errors.messages.invalid")
    @project.code = "A"
    assert_includes @project.errors[:code], I18n.t("errors.messages.invalid")
    refute @project.valid?
    @project.code = "A" * 3
    refute @project.valid?
    assert_includes @project.errors[:code], I18n.t("errors.messages.wrong_length", count: 2)
    @project.code = "Aa"
    refute @project.valid?
    @project.code = "A1"
    refute @project.valid?
    @project.code = "A!"
    refute @project.valid?
    @project.code = "A"
    assert_includes @project.errors[:code], I18n.t("errors.messages.invalid")
  end

  test "code should be unique" do
    project = create(:project, code: 'ZZ')
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

  test "destroy project" do
    assert_difference 'Project.count', -1 do
      @project.destroy
    end
  end
  

end
