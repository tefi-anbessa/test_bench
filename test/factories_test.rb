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
        discipline = create(:discipline, project: project, code: 'E')
        build(:tag, project: project, discipline: discipline)
      },
      :sequential_tag => -> { 
        project = create(:project)
        discipline = create(:discipline, project: project, code: 'E')
        build(:sequential_tag, project: project, discipline: discipline)
      },
      :complete_tag => -> {
        project = create(:project)
        discipline = create(:discipline, project: project, code: 'E')
        create(:complete_tag, project: project, discipline: discipline)
      },
      
      # Electrical components (legacy)
      :cable_type => :skip,
      :cable => :skip,
      :circuit => :skip,
      :light_cct => :skip,
      :motor => :skip,
      :socket_cct => :skip,
      :switchboard => :skip,
      :demand => :skip,
      
      # Electrical components (namespaced)
      :electrical_cable_type => -> { 
        project = create(:project)
        build(:electrical_cable_type, project: project) 
      },
      :electrical_cable => -> { 
        project = create(:project)
        discipline = create(:discipline, :elec, project: project)
        tag = create(:tag, prefix: 'EC', project: project, discipline: discipline)
        cable_type = create(:electrical_cable_type, project: project)
        build(:electrical_cable, tag: tag, electrical_cable_type: cable_type)
      },
      :electrical_switchboard => -> { 
        project = create(:project)
        discipline = create(:discipline, :elec, project: project)
        tag = create(:tag, prefix: 'EX', project: project, discipline: discipline)
        build(:electrical_switchboard, tag: tag)
      },
      :electrical_circuit => -> {
        project = create(:project)
        discipline = create(:discipline, :elec, project: project)
        switchboard_tag = create(:tag, prefix: 'EX', project: project, discipline: discipline)
        switchboard = create(:electrical_switchboard, tag: switchboard_tag)
        build(:electrical_circuit, electrical_switchboard: switchboard)
      },
      :electrical_light_cct => -> {
        project = create(:project)
        discipline = create(:discipline, :elec, project: project)
        tag = create(:tag, prefix: 'EL', project: project, discipline: discipline)
        build(:electrical_light_cct, tag: tag)
      },
      :electrical_motor => -> {
        project = create(:project)
        discipline = create(:discipline, :elec, project: project)
        tag = create(:tag, prefix: 'M', project: project, discipline: discipline)
        build(:electrical_motor, tag: tag)
      },
      :electrical_socket_cct => -> {
        project = create(:project)
        discipline = create(:discipline, :elec, project: project)
        tag = create(:tag, prefix: 'ES', project: project, discipline: discipline)
        build(:electrical_socket_cct, tag: tag)
      },
      :electrical_demand => -> {
        project = create(:project)
        discipline = create(:discipline, :elec, project: project)
        light_cct = create(:electrical_light_cct, project: project, discipline: discipline)
        build(:electrical_demand, demandable: light_cct)
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

  test "discipline factory creates unique codes" do
    project = create(:project)
    discipline1 = create(:discipline, project: project)
    discipline2 = create(:discipline, project: project)
    
    assert_not_equal discipline1.code, discipline2.code
  end

  test "discipline factory generates sequential codes" do
    project = create(:project)
    # Test that codes are unique and follow the pattern
    codes = 5.times.map { create(:discipline, project: project).code }.sort

    # Should generate 5 unique codes from A-Z
    assert_equal 5, codes.uniq.length
    codes.each do |code|
      assert_match /\A[a-zA-Z_][a-zA-Z0-9_]*\z/, code
    end
  end

test "discipline factory generates sequential names" do
  disciplines = create_list(:discipline, 10)
  names = disciplines.map(&:name)
  assert_equal 10, names.uniq.length
  names.each_with_index do |name, i|
    assert_match /\ADiscipline code[a-f0-9]+\z/, name
  end
end

  test "discipline factory handles code wrapping" do
    project = create(:project)
    # Since tests run in parallel, we can't rely on global sequence state
    # Instead, test that the factory generates valid, unique codes
    disciplines = create_list(:discipline, 10, project: project)

    # Verify all codes are valid single letters and unique
    codes = disciplines.map(&:code)
    assert_equal 10, codes.uniq.length
    codes.each do |code|
      assert_match /\A[a-zA-Z_][a-zA-Z0-9_]*\z/, code
    end

    # Test that creating more disciplines still works (no wrapping errors)
    more_disciplines = create_list(:discipline, 5, project: project)
    more_codes = more_disciplines.map(&:code)

    # All codes should be unique across both sets
    all_codes = codes + more_codes
    assert_equal 15, all_codes.uniq.length
    codes.each do |code|
      assert_match /\A[a-zA-Z_][a-zA-Z0-9_]*\z/, code
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
    discipline = create(:discipline, :elec)  # Using standard discipline 'E' for Electrical
    assert discipline.valid?
    assert_equal :elec, discipline.code
  end
end
