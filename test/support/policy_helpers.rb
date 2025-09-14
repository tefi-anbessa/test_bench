module PolicyHelpers
  # creates core users with associated roles
  def setup_policy_test
    @app_owner = create(:user, :app_owner)
    @admin = create(:user, :admin)
    @project_manager = create(:user)
    @team_member = create(:user)
    @regular_user = create(:user)
    
    @project = create(:project)
    @project_manager.grant(:project_manager, @project)
    @team_member.grant(:team_member, @project)

    @other_project = create(:project)
  end
  
  # returns user_context for given user and project
  def user_context(user, project = nil)
    ApplicationPolicy::UserContext.new(user, project || @project)
  end
end
