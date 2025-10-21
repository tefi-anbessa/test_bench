require "test_helper"

class TagTest < ActiveSupport::TestCase
  setup do
    # Set up project and discipline
    @project = create(:project)
    @discipline = create(:discipline, :e)  # Using electrical discipline as an example
    
    # Clear any existing tags to avoid uniqueness conflicts
    Tag.destroy_all
    
    # Create test tags 
    @tag_a1 = create(:tag, project: @project, discipline: @discipline, 
                     prefix: 'A', serial: 1, suffix: 'A', service: 'Service A1A')
    @tag_a2 = create(:tag, project: @project, discipline: @discipline, 
                     prefix: 'A', serial: 1, suffix: 'B', service: 'Service A1B')
    @tag_a3 = create(:tag, project: @project, discipline: @discipline, 
                     prefix: 'A', serial: 2, suffix: nil, service: 'Service A2')
    @tag_b1 = create(:tag, project: @project, discipline: @discipline, 
                     prefix: 'B', serial: 1, suffix: nil, service: 'Service B1')
    @tag_ba2 = create(:tag, project: @project, discipline: @discipline, 
                     prefix: 'BA', serial: 2, suffix: nil, service: 'Service BA2')
    @tag_bb1 = create(:tag, project: @project, discipline: @discipline, 
                     prefix: 'BB', serial: 1, suffix: nil, service: 'Service BB1')
    @tag_c1 = create(:tag, project: @project, discipline: @discipline, 
                     prefix: 'C', serial: 1, suffix: nil, service: 'Service C1')
    
    # Initialize a new tag for testing validations
    @tag = build(:tag, project: @project, discipline: @discipline)
    
    # Reload all tags to ensure we have the latest state
    [@tag_a1, @tag_a2, @tag_a3, @tag_b1, @tag_bb1, @tag_ba2, @tag_c1].each(&:reload)
  end

  # Factory Tests
  test 'tag factory should be valid' do
    tag = build(:tag, project: @project, discipline: @discipline)
    assert tag.valid?
    assert tag.prefix.present?
    assert tag.serial.present?
  end

  test 'next returns next tag in loop-based order' do
    # Test next method for each tag
    assert_equal @tag_a2, @tag_a1.next, 'A1A.next should be A1B'
    assert_equal @tag_a3, @tag_a2.next, 'A1B.next should be A2'
    assert_equal @tag_b1, @tag_a3.next, 'A2.next should be B1'
    assert_equal @tag_bb1, @tag_b1.next, 'B1.next should be BB1'
    assert_equal @tag_ba2, @tag_bb1.next, 'BB1.next should be BA2'
    assert_equal @tag_c1, @tag_ba2.next, 'BA2.next should be C1'
    assert_equal @tag_c1, @tag_c1.next, 'C1.next should return itself (last tag)'
  end

  test 'prev returns previous tag in loop-based order' do
    # Test prev method for each tag
    assert_equal @tag_ba2, @tag_c1.prev, 'C1.prev should be BA2'
    assert_equal @tag_bb1, @tag_ba2.prev, 'BA2.prev should be BB1'
    assert_equal @tag_b1, @tag_bb1.prev, 'BB1.prev should be B1'
    assert_equal @tag_a3, @tag_b1.prev, 'B1.prev should be A2'
    assert_equal @tag_a2, @tag_a3.prev, 'A2.prev should be A1B'
    assert_equal @tag_a1, @tag_a2.prev, 'A1B.prev should be A1A'
    assert_equal @tag_a1, @tag_a1.prev, 'A1A.prev should return itself (first tag)'
  end

  test 'next with loop_id attribute returns next tag in loop-based order' do
    assert_equal @tag_a2, @tag_a1.next(:loop_id), 
                 'A1A.next(:loop_id) should be A1B'
  end

  test 'prev with loop_id attribute returns previous tag in loop-based order' do
    assert_equal @tag_a1, @tag_a2.prev(:loop_id),
                 'A1B.prev(:loop_id) should be A1A'
  end

  test 'next with non-loop_id attribute falls back to parent implementation' do
    assert_equal @tag_a2, @tag_a1.next(:id),
                 'A1A.next(:id) should fall back to ID-based ordering'
  end

  test 'prev with non-loop_id attribute falls back to parent implementation' do
    assert_equal @tag_a1, @tag_a2.prev(:id),
                 'A1B.prev(:id) should fall back to ID-based ordering'
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
    assert complete_tag.service.present?
    assert complete_tag.stage.present?
    assert complete_tag.notes.present?
  end

  test "should be valid" do
    assert @tag.valid?
  end
  
  test "should require unique combination of project, discipline, prefix, serial, and suffix" do
    # Create initial tag
    tag1 = create(:tag, 
      project: @project,
      discipline: @discipline,
      prefix: 'CC',
      serial: 1001,
      suffix: 'A'
    )
    
    # Same project, same discipline, same prefix, same serial, same suffix should be invalid
    tag2 = build(:tag,
      project: tag1.project,
      discipline: tag1.discipline,
      prefix: tag1.prefix,
      serial: tag1.serial,
      suffix: tag1.suffix
    )
    refute tag2.valid?
    assert_includes tag2.errors[:base], I18n.t("activerecord.errors.models.tag.taken", tag: tag2.full_tag)
    
    # Different project, same other attributes should be valid
    tag3 = build(:tag,
      project: create(:project),
      discipline: tag1.discipline,
      prefix: tag1.prefix,
      serial: tag1.serial,
      suffix: tag1.suffix
    )
    assert tag3.valid?
    
    # Different discipline, same other attributes should be valid
    tag4 = build(:tag,
      project: tag1.project,
      discipline: create(:discipline, code: 'M'),
      prefix: tag1.prefix,
      serial: tag1.serial,
      suffix: tag1.suffix
    )
    assert tag4.valid?
    
    # Different prefix, same other attributes should be valid
    tag5 = build(:tag,
      project: tag1.project,
      discipline: tag1.discipline,
      prefix: 'CE',
      serial: tag1.serial,
      suffix: tag1.suffix
    )
    assert tag5.valid?
    
    # Different serial, same other attributes should be valid
    tag6 = build(:tag,
      project: tag1.project,
      discipline: tag1.discipline,
      prefix: tag1.prefix,
      serial: tag1.serial + 1,
      suffix: tag1.suffix
    )
    assert tag6.valid?
    
    # Different suffix, same other attributes should be valid
    tag7 = build(:tag,
      project: tag1.project,
      discipline: tag1.discipline,
      prefix: tag1.prefix,
      serial: tag1.serial,
      suffix: 'B'
    )
    assert tag7.valid?
    
    # Empty suffix should be treated as nil for uniqueness
    tag8 = create(:tag,
      project: @project,
      discipline: @discipline,
      prefix: 'CC',
      serial: 1002,
      suffix: ''
    )
    
    tag9 = build(:tag,
      project: tag8.project,
      discipline: tag8.discipline,
      prefix: tag8.prefix,
      serial: tag8.serial,
      suffix: nil
    )
    assert_not tag9.valid?
    assert_includes tag9.errors[:base], I18n.t('activerecord.errors.models.tag.taken', tag: tag9.full_tag)
  end

  test "prefix should be present" do
    @tag.prefix = ""
    assert_not @tag.valid?
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

  test "service should not be too long" do
    @tag.service = "a" * 41
    assert_not @tag.valid?
    
    @tag.service = "a" * 40
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
    refute @tag.valid?
    assert_includes @tag.errors[:tagable_type], I18n::t("errors.messages.inclusion")
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
    assert_includes tag.errors[:base], I18n::t("activerecord.errors.models.tag.change_tagable")

    #test again using update
    tag.reload
    tag.update(tagable: build(:cable))
    assert_not tag.valid?
    assert_includes tag.errors[:base], I18n::t("activerecord.errors.models.tag.change_tagable")
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
        cable_type: create(:cable_type)
      )
      assert_equal tag.reload.tagable, cable
    end
  end
  
  test "should validate tagable existence" do
    @tag.tagable_type = 'Cable'
    @tag.tagable_id = 9999 # Non-existent ID
    
    assert_not @tag.valid?
    assert_includes @tag.errors[:tagable], I18n::t("errors.messages.invalid")
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
    
    refute @tag.valid?
    assert_includes @tag.errors[:tagable_type], I18n::t("errors.messages.inclusion")
  end
  
  test "should be able to create new tag on project" do
    # Use a unique prefix that's not used in other tests
    unique_prefix = 'Z'  # Not used in any other test
    
    assert_difference('Tag.count', 1) do
      tag = create(:tag, project: @project, discipline: @discipline, 
                        prefix: unique_prefix, serial: 1, suffix: nil, service: 'New Tag')
      assert tag.valid?, "Tag should be valid but got errors: #{tag.errors.full_messages}"
    end
    
    # Verify the tag was created with the correct attributes
    assert @project.tags.exists?(prefix: unique_prefix, serial: 1, suffix: nil)
  end
  
  test "destroy project should destroy tags" do
    # Create a new project with a single tag for this test
    test_project = create(:project)
    create(:tag, project: test_project, discipline: @discipline, 
                 prefix: 'X', serial: 1, suffix: nil, service: 'Test Tag')
    
    # Verify the tag exists
    assert_equal 1, test_project.tags.count
    
    # Destroy the project and verify all its tags are destroyed
    assert_difference('Tag.count', -1) do
      test_project.destroy
    end
  end
  
  test 'tags should be ordered by loop_id, prefix, and suffix' do
    # Get just our test tags in the default scope order
    test_tag_ids = [@tag_a1, @tag_a2, @tag_a3, @tag_b1, @tag_bb1, @tag_ba2, @tag_c1].map(&:id)
    ordered_tags = Tag.where(id: test_tag_ids).to_a
    
    # Expected order based on the test data
    expected_order = [@tag_a1, @tag_a2, @tag_a3, @tag_b1, @tag_bb1, @tag_ba2, @tag_c1]
    
    # Verify the order matches exactly
    assert_equal expected_order, ordered_tags, 
      'Tags should be ordered by loop_id, prefix, and suffix'
      
    # Verify the loop_ids are generated as expected
    assert_equal @tag_a1.loop_id, @tag_a2.loop_id, 
      'Tags with same prefix and serial should have same loop_id'
    assert_equal @tag_b1.loop_id, @tag_bb1.loop_id, 
      'Tags with different prefix but same measured variable and serial should have same loop_id'
    assert_not_equal @tag_a1.loop_id, @tag_a3.loop_id,
      'Tags with different serials should have different loop_ids'
    assert_not_equal @tag_a1.loop_id, @tag_b1.loop_id,
      'Tags with different measured variable should have different loop_ids'
  end
end
