require 'test_helper'

class FactoriesTest < ActiveSupport::TestCase
  # Test that all factories can be created and are valid
  test 'all factories are valid' do
    # Define factory-specific test cases
    factory_tests = {
      # Core models
      :user => -> { build(:user) },
      :role => -> { build(:role, :admin) },
      :project => -> { build(:project) },
      :discipline => -> { build(:discipline) },
      :tag => -> { build(:tag, project: create(:project), discipline: create(:discipline)) },
      :sequential_tag => -> { build(:sequential_tag, project: create(:project), discipline: create(:discipline)) },
      :complete_tag => -> { 
        project = create(:project)
        discipline = create(:discipline)
        create(:complete_tag, project: project, discipline: discipline)
      },
      
      # Electrical components
      :cable_type => -> { build(:cable_type) },
      :cable => -> { build(:cable) },
      :circuit => -> { 
        switchboard = create(:switchboard)
        build(:circuit, switchboard: switchboard)
      },
      :light_cct => -> { build(:light_cct) },
      :motor => -> { build(:motor) },
      :socket_cct => -> { build(:socket_cct) },
      :switchboard => -> { build(:switchboard) },
      :demand => -> { 
        build(:demand, :with_light_cct)
      },
      
      # Roles and permissions
      :resource_role => -> { build(:resource_role, :project_project_owner) },
      :user_role => -> { 
        user = create(:user)
        user.grant(:admin)
        user
      }
    }
    
    # Get all registered factories
    factory_names = FactoryBot.factories.map(&:name)
    
    # Test each factory
    factory_names.sort.each do |factory_name|
      next unless factory_tests.key?(factory_name) # Skip if no test defined
      next if factory_tests[factory_name] == :skip # Skip explicitly skipped factories
      
      begin
        DatabaseCleaner.cleaning do
          instance = factory_tests[factory_name].call
          assert instance.valid?, 
                 "#{factory_name} factory is invalid: #{instance.errors.full_messages.to_sentence}"
        end
      rescue StandardError => e
        flunk "Error with #{factory_name} factory: #{e.message}\n#{e.backtrace.first(5).join("\n")}"
      end
    end
    
    # Verify we're testing all factories
    untested_factories = factory_names - factory_tests.keys
    assert_empty untested_factories, "The following factories are not being tested: #{untested_factories.join(', ')}"
  end

  # User factory tests
  test 'user factory' do
    user = build(:user)
    assert user.valid?, "User should be valid: #{user.errors.full_messages.join(', ')}"
    assert user.email.present?
    assert user.encrypted_password.present?
    assert_match /^[a-zA-Z0-9_.-]*$/, user.name, 'Name should match the required format'
  end

  test 'admin user factory' do
    admin = create(:user, :admin)
    assert admin.valid?, "Admin user should be valid: #{admin.errors.full_messages.join(', ')}"
    assert admin.has_role?(:admin), 'User should have admin role'
  end

  # Project factory tests
  test 'project factory' do
    project = build(:project)
    assert project.valid?
    assert project.code.present?
    assert_match Project::VALID_CODE_REGEX, project.code
  end

  # Role factory tests
  test 'role factory with valid role' do
    # Test with a global role
    role = create(:role, :admin)
    assert role.valid?, "Role should be valid: #{role.errors.full_messages.join(', ')}"
    assert_equal 'admin', role.name
    assert_nil role.resource_type
    
    # Test with a resource-specific role using the project_owner trait
    role = create(:role, :project_project_owner)
    assert role.valid?, "Role should be valid: #{role.errors.full_messages.join(', ')}"
    assert_equal 'project_owner', role.name
    assert_equal 'Project', role.resource_type
    assert_not_nil role.resource
  end

  # Tag factory tests
  test 'tag factory' do
    tag = build(:tag, project: create(:project), discipline: create(:discipline))
    assert tag.valid?
    assert tag.prefix.present?
    assert tag.serial.present?
  end

  test 'tag with notes' do
    tag = build(:tag, :with_notes, project: create(:project), discipline: create(:discipline))
    assert tag.valid?
    assert tag.notes.present?
  end

  test 'tag with full tag' do
    project = create(:project, code: 'XX')
    discipline = create(:discipline, code: 'M')
    tag = create(:tag, 
      project: project, 
      discipline: discipline, 
      prefix: 'P', 
      serial: 1, 
      suffix: 'A',
      stage: 1
    )
    
    # Save and reload to trigger after_find callback
    tag.save!
    tag.reload
    
    assert tag.valid?, "Tag should be valid: #{tag.errors.full_messages.join(', ')}"
    # Format is "M:P-0001.A" (discipline:prefix-serial.suffix)
    assert_equal 'M:P-0001.A', tag.full_tag, "Full tag should be in format 'M:P-0001.A'"
  end

  # Discipline factory test
  test 'discipline factory' do
    discipline = build(:discipline)
    assert discipline.valid?
    assert discipline.name.present?
    assert discipline.code.present?
  end
  
  test 'creates all standard disciplines' do
    # Create all standard disciplines using factory traits (lowercase code as trait name)
    create(:discipline, :a)  # Administration
    create(:discipline, :b)  # Architecture
    create(:discipline, :c)  # Civil Engineering
    create(:discipline, :e)  # Electrical Engineering
    create(:discipline, :i)  # Information Tech
    create(:discipline, :j)  # Instrument Engineering
    create(:discipline, :m)  # Mechanical Engineering
    create(:discipline, :p)  # Process Engineering
    create(:discipline, :u)  # Multi-Discipline

    # Verify all standard disciplines exist
    Discipline::DISCIPLINES.each do |discipline|
      assert Discipline.exists?(code: discipline[:code], name: discipline[:name]), 
             "Expected to find discipline: #{discipline[:name]} (#{discipline[:code]})"
    end
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
  
  
  test 'project is valid' do
    project = create(:project, code: 'AA')
    assert project.valid?, "Project is not valid: #{project.errors.full_messages.join(', ')}"
  end
  
  test 'project with tags is valid' do
    project = create(:project, code: 'CC')
    discipline = create(:discipline, code: 'M')
    create_list(:tag, 3, project: project, discipline: discipline)
    assert project.valid?, "Project with tags is not valid: #{project.errors.full_messages.join(', ')}"
  end
  
  test 'project with civil tags is valid' do
    project = create(:project, code: 'DD')
    discipline = create(:discipline, :c)  # Using standard discipline 'C' (Civil)
    create_list(:tag, 2, :civil, project: project, discipline: discipline)
    assert project.valid?, "Project with civil tags is not valid: #{project.errors.full_messages.join(', ')}"
  end
  
  test 'discipline variants are valid' do
    # Test creating a standard discipline
    discipline = create(:discipline, :a)  # Using standard discipline 'A'
    assert discipline.valid?
    assert_equal 'A', discipline.code
    
    # Test creating another standard discipline
    discipline2 = create(:discipline, :b)  # Using standard discipline 'B'
    assert discipline2.valid?
    assert_equal 'B', discipline2.code
  end
  
  test 'tag variants are valid' do
    project = create(:project, code: 'TT')
    
    # Test creating tags with different standard disciplines
    tag = create(:tag, :civil, project: project)  # Using civil discipline
    assert tag.valid?
    assert_equal 'C', tag.prefix  # Civil tags use 'C' prefix
    
    # Test with notes
    tag_with_notes = create(:tag, :with_notes, :electrical, project: project)  # Using electrical discipline
    assert tag_with_notes.valid?
    assert_not_nil tag_with_notes.notes
    
    # Test mechanical tag
    mechanical_tag = create(:tag, :mechanical, project: project)  # Using mechanical discipline
    assert mechanical_tag.valid?
    
    # Test sequential tag with electrical discipline
    sequential_tag = create(:tag, :sequential, :electrical, project: project)
    assert sequential_tag.valid?
  end
  

end
