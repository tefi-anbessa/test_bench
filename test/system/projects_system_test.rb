# frozen_string_literal: true
require "helpers/system_test_helpers"
require "application_system_test_case"

class ProjectsSystemTest < ApplicationSystemTestCase
  include Devise::Test::IntegrationHelpers
  include Warden::Test::Helpers
  include SystemTestHelpers
  
  setup do
    setup_projects_and_users
    setup_disciplines(name: 'Electrical', required_role: :designer)
    setup_accredited_users(:designer)
    setup_tags
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
      assert_selector "a", text: I18n.t('activerecord.models.project', count: 0)
      click_on I18n.t('activerecord.models.project', count: 0)  # Click on the projects index link
    end
    assert_current_path projects_path
    assert_text I18n.t("projects.index.header")
    assert page.title.include?(I18n.t("projects.index.title"))

    refute_selector "a[href='#{new_project_path}']" # team member cannot create new project

    assert_selector "input.search_field"
    assert_selector "a[href*='q%5Bs%5D=code']"
    assert_selector "a[href*='q%5Bs%5D=title']"
    assert_selector "a[href*='q%5Bs%5D=description']"
    
    assert_nav_button(:show, @project, icon_only: true)
    refute_selector "a[href='#{edit_project_path(@project)}']"  # team member cannot edit project
    refute_delete(project_path(@project)) # team member cannot delete project

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
      assert_selector "a", text: I18n.t('activerecord.models.project.other')
      click_on I18n.t('activerecord.models.project.other')  # Click on the project link
    end
    assert_current_path projects_path # project manager has 2 projects

    # only admin can create new project
    refute_selector "a[href='#{new_project_path}']" # project manager cannot create new project

    # search and header fields
    assert_selector "input.search_field"
    assert_selector "a.sort_link", text: I18n.t('activerecord.attributes.project.code') # alternative pattern
    assert_selector "a.sort_link", text: I18n.t('activerecord.attributes.project.title')
    assert_selector "a.sort_link", text: I18n.t('activerecord.attributes.project.description')
    assert_nav_button(:show, @project)
    refute_selector "a[href='#{project_path(@other_project)}']" # Only shows projects where user has a role
    assert_nav_button(:edit, @project, path: edit_project_path(@project))
    refute_delete(project_path(@project))  # project manager cannot delete project
  end

  test "admin view the projects index" do
    sign_in @admin
    # Mock current_project for this test
    ApplicationController.any_instance.stubs(:current_project).returns(@project)
    visit projects_path
    assert_current_path projects_path

    assert_nav_button(:new, path: new_project_path) # admin can create new project

    assert_nav_button(:show, @project, icon_only: true)# Admin can see all projects
    assert_nav_button(:edit, @project, path: edit_project_path(@project), icon_only: true)# Admin can edit all projects
    refute_delete(project_path(@project)) # only app owner can delete projects
  end

  test "app_owner viewing the projects index" do
    sign_in @app_owner
    # Mock current_project for this test
    ApplicationController.any_instance.stubs(:current_project).returns(@project)
    visit projects_path
    assert_current_path projects_path

    assert_nav_button(:new, path: new_project_path) # app_owner can create new project

    assert_nav_button(:show, @project, icon_only: true)# app_owner can see all projects
    assert_nav_button(:edit, @project, path: edit_project_path(@project), icon_only: true)# app_owner can edit all projects
    assert_nav_button(:delete, @project, icon_only: true) # app_owner can delete projects
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
      click_on [I18n.t('actions.show'), @project.code].join(" ") # Click on the project link
    end
    assert_current_path project_path(@project)

    assert_text I18n.t("projects.show.header", label: @project.code)
    assert page.title.include?(I18n.t("projects.show.title"))

    # Header bar navigation links
    assert_nav_button(:index, path: projects_path) # Link back to projects index
    assert_nav_button_disabled(:previous)
    assert_nav_button_disabled(:next)
    refute_selector "a[href='#{edit_project_path(@project)}']" # Link to edit project
    refute_selector "a[href='#{project_path(@project)}'][data-turbo-method='delete']" # delete icon

    assert_text I18n.t('activerecord.attributes.project.description')
    assert_text @project.description

    # Project scoped tag and document links 
    assert_selector "a[href='#{project_tags_path(@project)}']"
    assert_selector "a[href='#{project_documents_path(@project)}']"
    refute_selector "a[href='#{project_doc_types_path(@project)}']"

    # Discipline links 
    assert_selector "h5", text: I18n.t('disciplines.index.header', scope_text: @project.label)
    @project.disciplines.each do |discipline|
      assert_selector "a[href='#{discipline_path(discipline)}']", text: "#{discipline.code}: #{discipline.name}"
      # assert_selector "a[href='#{discipline_path(discipline)}'], [aria-label=I18n.t('actions.show')]"
      assert_selector "a[href='#{discipline_documents_path(discipline)}']"
    end

    # Users section
    assert_selector "h5", text: I18n.t('users.users.header', scope_text: @project.long_label)
    %i[project_manager project_admin team_member].each do |user_role|
      user = instance_variable_get("@#{user_role}")
      assert_text user.name
      assert_text user.email
      assert_text I18n.t("rolify.names.#{user_role}")
      assert_selector "a[href='#{user_path(user)}']", text: I18n.t('actions.show')
    end
    
    refute_text @app_owner.name
    refute_text @app_owner.email
    refute_text I18n.t("rolify.names.app_owner")
    refute_selector "a[href='#{user_path(@app_owner)}']", text: I18n.t('actions.show')
    refute_selector "a[href='#{user_path(@regular_user)}']", text: I18n.t('actions.show')
  end

  test "document controller show project" do
    @team_member.grant(:document_controller, @project)
    sign_in @team_member
    # Mock current_project for this test
    ApplicationController.any_instance.stubs(:current_project).returns(@project)
    visit project_path(@project)
    assert_current_path project_path(@project)

    assert_nav_button(:index, path: projects_path) # Link back to projects index

    refute_selector "a[href='#{edit_project_path(@project)}']" # Link to edit project
    refute_delete(project_path(@project))

    # Swatch drop down

    # Project scoped tag and document links 
    assert_selector "a[href='#{project_tags_path(@project)}']"
    assert_selector "a[href='#{project_documents_path(@project)}']"
    assert_selector "a[href='#{project_doc_types_path(@project)}']"
  end

  test "project manager show project" do
    sign_in @project_manager
    # Mock current_project for this test
    ApplicationController.any_instance.stubs(:current_project).returns(@project)
    visit project_path(@project)
    assert_current_path project_path(@project)

    assert_nav_button(:index, path: projects_path) # Link back to projects index
    assert_nav_button(:edit, @project, path: edit_project_path(@project)) # Project manager can edit project
    refute_delete(project_path(@project)) # Project manager cannot delete project
  end

  test "app owner show project" do
    sign_in @app_owner
    visit project_path(@project)
    assert_current_path project_path(@project)

    assert_nav_button(:index, path: projects_path) # Link back to projects index
    assert_nav_button(:edit, @project, path: edit_project_path(@project)) # App owner can edit project
    assert_nav_button(:delete, @project, path: project_path(@project)) # App owner can delete project
  end

  test "app_owner create new project" do
    sign_in @app_owner
    visit projects_path
    click_link(href: new_project_path)
    assert_current_path new_project_path
    assert_text I18n.t("projects.new.header")
    assert page.title.include?(I18n.t("projects.new.title"))

    assert_selector "input[name='project[code]']"
    assert_selector "input[name='project[title]']"
    assert_selector "textarea[name='project[description]']"
    assert_selector "select[name='project[swatch_id]']"
    assert_selector "button[type='submit']"
    assert_selector "a.btn.btn-warning", text: I18n.t('actions.discard')

    # Complete the form
    fill_in "project_code", with: "TT"
    fill_in "project_title", with: "New Project"
    fill_in "project_description", with: "This is a test project"
    select "app_theme", from: "project_swatch_id"

    # Save the new project
    click_button I18n.t('actions.create')
    sleep 0.1  # Give database time to commit
    new_project = Project.find_by(code: "TT")
    assert_current_path project_path(new_project) 
    assert_text "New Project"
    assert_text I18n.t("flash.create.notice", resource_name: I18n.t("activerecord.models.project", count: 1))
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
    assert_selector "a.btn.btn-warning", text: I18n.t('actions.discard')

    # Complete the form
    fill_in "project_title", with: "Modified Test Project"
    fill_in "project_description", with: "This is a modified test project"
    click_button I18n.t('actions.update')

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
    click_delete(project_path(@project))
    assert_current_path projects_path
    refute_selector "a[href='#{project_path(@project)}']"
    assert_text I18n.t("flash.destroy.notice", resource_name: I18n.t("activerecord.models.project", count: 1))
  end

  test "app owner destroy project from the show view" do
    sign_in @app_owner
    visit project_path(@project)
     # Find the actual delete link and inspect its href
    click_delete(project_path(@project))
    assert_current_path projects_path
    refute_selector "a[href='#{project_path(@project)}']"
    assert_text I18n.t("flash.destroy.notice", resource_name: I18n.t("activerecord.models.project", count: 1))
  end

end
