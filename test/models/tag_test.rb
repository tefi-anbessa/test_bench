require "test_helper"

class TagTest < ActiveSupport::TestCase
  def setup
    @project = create(:project)
    @discipline = create(:discipline, :c)  # Using civil discipline as an example
    @tag = build(:tag, project: @project, discipline: @discipline)
  end

  test "should be valid" do
    assert @tag.valid?
  end

  test "should be able to create new tag on project" do
    assert_difference 'Tag.count', 1 do
      @project.tags.create!(
        prefix: "A",
        serial: 1,
        suffix: "B",
        description: "Pump sump",
        stage: 0,
        notes: "yadda",
        discipline: @discipline
      )
    end
  end

  test "prefix should be present" do
    @tag.prefix = ""
    assert_not @tag.valid?
  end
  
  test "prefix should be from valid set" do
    valid_prefixes = %w[CC CE CJB CX FT FV HV LT LZ PG PRV PT PZ XV ME MP MV A B LD LE LH LS LW P S SP T US V]
    
    @tag.prefix = "INVALID"
    assert_not @tag.valid?
    
    valid_prefixes.each do |prefix|
      @tag.prefix = prefix
      assert @tag.valid?, "#{prefix} should be a valid prefix"
    end
  end

  test "serial should be present" do
    @tag.serial = nil
    assert_not @tag.valid?
  end
  
  test "serial should be between 0 and 9999" do
    @tag.serial = -1
    assert_not @tag.valid?
    
    @tag.serial = 10000
    assert_not @tag.valid?
    
    @tag.serial = 0
    assert @tag.valid?
    
    @tag.serial = 9999
    assert @tag.valid?
  end

  test "suffix should be maximum 5 characters" do
    @tag.suffix = "a" * 6
    assert_not @tag.valid?
    
    @tag.suffix = "a" * 5
    assert @tag.valid?
  end

  test "description should not be too long" do
    @tag.description = "a" * 41
    assert_not @tag.valid?
    
    @tag.description = "a" * 40
    assert @tag.valid?
  end

  test "project stage should be in the range 0 to 10" do
    @tag.stage = 11
    assert_not @tag.valid?
  end

  test "full tag method should work" do
    discipline = create(:discipline, code: 'A')  # Create a discipline with a specific code
    tag1 = create(:tag, prefix: 'PG', serial: 1001, suffix: '', project: @project, discipline: discipline)
    tag1.reload  # Reload to trigger after_find callback
    assert_equal "#{discipline.code}:#{tag1.prefix}-#{tag1.serial.to_s.rjust(4, '0')}", tag1.full_tag
    
    tag2 = create(:tag, prefix: 'EC', serial: 1002, suffix: 'A', project: @project, discipline: discipline)
    tag2.reload  # Reload to trigger after_find callback
    assert_equal "#{discipline.code}:#{tag2.prefix}-#{tag2.serial.to_s.rjust(4, '0')}.#{tag2.suffix}", tag2.full_tag
  end

  test "destroy tag should remove from project" do
    tag = create(:tag, project: @project, discipline: @discipline)
    assert_difference('@project.tags.count', -1) do
      tag.destroy
    end
    assert_not_includes(@project.reload.tags, tag)
  end
=begin
  test "destroy project should destroy tags" do
    count = @project.tags.count
    assert_difference 'Tag.count', -count do
      @project.destroy
      assert_not_includes(@project.tags, @tag)
    end
  end
=end
end
