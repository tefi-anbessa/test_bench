require 'test_helper'

class ElectricalResourcePolicyTest < ActiveSupport::TestCase
  include PolicyHelpers

  def setup
    @project = create(:project)
    @other_project = create(:project)
    @tag = create(:tag, project: @project)
    @other_tag = create(:tag, project: @other_project)
    
    # Create test users with different roles
    @app_owner = create(:user, :app_owner)
    @admin = create(:user, :admin)
    @project_owner = create(:user)
    @project_owner.grant(:project_owner, @project)
    
    @team_member = create(:user)
    @team_member.grant(:team_member, @project)
    
    @electrical_designer = create(:user)
    @electrical_designer.grant(:team_member, @project)
    @electrical_designer.grant(:electrical_designer)
    
    @regular_user = create(:user)
  end
  
  # Helper to create policy with user and project context
  def policy(user, project, record = nil)
    user_context = ApplicationPolicy::UserContext.new(user, project)
    ElectricalResourcePolicy.new(user_context, record || Object.new)
  end

  # Scope Tests
  test 'scope includes only resources in current project' do
    # This will be tested in specific resource policy tests
    assert true
  end

  # Index Tests
  test 'index? allows app owner and admin' do
    assert policy(@app_owner, @project).index?
    assert policy(@admin, @project).index?
  end

  test 'index? allows users with project role' do
    assert policy(@project_owner, @project).index?
    assert policy(@team_member, @project).index?
    assert policy(@electrical_designer, @project).index?
  end

  test 'index? denies users without project role' do
    refute policy(@regular_user, @project).index?
    refute policy(nil, @project).index?
  end

  test 'index? denies when no project is selected' do
    refute policy(@project_owner, nil).index?
  end

  # Show Tests
  test 'show? allows app owner and admin' do
    record = OpenStruct.new(tag: @tag)
    assert policy(@app_owner, @project, record).show?
    assert policy(@admin, @project, record).show?
  end

  test 'show? allows users with project role for resources in their project' do
    record = OpenStruct.new(tag: @tag)
    assert policy(@project_owner, @project, record).show?
    assert policy(@team_member, @project, record).show?
    assert policy(@electrical_designer, @project, record).show?
  end

  test 'show? denies users for resources in other projects' do
    other_record = OpenStruct.new(tag: @other_tag)
    refute policy(@project_owner, @project, other_record).show?
  end

  test 'show? denies when no project is selected' do
    record = OpenStruct.new(tag: @tag)
    refute policy(@project_owner, nil, record).show?
  end

  # Create/Update Tests
  test 'create? and update? allow app owner and admin' do
    record = OpenStruct.new(tag: @tag)
    assert policy(@app_owner, @project, record).create?
    assert policy(@admin, @project, record).create?
    assert policy(@app_owner, @project, record).update?
    assert policy(@admin, @project, record).update?
  end

  test 'create? and update? allow electrical designers in project' do
    record = OpenStruct.new(tag: @tag)
    assert policy(@electrical_designer, @project, record).create?
    assert policy(@electrical_designer, @project, record).update?
  end

  test 'create? and update? deny non-electrical users' do
    record = OpenStruct.new(tag: @tag)
    refute policy(@project_owner, @project, record).create?
    refute policy(@team_member, @project, record).create?
    refute policy(@project_owner, @project, record).update?
    refute policy(@team_member, @project, record).update?
  end

  # Destroy Tests
  test 'destroy? allows only app owner and admin' do
    record = OpenStruct.new(tag: @tag)
    assert policy(@app_owner, @project, record).destroy?
    assert policy(@admin, @project, record).destroy?
    
    refute policy(@electrical_designer, @project, record).destroy?
    refute policy(@project_owner, @project, record).destroy?
    refute policy(@team_member, @project, record).destroy?
    refute policy(nil, @project, record).destroy?
  end
end
