module TestLoginHelpers
  # creates core users with associated roles
  def setup_projects_and_users
    # Define two projects for in and out of scope tests
    @project = create(:project)
    @other_project = create(:project)
    
    # Create a swatch for the app_theme and use it for tests.
    @swatch = create(:swatch, name: 'app_theme')

    # Define two disciplines for in and out of scope tests for models where discipline is used to define project
    if resource_class.respond_to?(:discipline)
      # Use the module's class discipline method
      name = resource_class.discipline
    else
      # Extract the module name and use that as the default discipline
      name = resource_class.name.split("::")[0..-2].join("")
    end
    @discipline = create(:discipline, name: name, label: name.upcase[0], project: @project, swatch: @swatch)
    @other_discipline = create(:discipline, name: name, label: name.upcase[0], project: @other_project, swatch: @swatch)
    
    # Define symbolic users with roles
    @app_owner = create(:user)
    @app_owner.grant(:app_owner)
    @admin = create(:user)
    @admin.grant(:admin)
    @project_manager = create(:user)
    @project_manager.grant(:project_manager, @project)
    @team_member = create(:user)
    @team_member.grant(:team_member, @project)
    @regular_user = create(:user) # No roles

    # Set up a user with edit permissions on this resource.
    @accredited_team_member = create(:user)
    @accredited_team_member.grant(:team_member, @project)
    # If resource_class.required_role is defined and not nil, grant this role. 
    if resource_class.respond_to?(:required_role) && resource_class.required_role.present?
      @accredited_team_member.grant(resource_class.required_role)
    end
  end

  # Helper methods

  # Signs in user and sets current project (order matters: must sign in first)
  def sign_in_and_set_project(user, project)
    sign_in user
    set_current_project(project)
  end

  def resource_class
   self.class.name.sub('ControllerTest', '').singularize.constantize
  end
  
  # returns user_context for given user and project
  def user_context(user, project)
    ApplicationPolicy::UserContext.new(user, project || @project)
  end
end
