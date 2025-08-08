require "test_helper"

class ProjectTest < ActiveSupport::TestCase
  def setup
    @project = projects(:ab)
  end

  test "fixtures should be valid" do
    projects.each do |p|
      assert p.valid?, p.errors.full_messages.inspect
    end
  end

  test "should be valid" do
    assert @project.valid?
  end

  test "create new project" do
    code = Project.pluck(:code).sort.last.next
    assert_difference 'Project.count', 1, "Next code is #{code}" do
      Project.create(code: code,
        title: "Title", description: "yadda")
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
  end

  test "title should be present" do
    @project.title = "     "
    assert_not @project.valid?
  end

  test "title should not be too long" do
    @project.title = "a" * 51
    assert_not @project.valid?
  end
=begin
  test "destroy project" do
    assert_difference 'Project.count', -1 do
      @project.destroy
    end
  end
=end

end
