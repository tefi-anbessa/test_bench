module PolicyHelpers
  def setup_policy_test
    @app_owner = create(:user, :app_owner)
    @admin = create(:user, :admin)
    @project_owner = create(:user)
    @team_member = create(:user)
    @regular_user = create(:user)
    
    @project = create(:project)
    @project_owner.add_role(:project_owner, @project)
    @team_member.add_role(:team_member, @project)
  end
  
  def user_context(user, project = nil)
    ApplicationPolicy::UserContext.new(user, project || @project)
  end
end
