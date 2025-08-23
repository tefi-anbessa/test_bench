require 'test_helper'

class ProjectPolicyTest < ActiveSupport::TestCase
  def setup
    @project = create(:project)
    @app_owner = create(:user, :app_owner)
    @admin = create(:user, :admin)
    @regular_user = create(:user)
    @project_owner = create(:user)
    @project_owner.add_role(:project_owner, @project)
    @team_member = create(:user)
    @team_member.add_role(:team_member, @project)
  end

  # Helper to create user context for policy
  def user_context(user, project = nil)
    user ? ApplicationPolicy::UserContext.new(user, project) : nil
  end

  # Scope tests
  test 'scope for app owner includes all projects' do
    projects = ProjectPolicy::Scope.new(user_context(@app_owner), Project).resolve
    assert_includes projects, @project, 'App owner should have access to all projects'
  end

  test 'scope for admin includes all projects' do
    projects = ProjectPolicy::Scope.new(user_context(@admin), Project).resolve
    assert_includes projects, @project, 'Admin should have access to all projects'
  end

  test 'scope for project owner includes their projects' do
    projects = ProjectPolicy::Scope.new(user_context(@project_owner), Project).resolve
    assert_includes projects, @project, 'Project owner should have access to their own project'
  end

  test 'scope for team member includes their projects' do
    projects = ProjectPolicy::Scope.new(user_context(@team_member), Project).resolve
    assert_includes projects, @project, 'Team member should have access to projects they are part of'
  end

  test 'scope for regular user does not include projects they are not part of' do
    projects = ProjectPolicy::Scope.new(user_context(@regular_user), Project).resolve
    assert_not_includes projects, @project, 'Regular user should not see projects they are not part of'
  end

  test 'index? allows any authenticated user' do
    assert ProjectPolicy.new(user_context(@app_owner), Project).index?
    assert ProjectPolicy.new(user_context(@admin), Project).index?
    assert ProjectPolicy.new(user_context(@project_owner), Project).index?
    assert ProjectPolicy.new(user_context(@team_member), Project).index?
    assert ProjectPolicy.new(user_context(@regular_user), Project).index?
  end

  test 'index? denies unauthenticated users' do
    refute ProjectPolicy.new(nil, Project).index?
  end

  test 'show? allows any authenticated user with project access' do
    assert ProjectPolicy.new(user_context(@project_owner), @project).show?
    assert ProjectPolicy.new(user_context(@team_member), @project).show?
  end

  test 'show? denies unauthenticated users' do
    refute ProjectPolicy.new(nil, @project).show?
  end

  test 'scope with current_project only includes that project if user has access' do
    projects = ProjectPolicy::Scope.new(
      user_context(@project_owner, @project), 
      Project
    ).resolve
    assert_equal [@project], projects.to_a, 
      'Project owner should only see the current project when specified'
  end

  # Show tests
  test 'show allows anyone' do
    assert ProjectPolicy.new(
      user_context(@regular_user), 
      @project
    ).show?, 
      'Regular user should be able to view project'
    
    assert ProjectPolicy.new(
      user_context(@app_owner), 
      @project
    ).show?, 
      'App owner should be able to view project'
    
    assert ProjectPolicy.new(
      user_context(@admin), 
      @project
    ).show?, 
      'Admin should be able to view project'
    
    assert ProjectPolicy.new(
      user_context(@project_owner), 
      @project
    ).show?, 
      'Project owner should be able to view project'
    
    assert ProjectPolicy.new(
      user_context(@team_member), 
      @project
    ).show?, 
      'Team member should be able to view project'
  end

  # New tests
  test 'new only allows app owners' do
    assert ProjectPolicy.new(
      user_context(@app_owner), 
      Project
    ).new?, 'App owner should be able to access new project form'
    
    refute ProjectPolicy.new(
      user_context(@admin), 
      Project
    ).new?, 'Admin should not be able to access new project form'
    
    refute ProjectPolicy.new(
      user_context(@regular_user), 
      Project
    ).new?, 'Regular user should not be able to access new project form'
    
    refute ProjectPolicy.new(
      user_context(@project_owner), 
      Project
    ).new?, 'Project owner should not be able to access new project form'
    
    refute ProjectPolicy.new(
      user_context(nil), 
      Project
    ).new?, 'Guest should not be able to access new project form'
  end

  # Create tests
  test 'create only allows app owners' do
    assert ProjectPolicy.new(
      user_context(@app_owner), 
      Project
    ).create?, 'App owner should be able to create projects'
    
    refute ProjectPolicy.new(
      user_context(@admin), 
      Project
    ).create?, 'Admin should not be able to create projects'
    
    refute ProjectPolicy.new(
      user_context(@regular_user), 
      Project
    ).create?, 'Regular user should not be able to create projects'
    
    refute ProjectPolicy.new(
      user_context(@project_owner), 
      Project
    ).create?, 'Project owner should not be able to create projects'
    
    refute ProjectPolicy.new(
      user_context(nil), 
      Project
    ).create?, 'Guest should not be able to create projects'
  end

  # Edit/Update tests
  test 'edit and update allow app owner' do
    assert ProjectPolicy.new(
      user_context(@app_owner), 
      @project
    ).edit?, 'App owner should be able to edit project'
    
    assert ProjectPolicy.new(
      user_context(@app_owner), 
      @project
    ).update?, 'App owner should be able to update project'
  end

  test 'edit and update allow admin' do
    assert ProjectPolicy.new(
      user_context(@admin), 
      @project
    ).edit?, 'Admin should be able to edit project'
    
    assert ProjectPolicy.new(
      user_context(@admin), 
      @project
    ).update?, 'Admin should be able to update project'
  end

  test 'edit and update allow project owner' do
    assert ProjectPolicy.new(
      user_context(@project_owner), 
      @project
    ).edit?, 'Project owner should be able to edit project'
    
    assert ProjectPolicy.new(
      user_context(@project_owner), 
      @project
    ).update?, 'Project owner should be able to update project'
  end

  test 'edit and update do not allow others' do
    refute ProjectPolicy.new(
      user_context(@regular_user), 
      @project
    ).edit?, 'Regular user should not be able to edit project'
    
    refute ProjectPolicy.new(
      user_context(@regular_user), 
      @project
    ).update?, 'Regular user should not be able to update project'
    
    refute ProjectPolicy.new(
      user_context(@team_member), 
      @project
    ).edit?, 'Team member should not be able to edit project'
    
    refute ProjectPolicy.new(
      user_context(@team_member), 
      @project
    ).update?, 'Team member should not be able to update project'
    
    refute ProjectPolicy.new(
      user_context(nil), 
      @project
    ).edit?, 'Guest should not be able to edit project'
    
    refute ProjectPolicy.new(
      user_context(nil), 
      @project
    ).update?, 'Guest should not be able to update project'
  end

  # Destroy tests
  test 'destroy allows app owner and admin' do
    assert ProjectPolicy.new(
      user_context(@app_owner), 
      @project
    ).destroy?, 'App owner should be able to destroy project'
    
    assert ProjectPolicy.new(
      user_context(@admin), 
      @project
    ).destroy?, 'Admin should be able to destroy project'
  end

  test 'destroy denies project owner, team members and regular users' do
    refute ProjectPolicy.new(
      user_context(@project_owner), 
      @project
    ).destroy?, 'Project owner should not be able to destroy project'
    
    refute ProjectPolicy.new(
      user_context(@team_member), 
      @project
    ).destroy?, 'Team member should not be able to destroy project'
    
    refute ProjectPolicy.new(
      user_context(@regular_user), 
      @project
    ).destroy?, 'Regular user should not be able to destroy project'
  end

  test 'destroy denies unauthenticated users' do
    refute ProjectPolicy.new(
      user_context(nil), 
      @project
    ).destroy?, 'Guest should not be able to destroy project'
  end

  # Team management tests
  test 'manage_team_members allows app owner, admin and project owner' do
    assert ProjectPolicy.new(
      user_context(@app_owner), 
      @project
    ).manage_team_members?, 'App owner should be able to manage team members'
    
    assert ProjectPolicy.new(
      user_context(@admin), 
      @project
    ).manage_team_members?, 'Admin should be able to manage team members'
    
    assert ProjectPolicy.new(
      user_context(@project_owner), 
      @project
    ).manage_team_members?, 'Project owner should be able to manage team members'
  end

  test 'manage_team_members denies team members, regular users and guests' do
    refute ProjectPolicy.new(
      user_context(@team_member), 
      @project
    ).manage_team_members?, 'Team member should not be able to manage team members'
    
    refute ProjectPolicy.new(
      user_context(@regular_user), 
      @project
    ).manage_team_members?, 'Regular user should not be able to manage team members'
    
    refute ProjectPolicy.new(
      user_context(nil), 
      @project
    ).manage_team_members?, 'Guest should not be able to manage team members'
  end
end
