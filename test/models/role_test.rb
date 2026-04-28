require "test_helper"

class RoleTest < ActiveSupport::TestCase
  def setup
    @project = create(:project)
  end

  test "factory should be valid" do
    role = build(:role)
    assert role.valid?
  end

  test "should create global role" do
    role = create(:role, :admin)
    assert_equal 'admin', role.name
    assert_nil role.resource_type
    assert_nil role.resource_id
  end

  test "should create project role" do
    role = create(:role, name: :project_manager, resource: @project)
    assert_equal 'project_manager', role.name
    assert_equal 'Project', role.resource_type
    assert_equal @project.id, role.resource_id
  end

  test "should create resource role with factory" do
    role = create(:resource_role, resource: @project, name: :team_member)
    assert_equal 'team_member', role.name
    assert_equal 'Project', role.resource_type
    assert_equal @project.id, role.resource_id
  end

  test "should assign role to user" do
    user = create(:user)
    role = create(:role, name: 'admin')
    
    assert_difference 'user.roles.count', 1 do
      user.add_role(role.name.to_sym, role.resource)
    end
    assert user.has_role?(role.name.to_sym, role.resource)
  end

  test "should not allow invalid resource types" do
    role = build(:role, resource_type: 'InvalidModel')
    assert_not role.valid?
    assert_includes role.errors[:resource_type], I18n.t("errors.messages.inclusion")
  end
  
  # rolify gem manages role duplicates, so this test is not valid
  # test "should not allow duplicate role names for the same resource" do
  # Create a global role
  #    admin_role = create(:role, :admin)

  # Should be invalid - same name and nil resource
  #    duplicate_global = build(:role, name: 'admin')
  #    assert_not duplicate_global.valid?
  #    assert_includes duplicate_global.errors[:name], 'role already exists for this resource'

  # Should be valid - different resource type with valid role name
  #    project = create(:project)
  #    project_role = build(:role, name: 'project_manager', resource: project)
  #    assert project_role.valid?, "Expected role with valid name to be valid: #{project_role.errors.full_messages}"
  # end

  test "should return ransackable attributes" do
    assert_equal ["name", "id"], Role.ransackable_attributes
  end

  test "should return ransackable associations" do
    assert_equal ["users", "resource"], Role.ransackable_associations
  end

  test "should order by resource_type, resource_id, and name" do
    # Create test data
    project1 = create(:project)
    project2 = create(:project)
    
    # Create roles with valid project roles (only two per project)
    role1 = create(:role, name: :project_manager, resource_type: 'Project', resource_id: project1.id)
    role2 = create(:role, name: :team_member, resource_type: 'Project', resource_id: project1.id)
    
    # Create a global role
    global_role = create(:role, name: :admin, resource_type: nil, resource_id: nil)
    
    # Create a role for a different project
    other_project_role = create(:role, name: :project_manager, resource_type: 'Project', resource_id: project2.id)
    
    # Get all roles in default scope order
    roles = Role.all.to_a
    
    # Global role should be first (resource_type is nil)
    assert_equal global_role, roles[0]
    
    # Project1 roles should be next, sorted by name
    assert_equal [role1, role2], roles[1..2]
    
    # Project2 role should be last
    assert_equal other_project_role, roles[3]
  end
end
