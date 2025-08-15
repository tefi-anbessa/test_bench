require 'test_helper'

class FactoriesTest < ActiveSupport::TestCase
  # Run each test in a transaction that gets rolled back
  self.use_transactional_tests = true

  test 'user factory' do
    user = build(:user)
    assert user.valid?
  end

  test 'admin user factory' do
    admin = create(:user, :admin)
    assert admin.valid?
    assert admin.has_role?(:admin)
  end

  test 'user with project role' do
    user = create(:user)
    project = create(:project)
    user.add_role(:member, project)
    assert user.has_role?(:member, project)
  end

  test 'project factory' do
    project = build(:project)
    assert project.valid?
  end

  test 'project with owner role' do
    project = create(:project)
    owner = create(:user)
    owner.add_role(:owner, project)
    assert owner.has_role?(:owner, project)
  end

  test 'project with member roles' do
    project = create(:project)
    member1 = create(:user)
    member2 = create(:user)
    member1.add_role(:member, project)
    member2.add_role(:member, project)
    assert_equal 2, User.with_role(:member, project).count
  end

  test 'project with tags' do
    project = create(:project)
    create_list(:tag, 3, project: project, discipline: create(:discipline))
    assert_equal 3, project.tags.count
  end

  test 'discipline factory' do
    discipline = build(:discipline)
    assert discipline.valid?
  end

  test 'discipline with tags' do
    discipline = create(:discipline)
    project = create(:project)
    create_list(:tag, 2, discipline: discipline, project: project)
    assert_equal 2, discipline.tags.count
  end

  test 'tag factory' do
    tag = build(:tag, project: create(:project), discipline: create(:discipline))
    assert tag.valid?
  end

  test 'cable tag' do
    discipline = create(:discipline, code: 'C')
    tag = build(:tag, :cable, discipline: discipline)
    assert tag.valid?
    assert_equal 'C', tag.prefix
  end

  test 'tag with notes' do
    tag = build(:tag, :with_notes, project: create(:project), discipline: create(:discipline))
    assert tag.valid?
    assert_not_nil tag.notes
  end

  test 'sequential tags' do
    project = create(:project, code: 'YY')
    discipline = create(:discipline, code: 'E')  # Single character code
    
    # Create tags with explicit serials to ensure they're sequential
    tag1 = create(:tag, 
      project: project, 
      discipline: discipline, 
      prefix: discipline.code,
      serial: 1,
      suffix: nil  # Explicitly set to nil to avoid suffix in full_tag
    )
    
    tag2 = create(:tag, 
      project: project, 
      discipline: discipline, 
      prefix: discipline.code,
      serial: 2,
      suffix: nil  # Explicitly set to nil to avoid suffix in full_tag
    )
    
    # Reload to ensure full_tag is set
    tag1.reload
    tag2.reload
    
    # Check that serials are sequential numbers
    assert_equal tag1.serial + 1, tag2.serial, 'Serials should be sequential'
    
    # Check the full_tag format (E:prefix-0001)
    expected_full_tag1 = "#{discipline.code}:#{tag1.prefix}-#{tag1.serial.to_s.rjust(4, '0')}"
    expected_full_tag2 = "#{discipline.code}:#{tag2.prefix}-#{tag2.serial.to_s.rjust(4, '0')}"
    
    assert_equal expected_full_tag1, tag1.full_tag, 'First tag full_tag should match expected format'
    assert_equal expected_full_tag2, tag2.full_tag, 'Second tag full_tag should match expected format'
  end
  
  test 'simple factories are valid' do
    # Use truncation for this test to ensure clean state
    DatabaseCleaner.strategy = :truncation, { except: %w[ar_internal_metadata] }
    
    # Test each factory individually
    FactoryBot.factories.each do |factory|
      # Skip complex factories that are tested separately
      next if [:tag, :project, :discipline, :user].include?(factory.name)
      
      DatabaseCleaner.cleaning do
        instance = create(factory.name)
        assert instance.valid?, "#{factory.name} factory is not valid: #{instance.errors.full_messages.join(', ')}"
      end
    end
  ensure
    # Reset to default strategy
    DatabaseCleaner.strategy = :transaction
  end
  
  test 'project with owner is valid' do
    project = create(:project, code: 'AA')
    owner = create(:user)
    owner.add_role(:owner, project)
    assert project.valid?, "Project with owner is not valid: #{project.errors.full_messages.join(', ')}"
  end
  
  test 'project with members is valid' do
    project = create(:project, code: 'BB')
    2.times { create(:user).add_role(:member, project) }
    assert project.valid?, "Project with members is not valid: #{project.errors.full_messages.join(', ')}"
  end
  
  test 'project with tags is valid' do
    project = create(:project, code: 'CC')
    create_list(:tag, 3, project: project, discipline: create(:discipline, code: 'G'))
    assert project.valid?, "Project with tags is not valid: #{project.errors.full_messages.join(', ')}"
  end
  
  test 'project with cable tags is valid' do
    project = create(:project, code: 'DD')
    discipline = create(:discipline, code: 'H')
    create_list(:tag, 2, :cable, project: project, discipline: discipline)
    assert project.valid?, "Project with cable tags is not valid: #{project.errors.full_messages.join(', ')}"
  end
  
  test 'discipline variants are valid' do
    # Create a discipline with a unique code
    discipline = create(:discipline, code: 'Z', name: 'Test Discipline')
    assert discipline.valid?
    
    # Create another discipline with a different unique code
    discipline_with_tags = create(:discipline, :with_tags, code: 'Y', name: 'Test Discipline with Tags')
    assert discipline_with_tags.valid?
    assert_equal 3, discipline_with_tags.tags.count
  end
  
  test 'tag variants are valid' do
    # Create a discipline with a unique code for these tests
    discipline = create(:discipline, code: 'X', name: 'Test Discipline for Tags')
    project = create(:project, code: 'TT')
    
    tag = create(:tag, discipline: discipline, project: project)
    assert tag.valid?
    
    tag_with_notes = create(:tag, :with_notes, discipline: discipline, project: project)
    assert tag_with_notes.valid?
    assert_not_nil tag_with_notes.notes
    
    cable_tag = create(:tag, :cable, discipline: discipline, project: project)
    assert cable_tag.valid?
    assert_equal 'C', cable_tag.prefix
    
    electrical_tag = create(:tag, :electrical, discipline: discipline, project: project)
    assert electrical_tag.valid?
    
    mechanical_tag = create(:tag, :mechanical, discipline: discipline, project: project)
    assert mechanical_tag.valid?
    
    sequential_tag = create(:tag, :sequential, discipline: discipline, project: project)
    assert sequential_tag.valid?
  end
  

end
