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
    role = create(:role, :project_project_owner, resource: @project)
    assert_equal 'project_owner', role.name
    assert_equal 'Project', role.resource_type
    assert_equal @project.id, role.resource_id
  end

  test "should create resource role with factory" do
    role = create(:resource_role, resource: @project, name: 'team_member')
    assert_equal 'team_member', role.name
    assert_equal 'Project', role.resource_type
    assert_equal @project.id, role.resource_id
  end

  test "should assign role to user" do
    user = create(:user)
    role = create(:role, :electrical_designer)
    
    assert_difference 'user.roles.count', 1 do
      user.add_role(role.name.to_sym, role.resource)
    end
    
    assert user.has_role?(role.name.to_sym, role.resource)
  end

  test "should not allow invalid resource types" do
    role = build(:role, resource_type: 'InvalidModel')
    assert_not role.valid?
    assert_includes role.errors[:resource_type], 'is not included in the list'
  end

  test "should not allow duplicate role names for the same resource" do
    # Create a global role
    admin_role = create(:role, :admin)
    
    # Should be invalid - same name and nil resource
    duplicate_global = build(:role, name: 'admin')
    assert_not duplicate_global.valid?
    assert_includes duplicate_global.errors[:name], 'role already exists for this resource'
    
    # Should be valid - different resource type with valid role name
    project = create(:project)
    project_role = build(:role, name: 'project_owner', resource: project)
    assert project_role.valid?, "Expected role with valid name to be valid: #{project_role.errors.full_messages}"
  end

  test "should return ransackable attributes" do
    assert_equal ["name", "id"], Role.ransackable_attributes
  end

  test "should return ransackable associations" do
    assert_equal ["users", "resource"], Role.ransackable_associations
  end
end
