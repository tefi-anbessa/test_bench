# frozen_string_literal: true
require "application_system_test_case"
require "helpers/system_test_helpers"

class DisciplineSystemTest < ApplicationSystemTestCase
  include Devise::Test::IntegrationHelpers
  include Warden::Test::Helpers
  include SystemTestHelpers
  
  setup do
    setup_projects_and_users
    setup_disciplines(name: 'Electrical', required_role: :designer)
    setup_accredited_users(:designer)
    setup_tags
    model_specific_setup
  end

  def model_specific_setup
    @discipline.update(sort_order: 1)
    @resource = @discipline
    @resource2 = @project.disciplines.find_by(name: "Mechanical")
    @resource2.update(sort_order: 2)

    @dt = create(:doc_type, discipline: @discipline)
    @document = create(:document, discipline: @discipline, doc_type: @dt)
  end

  def test_setup_is_valid
    assert @project.valid?
    assert @project.persisted?
    assert @discipline.valid?
    assert @discipline.persisted?
    assert @admin.valid?
    assert @admin.persisted?
    assert @project_manager.valid?
    assert @project_manager.persisted?
    assert @team_member.valid?
    assert @team_member.persisted?
    assert @regular_user.valid?
    assert @regular_user.persisted?
    assert @accredited_user.valid?
    assert @accredited_user.persisted?
    assert @tag.valid?
    assert @tag.persisted?
    assert @tag2.valid?
    assert @tag2.persisted?
    assert @resource.valid?
    assert @resource.persisted?
    assert @resource2.valid?
    assert @resource2.persisted?
    assert (@resource2.sort_order > @resource.sort_order)
  end

  test "team member navigate from project show to discipline show" do
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

    # Discipline links 
    assert_selector "h5", text: I18n.t('disciplines.index.header', scope_text: @project.label)
    @project.disciplines.each do |disc|
      next unless disc.persisted?
      name = I18n.exists?("discipline.name.#{disc.name}") ? I18n.t("discipline.name.#{disc.name}") : disc.name
      text = [disc.code, name].join(": ")
      assert_selector "a[href='#{discipline_path(disc)}']", text: text # Link to show discipline
      assert_nav_button(:show, disc, icon_only: true)
      assert_selector "a[href='#{discipline_tags_path(disc)}']"
      assert_selector "a[href='#{discipline_documents_path(disc)}']"

      find("#discipline-#{disc.id}").click
      assert_current_path discipline_path(disc)
      # Header
      assert_selector "#discipline-header", text: I18n.t('disciplines.show.header', label: I18n.t("discipline.name.#{disc.name}"))
      assert page.title.include?(I18n.t("disciplines.show.title"))
      # Header links 
      assert_nav_button(:show_project, disc.project)
      assert_nav_button(:index, path: project_disciplines_path(disc.project))
      refute_selector "a[href='#{edit_discipline_path(disc)}']", text: I18n.t('actions.edit') # Edit discipline link
      refute_delete(discipline_path(disc)) # Delete discipline link
      refute_selector "a[href='#{new_project_discipline_path(@project)}']", text: I18n.t('actions.new') # New discipline link
      # Discipline attribute labels
      assert_text I18n.t('activerecord.attributes.discipline.notes')
      assert_text I18n.t('activerecord.attributes.discipline.required_role')
      assert_text I18n.t('activerecord.attributes.discipline.catalog_required_role')
      assert_text I18n.t('activerecord.attributes.discipline.prefix_schema')
      refute_text I18n.t('activerecord.models.swatch', count: 1)
      # Discipline attributes
      assert_text disc.notes if disc.notes.present?
      assert_text disc.required_role if disc.required_role.present?
      assert_text disc.catalog_required_role if disc.catalog_required_role.present?
      assert_text disc.prefix_schema['name'] # [TODO: Write a test for collapsible on attribute rather than association.]
      refute_text disc.swatch&.name if disc.swatch.present?
      # Discipline links for tags and documents
      assert_selector "a[href='#{discipline_tags_path(disc)}']", 
        text: I18n.t('activerecord.models.tag', count: disc.tags.count)
      find("a[href='#{discipline_tags_path(disc)}']").click
      assert_current_path discipline_tags_path(disc)
      find("a[href='#{discipline_path(disc)}']").click
      assert_current_path discipline_path(disc)
      assert_selector "a[href='#{discipline_documents_path(disc)}']", 
        text: I18n.t('activerecord.models.document', count: disc.documents.count)
      find("a[href='#{discipline_documents_path(disc)}']").click
      assert_current_path discipline_documents_path(disc)
      find("a[href='#{discipline_path(disc)}']").click
      assert_current_path discipline_path(disc)

      # Model links
      # Mimic the controller setup_dashboard method
      models = ActiveRecord::Base.descendants
        .select { |model| model.module_parent_name == disc.name && model.model_name.human != "Base" }
        .sort_by(&:model_name)
      @model_links = models.map { |m| [m.model_name.human.pluralize, m.model_name.route_key] }
      @model_links.each do |link|
        assert_selector "a[href='#{send("discipline_#{link[1]}_path", disc)}']", text: link[0]
        find("a[href='#{send("discipline_#{link[1]}_path", disc)}']", text: link[0]).click
        assert_current_path send("discipline_#{link[1]}_path", disc)
        find("a[href='#{discipline_path(disc)}']", text: disc.name).click
        assert_current_path discipline_path(disc)
      end
      # Users
      assert_selector "h5", text: I18n.t('users.users.header', scope_text: disc.long_label)
      if disc.roles.any?
        disc.roles.each do |role|
          role.users.each do |user|
            assert_nav_button(:show, user, icon_only: true)
            assert_text user.name
            assert_text user.email
            assert_text role.name
          end
        end
      else
        assert_text I18n.t('users.users.no_users', scope_text: disc.long_label)
      end
      # Return to project show view
      find("a[href='#{project_path(@project)}']", text: @project.code).click
    end
  end

  def test_team_member_test_next_and_previous_buttons
    sign_in @team_member
    # Mock current_project for this test
    ApplicationController.any_instance.stubs(:current_project).returns(@project)
    visit resource_path(@resource)
    assert_current_path resource_path(@resource)
    
    # Header bar should include disabled previous button and enabled next button
    assert_nav_button_disabled(:previous)
    assert_nav_button(:next, @resource2)
    
    click_link I18n.t('actions.next')
    assert_current_path resource_path(@resource2)

    # Header bar should include enabled previous button and disabled next button
    assert_nav_button(:previous, @resource)
    # There are more disciplines, so next button should be enabled
    # assert_nav_button_disabled(:next)

    click_link I18n.t('actions.previous')
    assert_current_path resource_path(@resource)
  end

  test "project manager show discipline" do
    sign_in @project_manager
    # Mock current_project for this test
    ApplicationController.any_instance.stubs(:current_project).returns(@project)
    @project.disciplines.each do |disc|
      next unless disc.persisted?
      visit discipline_path(disc)
      # Header links 
      assert_nav_button(:show_project, disc.project)
      assert_nav_button(:index, path: project_disciplines_path(disc.project))
      assert_nav_button(:edit, disc, path: edit_discipline_path(disc)) # Edit discipline link
      refute_delete(discipline_path(disc)) # Delete discipline link
      refute_selector "a[href='#{new_project_discipline_path(@project)}']", text: I18n.t('actions.new') # New discipline link

      # Field labels
      assert_text I18n.t('activerecord.models.swatch', count: 1) if disc.swatch.present?

      # Fields
      assert_text disc.swatch&.name if disc.swatch.present?
    end
  end

  test "document controller can see doc_type links" do
    # Make a document controller user for this test
    @team_member.grant(:document_controller, @project)
    sign_in @team_member
    # Mock current_project for this test
    ApplicationController.any_instance.stubs(:current_project).returns(@project)
    @project.disciplines.each do |disc|
      # puts "BEFORE: #{disc.inspect} | persisted?: #{disc.persisted?}"
      next unless disc.persisted?
      visit discipline_path(disc)
      # Doc_types links
      assert_selector "a[href='#{discipline_doc_types_path(disc)}']", 
        text: I18n.t('activerecord.models.doc_type', count: disc.doc_types.count)
      find("a[href='#{discipline_doc_types_path(disc)}']").click
      assert_current_path discipline_doc_types_path(disc)
      find("a[href='#{discipline_path(disc)}']", text: disc.name).click
      assert_current_path discipline_path(disc)
    end
  end

  test "project admin show discipline" do
    sign_in @project_admin
    # Mock current_project for this test
    ApplicationController.any_instance.stubs(:current_project).returns(@project)
    @project.disciplines.each do |disc|
      next unless disc.persisted?
      visit discipline_path(disc)
      # Header links
      assert_nav_button(:show_project, disc.project)
      assert_nav_button(:index, path: project_disciplines_path(disc.project))
      assert_nav_button(:edit, disc, path: edit_discipline_path(disc)) # Edit discipline link
      assert_nav_button(:delete, disc) # Delete discipline link
      assert_nav_button(:new, @project.disciplines.build, path: new_project_discipline_path(@project)) # New discipline link
    end
  end

  test "project admin create new discipline" do
    sign_in @project_admin
    # Mock current_project for this test
    ApplicationController.any_instance.stubs(:current_project).returns(@project)
    visit project_disciplines_path(@project)
    click_link(href: new_project_discipline_path(@project))
    assert_current_path new_project_discipline_path(@project)
    assert_text I18n.t("disciplines.new.header")
    assert page.title.include?(I18n.t("disciplines.new.title"))

    discipline_form_field_assertions

    # Complete the form
    fill_in "discipline_name", with: "Alternative"
    fill_in "discipline_code", with: "ALT"
    select "default", from: "discipline_schema_key"
    select "Designer", from: "discipline_required_role"
    select "app_theme", from: "discipline_swatch_id"

    # Save the new project
    click_button I18n.t('actions.create')
    sleep 0.1  # Give database time to commit
    new_discipline = @project.disciplines.find_by(code: "ALT")
    assert_not_nil new_discipline
    assert_current_path discipline_path(new_discipline) 
    assert_text "Alternative"
    assert_text I18n.t("flash.create.notice", resource_name: I18n.t("activerecord.models.discipline", count: 1))
  end

  test "project manager edit discipline" do
    sign_in @project_manager
    # Mock current_project for this test
    ApplicationController.any_instance.stubs(:current_project).returns(@project)
    visit discipline_path(@discipline)
    click_link(href: edit_discipline_path(@discipline))
    assert_current_path edit_discipline_path(@discipline)
    assert_text I18n.t("disciplines.edit.header", label: @discipline.code)
    assert page.title.include?(I18n.t("disciplines.edit.title"))

    discipline_form_field_assertions

    # Complete the form
    fill_in "discipline_name", with: "New Alternative"
    click_button I18n.t('actions.update')

    assert_current_path discipline_path(@discipline)
    assert_text "New Alternative"
    @discipline.reload
    assert_equal "New Alternative", @discipline.name

    # Make another edit to test the show view link, and then discard
    click_link(href: edit_discipline_path(@discipline))
    assert_current_path edit_discipline_path(@discipline)
    fill_in "discipline_name", with: "Reverted Test Project"
    accept_confirm do
      click_link(text: I18n.t('actions.discard'))
    end
    assert_current_path discipline_path(@discipline)
    assert_text "New Alternative"
    @discipline.reload
    assert_equal "New Alternative", @discipline.name
  end

  test "project admin destroy discipline from the index view" do
    sign_in @project_admin
    # Mock current_project for this test
    ApplicationController.any_instance.stubs(:current_project).returns(@project)
    visit project_disciplines_path(@project)
    click_delete(discipline_path(@discipline))
    assert_current_path project_disciplines_path(@project)
    refute_selector "a[href='#{discipline_path(@discipline)}']"
    assert_text I18n.t("flash.destroy.notice", resource_name: I18n.t("activerecord.models.discipline", count: 1))
  end

  test "app owner destroy discipline from the show view" do
    sign_in @app_owner
    # Mock current_project for this test
    ApplicationController.any_instance.stubs(:current_project).returns(@project)
    visit discipline_path(@discipline)
    click_delete(discipline_path(@discipline))
    assert_current_path project_disciplines_path(@project)
    refute_selector "a[href='#{discipline_path(@discipline)}']"
    assert_text I18n.t("flash.destroy.notice", resource_name: I18n.t("activerecord.models.discipline", count: 1))
  end

  test "admin destroy discipline from the project show view" do
    sign_in @admin
    # Mock current_project for this test
    ApplicationController.any_instance.stubs(:current_project).returns(@project)
    visit project_path(@project)
    click_delete(discipline_path(@discipline))
    assert_current_path project_disciplines_path(@project)
    refute_selector "a[href='#{discipline_path(@discipline)}']"
    assert_text I18n.t("flash.destroy.notice", resource_name: I18n.t("activerecord.models.discipline", count: 1))
  end

  private

    def discipline_form_field_assertions
      assert_field "discipline[code]"
      assert_field "discipline[name]"
      assert_selector "select[name='discipline[schema_key]']"
      assert_selector "select[name='discipline[swatch_id]']"
      assert_selector "select[name='discipline[required_role]']"
      assert_selector "button[type='submit']"
      assert_selector "a.btn.btn-warning", text: I18n.t('actions.discard')
    end

end
