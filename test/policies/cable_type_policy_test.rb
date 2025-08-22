require 'test_helper'

class CableTypePolicyTest < ActiveSupport::TestCase
  # Setup test data
  setup do
    @project = create(:project)
    @other_project = create(:project)
    
    @cable_type = create(:cable_type, project: @project)
    @other_cable_type = create(:cable_type, project: @other_project)
    
    # Create test users
    @admin = create(:user)
    @admin.add_role(:admin)
    
    @app_owner = create(:user)
    @app_owner.add_role(:app_owner)
    
    @electrical_designer = create(:user)
    @electrical_designer.add_role(:electrical_designer) # Global role
    @electrical_designer.add_role(:team_member, @project) # Project-specific role
    
    @electrical_designer_no_team = create(:user)
    @electrical_designer_no_team.add_role(:electrical_designer) # Global role
    
    @regular_user = create(:user)
  end
  
  # Helper to create policy with user and project context
  def policy(user, project, record = nil)
    user_context = ApplicationPolicy::UserContext.new(user, project)
    CableTypePolicy.new(user_context, record || CableType)
  end
  
  # Scope Tests
  test 'scope returns cable types for current project' do
    context = ApplicationPolicy::UserContext.new(@electrical_designer, @project)
    scope = CableTypePolicy::Scope.new(context, CableType).resolve
    assert_includes scope, @cable_type
    refute_includes scope, @other_cable_type
  end
  
  test 'scope returns empty when no project is selected' do
    context = ApplicationPolicy::UserContext.new(@electrical_designer, nil)
    scope = CableTypePolicy::Scope.new(context, CableType).resolve
    assert_empty scope
  end
  
  # Index Tests
  test 'index? allows any user when project is selected' do
    assert policy(@regular_user, @project).index?
  end
  
  test 'index? denies when no project is selected' do
    refute policy(@regular_user, nil).index?
  end
  
  # Show Tests
  test 'show? allows viewing cable type in current project' do
    assert policy(@electrical_designer, @project, @cable_type).show?
  end
  
  test 'show? denies viewing cable type from other projects' do
    refute policy(@electrical_designer, @project, @other_cable_type).show?
  end
  
  test 'show? denies when no project is selected' do
    refute policy(@electrical_designer, nil, @cable_type).show?
  end
  
  # Edit Tests
  # Electrical designer with project team membership
  test 'electrical designers with project team membership have full edit control but not destroy' do
    # For create? and new?, we pass the class as the record
    assert policy(@electrical_designer, @project, CableType).create?
    assert policy(@electrical_designer, @project, CableType).new?
    
    # For update? and edit?, we pass the instance as the record
    assert policy(@electrical_designer, @project, @cable_type).update?
    assert policy(@electrical_designer, @project, @cable_type).edit?
    refute policy(@electrical_designer, @project, @cable_type).destroy?
  end
  
  test 'electrical designers without project team membership have no edit access' do
    refute policy(@electrical_designer_no_team, @project, CableType).create?
    refute policy(@electrical_designer_no_team, @project, CableType).new?
    refute policy(@electrical_designer_no_team, @project, @cable_type).update?
    refute policy(@electrical_designer_no_team, @project, @cable_type).edit?
    refute policy(@electrical_designer_no_team, @project, @cable_type).destroy?
  end

  # Regular team member tests
  test 'regular team members without electrical designer role have no edit access' do
    refute policy(@regular_user, @project, CableType).create?
    refute policy(@regular_user, @project, CableType).new?
    refute policy(@regular_user, @project, @cable_type).update?
    refute policy(@regular_user, @project, @cable_type).edit?
    refute policy(@regular_user, @project, @cable_type).destroy?
  end
  
  # Destroy Tests
  test 'admin can destroy' do
    assert policy(@admin, @project, @cable_type).destroy?
  end
  
  test 'app owner can destroy' do
    assert policy(@app_owner, @project, @cable_type).destroy?
  end

  

end
