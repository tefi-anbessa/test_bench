# frozen_string_literal: true
require "test_helper"
require "helpers/test_setup_helpers"
require "helpers/system_test_helpers"
module DisciplineResourceSystemTests
  extend ActiveSupport::Concern
  include TestSetupHelpers
  include SystemTestHelpers

  def setup_common_data
    setup_projects_and_users
    setup_disciplines(name: "Electrical", required_role: :designer)
    setup_accredited_users(:designer)
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
    assert @resource.valid?
    assert @resource.persisted?
    assert @resource2.valid?
    assert @resource2.persisted?
  end

  def test_team_member_navigating_to_project_resource_index
    sign_in @team_member
    # Mock current_project for this test
    ApplicationController.any_instance.stubs(:current_project).returns(@project)
    visit project_path(@project)
    assert_current_path project_path(@project)
    click_link(href: project_resource_index_path(@project))
    assert_current_path project_resource_index_path(@project)
    
    project_resource_index_assertions
    # Variable assertions
    refute_selector "a[href='#{edit_resource_path(@resource)}']" # team member cannot edit resource
    refute_selector "a[href='#{resource_path(@resource)}'][data-method='delete']" # team member cannot delete resource
  end

  def test_team_member_navigating_to_discipline_resource_index
    sign_in @team_member
    # Mock current_project for this test
    ApplicationController.any_instance.stubs(:current_project).returns(@project)
    visit project_path(@project)
    assert_current_path project_path(@project)
    click_link(href: discipline_resource_index_path(@discipline))
    assert_current_path discipline_resource_index_path(@discipline)
    
    discipline_resource_index_assertions
    # Variable assertions
    refute_selector "a[href='#{new_discipline_resource_path(@discipline)}']" # Link to new resource
    refute_selector "a[href='#{edit_resource_path(@resource)}']" # team member cannot edit resource
    refute_delete(resource_path(@resource)) # team member cannot delete resource
  end

  def test_accredited_user_view_index
    sign_in @accredited_user
    # Mock current_project for this test
    ApplicationController.any_instance.stubs(:current_project).returns(@project)
    visit discipline_resource_index_path(@discipline)
    assert_current_path discipline_resource_index_path(@discipline)

    discipline_resource_index_assertions
    # Variable assertions
    assert_nav_button(:new, path: new_discipline_resource_path(@discipline)) # Link to new resource
    assert_nav_button(:edit, @resource, path: edit_resource_path(@resource)) # accredited team member can edit resource
    refute_delete(resource_path(@resource)) # accredited team member cannot delete resource
  end

  def test_admin_view_index
    sign_in @project_admin
    # Mock current_project for this test
    ApplicationController.any_instance.stubs(:current_project).returns(@project)
    visit discipline_resource_index_path(@discipline)
    assert_current_path discipline_resource_index_path(@discipline)

    discipline_resource_index_assertions
    # Variable assertions
    assert_nav_button(:new, path: new_discipline_resource_path(@discipline)) # Link to new resource
    assert_nav_button(:edit, @resource, path: edit_resource_path(@resource)) # admin can edit resource
    assert_nav_button(:delete, @resource, icon_only: true) # admin can delete resource
  end

  def test_team_member_navigating_to_resource_show_view
    sign_in @team_member
    # Mock current_project for this test
    ApplicationController.any_instance.stubs(:current_project).returns(@project)
    visit project_path(@project)
    assert_current_path project_path(@project)
    click_link(href: project_resource_index_path(@project))
    assert_current_path project_resource_index_path(@project)
    
    click_link href: resource_path(@resource)
    assert_current_path resource_path(@resource)

    show_assertions
    # Include discipline in @show_associations

    # Variable assertions
    refute_selector "a[href='#{edit_resource_path(@resource)}']"
    refute_delete(resource_path(@resource)) # team member cannot delete resource
    refute_selector "a[href='#{new_discipline_resource_path(@discipline)}']"
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
    assert_nav_button_disabled(:next)

    click_link I18n.t('actions.previous')
    assert_current_path resource_path(@resource)
  end

  def test_accredited_user_resource_show_view
    sign_in @accredited_user
    # Mock current_project for this test
    ApplicationController.any_instance.stubs(:current_project).returns(@project)
    visit resource_path(@resource)
    assert_current_path resource_path(@resource)

    show_assertions
    # Variable assertions
    assert_nav_button(:edit, @resource, path: edit_resource_path(@resource))
    refute_delete(resource_path(@resource))
    assert_nav_button(:new, path: new_discipline_resource_path(@discipline))
  end

  def test_admin_resource_show_view
    sign_in @project_admin
    # Mock current_project for this test
    ApplicationController.any_instance.stubs(:current_project).returns(@project)
    visit resource_path(@resource)
    assert_current_path resource_path(@resource)

    show_assertions
    # Variable assertions
    assert_nav_button(:edit, @resource, path: edit_resource_path(@resource))
    assert_nav_button(:delete, @resource)
    assert_nav_button(:new, path: new_discipline_resource_path(@discipline))
  end

  def test_accredited_user_navigating_to_resource_new_view_from_show
    sign_in @accredited_user
    # Mock current_project for this test
    ApplicationController.any_instance.stubs(:current_project).returns(@project)
    visit resource_path(@resource)
    assert_current_path resource_path(@resource)

    find("a[href='#{new_discipline_resource_path(@discipline)}']").click
    assert_current_path new_discipline_resource_path(@discipline)

    new_resource_form_assertions
  end

  def test_admin_navigating_to_resource_new_view_from_index
    sign_in @project_admin
    # Mock current_project for this test
    ApplicationController.any_instance.stubs(:current_project).returns(@project)
    visit discipline_resource_index_path(@discipline)
    assert_current_path discipline_resource_index_path(@discipline)

    find("a[href='#{new_discipline_resource_path(@discipline)}']").click
    assert_current_path new_discipline_resource_path(@discipline)
  end

  def test_accredited_user_create_resource
    # TODO: This test will fail on any uniqueness requirements - it duplicates the factory
    # Make a routine to make any field unique if needed
    sign_in @accredited_user
    # Mock current_project for this test
    ApplicationController.any_instance.stubs(:current_project).returns(@project)
    visit resource_path(@resource)
    assert_current_path resource_path(@resource)

    find("a[href='#{new_discipline_resource_path(@discipline)}']").click
    assert_current_path new_discipline_resource_path(@discipline)

    new_resource_form_assertions
    fill_in_resource_fields
    assert_difference -> { resource_class.count }, 1 do
      # Submit the form data
      click_button I18n.t('actions.create')
      sleep 1.0  # Give database time to commit
    end
    # [TODO: find a way to make this safe by getting the correct record just saved]
    new_resource = resource_class.last
    assert_current_path resource_path(new_resource)
  end

  def test_accredited_team_member_edit_resource
    sign_in @accredited_user
    # Mock current_project for this test
    ApplicationController.any_instance.stubs(:current_project).returns(@project)
    visit discipline_resource_index_path(@discipline)
    assert_current_path discipline_resource_index_path(@discipline)
    original = @resource

    find("a[href='#{edit_resource_path(@resource)}']").click
    assert_current_path edit_resource_path(@resource)
    assert_text I18n.t("#{view_key}.edit.header", label: @resource.long_label)
    assert page.title.include?(I18n.t("#{view_key}.edit.title"))

    edit_resource_form_assertions

    @edit_attributes.each do |field, value|
      fill_in "#{resource_class.model_name.param_key}[#{field}]", with: value
    end
    
    # Submit the form data
    click_button I18n.t('actions.update')
    sleep 1.0  # Give database time to commit
    @resource.reload
    assert_current_path resource_path(@resource)
    @edit_attributes.each do |field, value|
      assert_text value
      assert @resource.send(field) == value
    end
    assert_text I18n.t("flash.update.notice", 
      resource_name: I18n.t("activerecord.models.#{resource_class.model_name.i18n_key}.one"))

    # Edit again to test the show view link
    find("a[href='#{edit_resource_path(@resource)}']").click
    assert_current_path edit_resource_path(@resource)

    @edit_attributes.each do |key, value|
      fill_in "#{resource_class.model_name.param_key}[#{key}]", with: original.send(key)
    end
    
    accept_confirm do
      click_link(text: I18n.t('actions.discard'))
    end
    assert_current_path resource_path(@resource)
    @edit_attributes.each do |key, value|
      assert_text value
      assert_equal value, @resource.send(key)
    end
  end

  def test_admin_destroy_resource_from_the_index_view
    sign_in @admin
    # Mock current_project for this test
    ApplicationController.any_instance.stubs(:current_project).returns(@project)
    visit discipline_resource_index_path(@discipline)
    assert_current_path discipline_resource_index_path(@discipline)
    
    click_delete(resource_path(@resource))
    assert_current_path discipline_resource_index_path(@discipline)
    refute_selector "a[href='#{resource_path(@resource)}']"
    assert_text I18n.t("flash.destroy.notice", 
      resource_name: I18n.t("activerecord.models.#{resource_class.model_name.i18n_key}.one"))
  end

  def test_admin_destroy_resource_from_the_show_view
    sign_in @admin
    # Mock current_project for this test
    ApplicationController.any_instance.stubs(:current_project).returns(@project)
    visit resource_path(@resource)
    assert_current_path resource_path(@resource)
    
    click_delete(resource_path(@resource))
    assert_current_path discipline_resource_index_path(@discipline)
    refute_selector "a[href='#{resource_path(@resource)}']"
    assert_text I18n.t("flash.destroy.notice", resource_name: @resource.model_name.human)
  end

  private # Helper methods
    
    # This assertion is generalised for discipline resource indexes, 
    # the including module shall provide the expected header and title as instance variables
    def discipline_resource_index_assertions
      assert_text @discipline_resource_index_header
      assert page.title.include?(@discipline_resource_index_title)

      assert_nav_button(:show_project, @project) # Link back to project resource view
      assert_nav_button(:show_discipline, @discipline) # Link back to discipline resource view

      assert_nav_button(:show, @resource, icon_only: true) # Link to resource show view
      index_field_assertions
    end
end