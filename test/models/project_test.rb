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
    assert_not @project.valid?
  end

  test "code should be 2 upper case characters" do
    @project.code = "aa"
    assert_not @project.valid?
    @project.code = "A"
    assert_not @project.valid?
    @project.code = "A" * 3
    assert_not @project.valid?
    @project.code = "Aa"
    assert_not @project.valid?
    @project.code = "A1"
    assert_not @project.valid?
    @project.code = "A!"
    assert_not @project.valid?
  end

  test "code should be unique" do
    project = create(:project, code: 'ZZ')
    duplicate_project = build(:project, code: 'ZZ')
    assert_not duplicate_project.valid?
  end

  test "title should be present" do
    @project.title = "     "
    assert_not @project.valid?
  end

  test "title should not be too long" do
    @project.title = "a" * 256
    assert_not @project.valid?
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
