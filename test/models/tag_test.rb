require "test_helper"

class TagTest < ActiveSupport::TestCase
  def setup
    @project = create(:project)
    @discipline = create(:discipline, :e)  # Using electrical discipline as an example
    @tag = build(:tag, project: @project, discipline: @discipline)
  end

  # Factory Tests
  test 'tag factory should be valid' do
    tag = build(:tag, project: @project, discipline: @discipline)
    assert tag.valid?
    assert tag.prefix.present?
    assert tag.serial.present?
  end

  test 'sequential_tag factory should create sequential tags' do
    tag1 = create(:sequential_tag, project: @project, discipline: @discipline)
    tag2 = create(:sequential_tag, project: @project, discipline: @discipline)
    assert_equal 1, tag2.serial - tag1.serial
  end

  test 'complete_tag factory should create complete tags' do
    complete_tag = create(:complete_tag, project: @project, discipline: @discipline)
    assert complete_tag.valid?
    assert complete_tag.prefix.present?
    assert complete_tag.serial.present?
    assert complete_tag.description.present?
    assert complete_tag.stage.present?
    assert complete_tag.notes.present?
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
    assert_not_includes @project.reload.tags, tag
  end
  
  # Tagable validation tests
  test "should allow setting tagable_type without tagable_id" do
    @tag.tagable_type = 'Cable'
    @tag.tagable_id = nil
    assert @tag.valid?
  end
  
  test "should validate tagable_type against allowed types" do
    @tag.tagable_type = 'InvalidType'
    @tag.valid?
    assert_includes @tag.errors[:tagable_type], 'is not included in the list'
  end
  
  test "should allow creating tagable type with existing tag" do
    # First create a tag with type but no tagable
    tag = create(:tag, :unique_tag, prefix: 'EC', project: @project, discipline: @discipline, 
              tagable_type: 'Cable', tagable_id: nil)
    assert tag.valid?
    
    # Now create a cable using this tag
    assert_difference 'Cable.count', 1 do
      cable = create(:cable, tag: tag)
      assert_equal tag.reload.tagable, cable
    end
  end
  
  test "should prevent changing tagable association once set" do
    # Create a cable with a tag
    tag = create(:tag, :unique_tag, prefix: 'EC', project: @project, discipline: @discipline)
    cable = create(:cable, tag: tag)
    assert_equal cable, tag.tagable
    # motor = create(:motor, tag: tag)
    # refute tag.valid?
    # tag.tagable_type = 'CableType'
    # Try to change to a different tagable by assignment
    tag.tagable_id = 999
    tag.save
    assert_not tag.valid?
    assert_includes tag.errors[:base], 'Cannot change tagable association once set'

    #test again using update
    tag.reload
    tag.update(tagable: build(:cable))
    assert_not tag.valid?
    assert_includes tag.errors[:base], 'Cannot change tagable association once set'
  end
  
  test "should prevent assigning tagable that's already associated with a tag" do
    # Create a cable with a tag
    tag = create(:tag, :unique_tag, prefix: 'EC', project: @project, discipline: @discipline)
    cable = create(:cable, tag: tag)
    # Create a new tag with no association
    new_tag = create(:tag, :unique_tag, prefix: 'EC', project: @project, discipline: @discipline)

    # Try to associate the new tag with existing tagable by assignment
    new_tag.tagable = cable
    new_tag.save
    refute new_tag.valid?
    assert_includes new_tag.errors[:tagable], 'is already associated with another tag'
    assert_equal cable, tag.reload.tagable
    assert_nil new_tag.reload.tagable

    # Try the same using update method
    new_tag.update(tagable: cable)
    assert_not new_tag.valid?
    assert_includes new_tag.errors[:tagable], 'is already associated with another tag'
    assert_equal cable, tag.reload.tagable
    assert_nil new_tag.reload.tagable
  end
  
  test "should allow creating tagable with existing tag" do
    # First create a tag with type but no tagable
    tag = create(:tag, project: @project, discipline: @discipline, 
              tagable_type: 'Cable', tagable_id: nil)
    
    # Now create a cable using this tag
    assert_difference 'Cable.count', 1 do
      cable = Cable.create!(
        tag: tag,
        cable_type: create(:cable_type, :pvc_flat_twin_earth)
      )
      assert_equal tag.reload.tagable, cable
    end
  end
  
  test "should validate tagable existence" do
    @tag.tagable_type = 'Cable'
    @tag.tagable_id = 9999 # Non-existent ID
    
    assert_not @tag.valid?
    assert_includes @tag.errors[:tagable], 'must exist'
  end
  
  test "should nullify both type and id when associated record is destroyed" do
    tag = create(:tag, :unique_tag, prefix: 'EC', project: @project, discipline: @discipline)
    cable = create(:cable, tag: tag)
    
    # Store the cable id before destruction
    cable_id = cable.id
    
    # Destroy the cable - should trigger dependent: :nullify
    assert_difference('Cable.count', -1) do
      cable.destroy
    end
    
    # Verify cable is actually destroyed
    assert_raises(ActiveRecord::RecordNotFound) { Cable.find(cable_id) }
    
    # Verify tag's associations are nullified
    tag.reload
    assert_nil tag.tagable
    assert_nil tag.tagable_type
    assert_nil tag.tagable_id
  end
  
  test "should handle invalid tagable type gracefully" do
    @tag.tagable_type = 'NonExistentModel'
    @tag.tagable_id = 1
    
    assert_not @tag.valid?
    assert_includes @tag.errors[:tagable_type], 'is not a valid type'
  end
  
  test "destroy project should destroy tags" do
    tag = create(:tag, project: @project, discipline: @discipline)
    assert_difference 'Tag.count', -1 do
      @project.destroy
    end
    assert_not Tag.exists?(tag.id)
  end
end
