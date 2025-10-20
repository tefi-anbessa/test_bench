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
      :tag => -> { 
        project = create(:project)
        discipline = create(:discipline, code: 'E')
        build(:tag, project: project, discipline: discipline)
      },
      :sequential_tag => -> { 
        project = create(:project)
        discipline = create(:discipline, code: 'E')
        build(:sequential_tag, project: project, discipline: discipline)
      },
      :complete_tag => -> {
        project = create(:project)
        discipline = create(:discipline, code: 'E')
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
        light_cct = create(:light_cct)
        build(:demand, demandable: light_cct)
      },
      
      # Roles and permissions
      :resource_role => -> { build(:resource_role, :project_project_manager) },
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
    
    # Verify we're testing all factories (excluding discipline_set which is now a trait)
    untested_factories = factory_names - factory_tests.keys - [:discipline_set]
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
  end
  
  test 'resource role factory with project manager' do
    # Test with a resource-specific role
    role = create(:resource_role, :project_project_manager)
    assert role.valid?, "Role should be valid: #{role.errors.full_messages.join(', ')}"
    assert_equal 'project_manager', role.name
    assert_equal 'Project', role.resource_type
    assert_not_nil role.resource
  end


  # Discipline factory test
  test 'discipline factory' do
    discipline = build(:discipline)
    assert discipline.valid?, "Discipline should be valid: #{discipline.errors.full_messages.join(', ')}"
  end

  test 'can create all standard disciplines using trait' do
    # Clear any existing disciplines to avoid unique constraint issues
    Discipline.destroy_all
    
    # Create one discipline with the trait to create all standard ones
    create(:discipline, :with_all_standard)
    
    # Verify all standard disciplines were created
    assert_equal Discipline::DISCIPLINES.size, Discipline.count
    
    # Verify all created disciplines have valid codes and names
    discipline_codes = Discipline.pluck(:code)
    discipline_names = Discipline.pluck(:name)
    
    Discipline::DISCIPLINES.each do |disc|
      assert_includes discipline_codes, disc[:code], "Missing discipline with code #{disc[:code]}"
      assert_includes discipline_names, disc[:name], "Missing discipline with name #{disc[:name]}"
    end
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
  
  test 'discipline with standard code is valid' do
    # Test creating a standard discipline
    discipline = create(:discipline, :e)  # Using standard discipline 'E' for Electrical
    assert discipline.valid?
    assert_equal 'E', discipline.code
  end
  
  

end
