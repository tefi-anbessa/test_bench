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
    role = create(:role, :project_owner, resource: @project)
    assert_equal 'project_owner', role.name
    assert_equal 'Project', role.resource_type
    assert_equal @project.id, role.resource_id
  end

  test "should create resource role with factory" do
    role = create(:resource_role, resource: @project, name: 'editor')
    assert_equal 'editor', role.name
    assert_equal 'Project', role.resource_type
    assert_equal @project.id, role.resource_id
  end

  test "should assign role to user" do
    user = create(:user)
    role = create(:role, :editor)
    
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
    # Create a role with a specific name
    role1 = create(:role, name: 'test_role')
    
    # Should be invalid - same name and nil resource
    role2 = build(:role, name: 'test_role', resource_type: nil, resource_id: nil)
    assert_not role2.valid?
    assert_includes role2.errors[:name], 'role already exists for this resource'
    
    # Should be valid - same name but different resource
    role3 = build(:role, name: 'test_role', resource: @project)
    assert role3.valid?, "Expected role with same name but different resource to be valid: #{role3.errors.full_messages}"
  end

  test "should return ransackable attributes" do
    assert_equal ["name", "id"], Role.ransackable_attributes
  end

  test "should return ransackable associations" do
    assert_equal ["users", "roles"], Role.ransackable_associations
  end
end
