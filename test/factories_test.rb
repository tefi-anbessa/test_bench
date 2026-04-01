require 'test_helper'

class FactoriesTest < ActiveSupport::TestCase
  # Test that all factories can be created and are valid
  test 'all factories are valid' do
    # Get all registered factories
    factory_names = FactoryBot.factories.map(&:name)
    
    # Test each factory automatically
    factory_names.sort.each do |factory_name|
      begin
        DatabaseCleaner.cleaning do
          # Simply build the factory with no parameters
          instance = build(factory_name)
          
          assert instance.valid?, 
                 "#{factory_name} factory is invalid: #{instance.errors.full_messages.to_sentence}"
        end
      rescue StandardError => e
        flunk "Error with #{factory_name} factory: #{e.message}\n#{e.backtrace.first(5).join("\n")}"
      end
    end
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

  test "discipline factory creates unique names and labels" do
    project = create(:project)
    discipline1 = create(:discipline, project: project)
    discipline2 = create(:discipline, project: project)
    
    assert_not_equal discipline1.name, discipline2.name
    assert_not_equal discipline1.label, discipline2.label
  end

  test "discipline factory generates sequential names" do
    disciplines = create_list(:discipline, 10)
    names = disciplines.map(&:name)
    assert_equal 10, names.uniq.length
    names.each_with_index do |name, i|
      assert_match /\AFactory Discipline [a-f0-9]+\z/, name
    end
  end
  
  test 'project is valid' do
    project = create(:project, code: 'AA')
    assert project.valid?, "Project is not valid: #{project.errors.full_messages.join(', ')}"
  end
  
  test 'project with tags is valid' do
    project = create(:project, code: 'CC')
    discipline = create(:discipline, label: 'M')
    create_list(:tag, 3, project: project, discipline: discipline)
    assert project.valid?, "Project with tags is not valid: #{project.errors.full_messages.join(', ')}"
  end
end
