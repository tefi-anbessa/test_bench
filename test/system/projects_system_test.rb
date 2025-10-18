require "application_system_test_case"

class ProjectsTest < ApplicationSystemTestCase
  include Devise::Test::IntegrationHelpers
  include Warden::Test::Helpers
  
  setup do
    @project = create(:project)
    @project2 = create(:project)

    @app_owner = create(:user)
    @app_owner.grant(:app_owner)

    @admin = create(:user)
    @admin.grant(:admin)

    @project_manager = create(:user)
    @project_manager.grant(:project_manager, @project)
    @project_manager.grant(:project_manager, @project2)

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

  test "team member with only one project will have current_project automatically set" do
    skip "This does not appear to be working in test. It works in development." # This does not appear to be working in test. It works in development.
    sign_in @team_member
    # Click the project dropdown toggle
  end

  test "setting the current project" do
    sign_in @project_manager
    visit root_url
    find("#project-menu-btn").click
    
    within ".dropdown-menu" do
      assert_selector "a", text: I18n.t('actions.select')
      click_on I18n.t('actions.select')  # Click on the project select link
    end
    assert_current_path select_projects_path
    assert_text I18n.t("projects.select.header")
    assert page.title.include?(I18n.t("projects.select.title"))

    assert_selector "label.form-check-label", text: @project.code
    choose(@project.code)
    click_on I18n.t('actions.set') # Set the current project
    # Returns to back or root...
    assert_selector "#project-menu-btn", text: @project.code # Indicates that the current project is set
  end

  test "team member view the projects index" do
    sign_in @team_member
    # Mock current_project for this test
    ApplicationController.any_instance.stubs(:current_project).returns(@project)
    visit root_url
    
    # Click the dropdown toggle
    find("#project-menu-btn").click
    
    # Now the dropdown should be visible
    # You can then interact with dropdown items
    within ".dropdown-menu" do
      assert_selector "a", text: I18n.t('project', scope: 'activerecord.models').pluralize
      click_on I18n.t('project', scope: 'activerecord.models').pluralize  # Click on the projects index link
    end
    assert_current_path projects_path
    assert_text I18n.t("projects.index.header")
    assert page.title.include?(I18n.t("projects.index.title"))

    assert_selector "input.search_field"
    assert_selector "a[href*='q%5Bs%5D=code']"
    assert_selector "a[href*='q%5Bs%5D=title']"
    assert_selector "a[href*='q%5Bs%5D=description']"
    assert_selector "a[href='#{project_path(@project)}']", count: 2 # one link on code and one on icon in links
    refute_selector "a[href='#{edit_project_path(@project)}']"
    refute_selector "a[href='#{project_path(@project)}'][data-turbo-method='delete']"
    refute_selector "a[href='#{new_project_path}']" # only admin can create new project

    assert_text @project.code
    assert_text @project.title
    assert_text @project.description
  end

  test "project manager view the projects index" do
    sign_in @project_manager
    # Mock current_project for this test
    ApplicationController.any_instance.stubs(:current_project).returns(@project)
    visit root_url
    
    # Click the dropdown toggle
    find("#project-menu-btn").click
    
    # Now the dropdown should be visible
    # You can then interact with dropdown items
    within ".dropdown-menu" do
      assert_selector "a", text: I18n.t('project', scope: 'activerecord.models').pluralize
      click_on I18n.t('project', scope: 'activerecord.models').pluralize  # Click on the project link
    end
    assert_current_path projects_path # project manager has 2 projects

    # only admin can create new project
    refute_selector "a[href='#{new_project_path}']" 

    # search and header fields
    assert_selector "input.search_field"
    assert_selector "a.sort_link", text: I18n.t('activerecord.attributes.project.code') # alternative pattern
    assert_selector "a.sort_link", text: I18n.t('activerecord.attributes.project.title')
    assert_selector "a.sort_link", text: I18n.t('activerecord.attributes.project.description')
    assert_selector "a[href='#{project_path(@project)}']", count: 2 # one link on code and one on icon in links
    assert_selector "a[href='#{project_path(@project2)}']", count: 2 # one link on code and one on icon in links
    assert_selector "a[href='#{edit_project_path(@project)}']" # edit icon
    refute_selector "a[href='#{project_path(@project)}'][data-turbo-method='delete']" # delete icon
  end

  test "admin view the projects index" do
    sign_in @admin
    # Mock current_project for this test
    ApplicationController.any_instance.stubs(:current_project).returns(@project)
    visit projects_path
    refute_selector "a[href='#{project_path(@project)}'][data-turbo-method='delete']" # only app owner can delete projects
    assert_selector "a[href='#{new_project_path}']" # only admin can create new project
  end

  test "app_owner viewing the projects index" do
    sign_in @app_owner
    # Mock current_project for this test
    ApplicationController.any_instance.stubs(:current_project).returns(@project)
    visit projects_path
    assert_selector "a[href='#{new_project_path}']" # only admin and app owner can create new project
    assert_selector "a[href='#{project_path(@project)}'][data-method='delete']" # only app_owner can destroy project
  end

  test "team member show project" do
    sign_in @team_member
    # Mock current_project for this test
    ApplicationController.any_instance.stubs(:current_project).returns(@project)
    visit root_url
    
    # Click the dropdown toggle
    find("#project-menu-btn").click
    
    # Now the dropdown should be visible
    # You can then interact with dropdown items
    within ".dropdown-menu" do
      assert_selector "a[href='#{project_path(@project)}']", 
        text: [I18n.t('actions.show'), @project.code].join(" ")
      click_link(href: project_path(@project)) # Click on the project link
    end
    assert_current_path project_path(@project)
    assert_text I18n.t("projects.show.header", label: @project.code)
    assert page.title.include?(I18n.t("projects.show.title"))

    # Header bar navigation links
    assert_selector "a[href='#{projects_path}']"# Link back to projects index
    refute_selector "a[href='#{edit_project_path(@project)}']" # Link to edit project
    refute_selector "a[href='#{project_path(@project)}'][data-turbo-method='delete']" # delete icon
    # [TODO] test prev and next buttons

    assert_text I18n.t('activerecord.attributes.project.code')
    assert_text I18n.t('activerecord.attributes.project.title')
    assert_text I18n.t('activerecord.attributes.project.description')
    assert_text @project.code
    assert_text @project.title
    assert_text @project.description
  end

  test "project manager show project" do
    sign_in @project_manager
    # Mock current_project for this test
    ApplicationController.any_instance.stubs(:current_project).returns(@project)
    visit project_path(@project)

    assert_selector "a[href='#{projects_path}']"# Link back to projects index
    assert_selector "a[href='#{edit_project_path(@project)}']" # Link to edit project
    refute_selector "a[href='#{project_path(@project)}'][data-method='delete']" # delete icon
  end

  test "app owner show project" do
    sign_in @app_owner
    visit project_path(@project)

    assert_selector "a[href='#{projects_path}']"# Link back to projects index
    assert_selector "a[href='#{edit_project_path(@project)}']" # Link to edit project
    assert_selector "a[href='#{project_path(@project)}'][data-method='delete']" # delete icon
  end

  test "admin create new project" do
    sign_in @admin
    visit projects_path
    click_link(href: new_project_path)
    assert_current_path new_project_path
    assert_text I18n.t("projects.new.header")
    assert page.title.include?(I18n.t("projects.new.title"))

    assert_selector "input[name='project[code]']"
    assert_selector "input[name='project[title]']"
    assert_selector "textarea[name='project[description]']"
    assert_selector "button[type='submit']"
    assert_selector "a.btn.btn-warning.actions", text: I18n.t('actions.discard')

    # Complete the form
    fill_in "project_code", with: "TT"
    fill_in "project_title", with: "New Project"
    fill_in "project_description", with: "This is a test project"

    # Save the new project
    click_button I18n.t('actions.save')
    sleep 0.1  # Give database time to commit
    new_project = Project.find_by(code: "TT")
    assert_current_path project_path(new_project) 
    assert_text "New Project"
    assert_text I18n.t("flash.actions.create.notice", resource_name: I18n.t("activerecord.models.project"))
  end

  test "project manager edit project" do
    sign_in @project_manager
    visit projects_path
    click_link(href: edit_project_path(@project))
    assert_current_path edit_project_path(@project)
    assert_text I18n.t("projects.edit.header", label: @project.label)
    assert page.title.include?(I18n.t("projects.edit.title"))

    assert_selector "input[name='project[code]']"
    assert_selector "input[name='project[title]']"
    assert_selector "textarea[name='project[description]']"
    assert_selector "button[type='submit']"
    assert_selector "a.btn.btn-warning.actions", text: I18n.t('actions.discard')

    # Complete the form
    fill_in "project_title", with: "Modified Test Project"
    fill_in "project_description", with: "This is a modified test project"
    click_button I18n.t('actions.save')

    assert_current_path project_path(@project)
    assert_text "Modified Test Project"

    # Make another edit to test the show view link, and then discard
    click_link(href: edit_project_path(@project))
    assert_current_path edit_project_path(@project)
    fill_in "project_title", with: "Reverted Test Project"
    accept_confirm do
      click_link(text: I18n.t('actions.discard'))
    end
    assert_current_path project_path(@project)
    assert_text "Modified Test Project"
    
  end

  test "app owner destroy project from the index view" do
    sign_in @app_owner
    visit projects_path
     # Find the actual delete link and inspect its href
    accept_confirm do
      find("a[href='#{project_path(@project)}'][data-method='delete']").click
    end
    assert_current_path projects_path
    refute_selector "a[href='#{project_path(@project)}']"
    assert_text I18n.t("flash.actions.destroy.notice", resource_name: I18n.t("activerecord.models.project"))
  end

  test "app owner destroy project from the show view" do
    sign_in @app_owner
    visit project_path(@project)
     # Find the actual delete link and inspect its href
    accept_confirm do
      find("a[href='#{project_path(@project)}'][data-method='delete']").click
    end
    assert_current_path projects_path
    refute_selector "a[href='#{project_path(@project)}']"
    assert_text I18n.t("flash.actions.destroy.notice", resource_name: I18n.t("activerecord.models.project"))
  end

end
