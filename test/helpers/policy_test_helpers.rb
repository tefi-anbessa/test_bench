module PolicyTestHelpers
  # creates core users with associated roles
  def setup_policy_test
    # Define two projects for in and out of scope tests
    @project = create(:project)
    @other_project = create(:project)

    # Define two disciplines for in and out of scope tests
    @discipline = create(:discipline, project: @project)
    @other_discipline = create(:discipline, project: @other_project)
    
    # Define symbolic users with roles
    @app_owner = create(:user)
    @app_owner.grant(:app_owner)
    @admin = create(:user)
    @admin.grant(:admin)
    @project_manager = create(:user)
    @project_manager.grant(:project_manager, @project)
    @team_member = create(:user)
    @team_member.grant(:team_member, @project)
    @regular_user = create(:user)
  end

  def policy_class
    @policy_class ||= "#{resource_class}Policy".constantize
  end

  # Helper to be overridden by subclasses
  def resource_class
    self.class.to_s.sub('PolicyTest', '').constantize
  end
  
  # returns user_context for given user and project
  def user_context(user, project)
    ApplicationPolicy::UserContext.new(user, project || @project)
  end
end
