require 'test_helper'

class CableTypePolicyTest < ActiveSupport::TestCase
  setup do
    @project = create(:project)
    @other_project = create(:project)
    @cable_type = create(:cable_type, project: @project)
    @other_cable_type = create(:cable_type, project: @other_project)
    
    # Create test users with different roles
    @admin = create(:user)
    @admin.add_role(:admin)  # Global admin role
    
    @app_owner = create(:user)
    @app_owner.add_role(:app_owner)  # Global app_owner role
    
    @electrical_designer = create(:user)
    @electrical_designer.add_role(:electrical_designer)  # Global functional role
    @electrical_designer.add_role(:team_member, @project)  # Project membership
    
    @other_electrical_designer = create(:user)
    @other_electrical_designer.add_role(:electrical_designer)  # Global functional role
    @other_electrical_designer.add_role(:team_member, @other_project)  # Other project membership
    
    @regular_user = create(:user)
  end

  # Helper to set current project in the request
  def with_current_project(project, &block)
    @current_project = project
    yield
  ensure
    @current_project = nil
  end

  # Scope Tests
  test 'scope returns cable types for the current project' do
    with_current_project(@project) do
      scope = CableTypePolicy::Scope.new(@electrical_designer, CableType.all, @project).resolve
      assert_includes scope, @cable_type
      refute_includes scope, @other_cable_type
    end
  end

  test 'scope returns empty when no project is selected' do
    scope = CableTypePolicy::Scope.new(@electrical_designer, CableType.all, nil).resolve
    assert_empty scope
  end

  # Index Tests
  test 'index? allows any user when project is selected' do
    policy = CableTypePolicy.new(@regular_user, @cable_type)
    policy.instance_variable_set(:@project, @project)
    assert policy.index?
  end

  test 'index? denies when no project is selected' do
    policy = CableTypePolicy.new(@regular_user, @cable_type)
    policy.instance_variable_set(:@project, nil)
    refute policy.index?
  end

  # Show Tests
  test 'show? allows viewing cable type in current project' do
    policy = CableTypePolicy.new(@regular_user, @cable_type)
    policy.instance_variable_set(:@project, @project)
    assert policy.show?
  end

  test 'show? denies viewing cable type from other projects' do
    policy = CableTypePolicy.new(@regular_user, @cable_type)
    policy.instance_variable_set(:@project, @other_project)
    refute policy.show?
  end

  # Create Tests
  test 'create? allows electrical designers' do
    policy = CableTypePolicy.new(@electrical_designer, CableType.new(project: @project))
    policy.instance_variable_set(:@project, @project)
    assert policy.create?
  end

  test 'create? denies regular users' do
    policy = CableTypePolicy.new(@regular_user, CableType.new(project: @project))
    policy.instance_variable_set(:@project, @project)
    refute policy.create?
  end
  
  test 'create? denies electrical designers without project membership' do
    electrical_designer = create(:user)
    electrical_designer.add_role(:electrical_designer)  # Global role only, no project membership
    
    policy = CableTypePolicy.new(electrical_designer, CableType.new(project: @project))
    policy.instance_variable_set(:@project, @project)
    refute policy.create?
  end

  test 'create? denies when no project is selected' do
    refute CableTypePolicy.new(@electrical_designer, CableType.new).create?
  end

  # Update Tests
  test 'update? allows electrical designers' do
    policy = CableTypePolicy.new(@electrical_designer, @cable_type)
    policy.instance_variable_set(:@project, @project)
    assert policy.update?
  end

  test 'update? denies regular users' do
    policy = CableTypePolicy.new(@regular_user, @cable_type)
    policy.instance_variable_set(:@project, @project)
    refute policy.update?
  end

  test 'update? denies when no project is selected' do
    policy = CableTypePolicy.new(@electrical_designer, @cable_type)
    policy.instance_variable_set(:@project, nil)
    refute policy.update?
  end

  # Destroy Tests
  test 'destroy? only allows global admin or app owner' do
    admin = create(:user, :admin)
    app_owner = create(:user, :app_owner)

    [admin, app_owner].each do |user|
      policy = CableTypePolicy.new(user, @cable_type)
      policy.instance_variable_set(:@project, @project)
      assert policy.destroy?
    end

    [@electrical_designer, @regular_user].each do |user|
      policy = CableTypePolicy.new(user, @cable_type)
      policy.instance_variable_set(:@project, @project)
      refute policy.destroy?
    end
  end

  # New/Edit Delegation Tests
  test 'new? delegates to create?' do
    policy = CableTypePolicy.new(@electrical_designer, CableType.new(project: @project))
    policy.instance_variable_set(:@project, @project)
    assert policy.new?
  end

  test 'edit? delegates to update?' do
    policy = CableTypePolicy.new(@electrical_designer, @cable_type)
    policy.instance_variable_set(:@project, @project)
    assert policy.edit?
  end
end
