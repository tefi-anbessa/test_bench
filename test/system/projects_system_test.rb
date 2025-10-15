require "application_system_test_case"

class ProjectsTest < ApplicationSystemTestCase
  include Devise::Test::IntegrationHelpers
  include Warden::Test::Helpers
  
  setup do
    @project = create(:project)

    @app_owner = create(:user)
    @app_owner.grant(:app_owner)

    @admin = create(:user)
    @admin.grant(:admin)

    @project_manager = create(:user)
    @project_manager.grant(:project_manager, @project)

    @team_member = create(:user)
    @team_member.grant(:team_member, @project)

    @regular_user = create(:user)

    # Set the current project for all tests that need it
    set_current_project(@project) if defined?(set_current_project)
  end

  test "unauthenticated users should not see projects link" do
    visit root_url
    refute_selector "a[href='projects_url']"
  end


end
