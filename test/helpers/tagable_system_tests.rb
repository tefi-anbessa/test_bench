# frozen_string_literal: true
require "test_helper"
require "helpers/system_test_helpers"
module TagableSystemTests
  extend ActiveSupport::Concern
  include SystemTestHelpers

  def setup_common_tagable_data
    setup_projects_and_users
    setup_disciplines(name: "Electrical", required_role: :designer)
    setup_accredited_users(role = :designer)
    setup_tags
    setup_tagable_resources
  end

  # Tests

  def test_unauthenticated_users
    visit root_url
    refute_selector "a[href='projects_url']"
  end

  def test_team_member_navigating_to_discipline_resource_index
    sign_in @team_member
    # Mock current_project for this test
    ApplicationController.any_instance.stubs(:current_project).returns(@project)
    visit root_url
    # Click the project drop down link
    find("#project-menu-btn").click
    within ".dropdown-menu" do
      assert_selector "a[href='#{project_path(@project)}']", 
        text: [I18n.t('actions.show'), @project.code].join(" ")
      click_on [I18n.t('actions.show'), @project.code].join(" ") # Click on the project link
    end
    assert_current_path project_path(@project)

    find("a[href='#{discipline_path(@discipline)}']", text: I18n.t("actions.show")).click
    assert_current_path discipline_path(@discipline)

    find("a[href='#{discipline_resource_index_path(@discipline)}']").click
    assert_current_path discipline_resource_index_path(@discipline)

    # Variable assertions
    assert_selector "a[href='#{discipline_path(@discipline)}']" # Link back to discipline show view
    refute_selector "a[href='#{new_discipline_resource_path(@discipline)}']" # Link to new resource
    assert_selector "a[href='#{resource_path(@resource)}']" # Link to resource show view
    refute_selector "a[href='#{edit_resource_path(@resource)}']" # team member cannot edit resource
    refute_selector "a[href='#{resource_path(@resource)}'][data-method='delete']" # team member cannot delete resource

    discipline_resource_index_assertions
  end

  def test_accredited_user_view_index
    sign_in @accredited_user
    # Mock current_project for this test
    ApplicationController.any_instance.stubs(:current_project).returns(@project)
    visit discipline_resource_index_path(@discipline)
    assert_current_path discipline_resource_index_path(@discipline)

    # Variable assertions
    assert_selector "a[href='#{discipline_path(@discipline)}']" # Link back to discipline show view
    assert_selector "a[href='#{new_discipline_resource_path(@discipline)}']" # Link to new resource
    assert_selector "a[href='#{resource_path(@resource)}']" # Link to resource show view
    assert_selector "a[href='#{edit_resource_path(@resource)}']" # accredited user can edit resource
    refute_selector "a[href='#{resource_path(@resource)}'][data-method='delete']" # accredited user cannot delete resource
  end

  def test_admin_view_index
    sign_in @admin
    # Mock current_project for this test
    ApplicationController.any_instance.stubs(:current_project).returns(@project)
    visit discipline_resource_index_path(@discipline)
    assert_current_path discipline_resource_index_path(@discipline)

    # Variable assertions
    assert_selector "a[href='#{discipline_path(@discipline)}']" # Link back to discipline show view
    assert_selector "a[href='#{new_discipline_resource_path(@discipline)}']" # Link to new resource
    assert_selector "a[href='#{resource_path(@resource)}']" # Link to resource show view
    assert_selector "a[href='#{edit_resource_path(@resource)}']" # admin can edit resource
    assert_selector "a[href='#{resource_path(@resource)}'][data-method='delete']" # admin can delete resource
  end

  def test_team_member_navigating_to_the_resource_show_view
    sign_in @team_member
    # Mock current_project for this test
    ApplicationController.any_instance.stubs(:current_project).returns(@project)
    visit discipline_resource_index_path(@discipline)
    click_link(href: resource_path(@resource))
    assert_current_path resource_path(@resource)

    # Variable assertions
    assert_selector "a[href='#{discipline_resource_index_path(@discipline)}']"# Link back to discipline resource index
    refute_selector "a[href='#{edit_resource_path(@resource)}']" # edit resource
    refute_selector "a[href='#{resource_path(@resource)}'][data-method='delete']" # delete resource
    refute_selector "a[href='#{new_discipline_resource_path(@discipline)}']" # Link to new resource
    # [TODO] test prev and next buttons

    show_assertions
  end

  def test_accredited_user_resource_show_view
    sign_in @accredited_user
    # Mock current_project for this test
    ApplicationController.any_instance.stubs(:current_project).returns(@project)
    visit resource_path(@resource)
    assert_current_path resource_path(@resource)

    # Variable assertions
    assert_selector "a[href='#{discipline_resource_index_path(@discipline)}']" # Discipline resource index
    assert_selector "a[href='#{edit_resource_path(@resource)}']"
    refute_selector "a[href='#{resource_path(@resource)}'][data-method='delete']"
    assert_selector "a[href='#{new_discipline_resource_path(@discipline)}']"
  end

  def test_admin_resource_show_view
    sign_in @project_admin
    # Mock current_project for this test
    ApplicationController.any_instance.stubs(:current_project).returns(@project)
    visit resource_path(@resource)
    assert_current_path resource_path(@resource)

    # Variable assertions
    assert_selector "a[href='#{discipline_resource_index_path(@discipline)}']" # Discipline resource index
    assert_selector "a[href='#{edit_resource_path(@resource)}']"
    assert_selector "a[href='#{resource_path(@resource)}'][data-method='delete']"
    assert_selector "a[href='#{new_discipline_resource_path(@discipline)}']"
  end

  def test_accredited_user_navigating_to_new_resource_view_from_show
    sign_in @accredited_user
    # Mock current_project for this test
    ApplicationController.any_instance.stubs(:current_project).returns(@project)
    visit resource_path(@resource)
    assert_current_path resource_path(@resource)

    find("a[href='#{new_discipline_resource_path(@discipline)}']").click
    assert_current_path new_discipline_resource_path(@discipline)
    assert_text I18n.t("#{view_key}.new.header", scope_text: @discipline.long_label)
    assert page.title.include?(I18n.t("#{view_key}.new.title"))

    tag_form_assertions(nil)
    new_resource_form_assertions
  end

  def test_accredited_user_create_new_tag_and_resource_from_index
    sign_in @accredited_user
    # Mock current_project for this test
    ApplicationController.any_instance.stubs(:current_project).returns(@project)
    visit discipline_resource_index_path(@discipline)
    assert_current_path discipline_resource_index_path(@discipline)

    find("a[href='#{new_discipline_resource_path(@discipline)}']").click
    assert_current_path new_discipline_resource_path(@discipline)

    tag_form_assertions(nil)
    new_resource_form_assertions

    fill_in_tag_fields
    fill_in_resource_fields

    # Submit the form data
    click_button I18n.t('actions.create')
    sleep 2.0  # Give database time to commit
    # Form data uses @tag as a template, serial increased + 1.
    new_tag = Tag.find_by(discipline: @discipline,
      prefix: @saved_prefix, 
      serial: @saved_serial,
      suffix: @tag.suffix)
    assert_current_path resource_path(new_tag.tagable)
    assert_equal new_tag.tagable.class, resource_class
  end

  def test_accredited_user_create_new_resource_with_existing_tag_from_show
    @unassigned_tag.update(tagable_type: resource_class.name)
    sign_in @accredited_user
    # Mock current_project for this test
    ApplicationController.any_instance.stubs(:current_project).returns(@project)
    visit tag_path(@unassigned_tag)
    assert_current_path tag_path(@unassigned_tag)
    find("a[href='#{new_tag_resource_path(@unassigned_tag)}']").click
    assert_current_path new_tag_resource_path(@unassigned_tag)
    fill_in_resource_fields

    # Submit the form data
    click_button I18n.t('actions.create')
    sleep 1.0  # Give database time to commit
    assert_current_path resource_path(@unassigned_tag.reload.tagable)
    assert_text @unassigned_tag.label
    assert_text I18n.t('flash.tagables.assigned_to',
                            resource_name: resource_class.model_name.human,
                            id: @unassigned_tag.tagable.id,
                            tag: @unassigned_tag.label)
    assert_equal @unassigned_tag.tagable.class, resource_class
  end

  def test_accredited_user_edit_resource
    sign_in @accredited_user
    # Mock current_project for this test
    ApplicationController.any_instance.stubs(:current_project).returns(@project)
    visit discipline_resource_index_path(@discipline)
    assert_current_path discipline_resource_index_path(@discipline)
    original = @resource.dup
    find("a[href='#{edit_resource_path(@resource)}']").click
    assert_current_path edit_resource_path(@resource)
    
    assert_text I18n.t("#{view_key}.edit.header", label: @resource.long_label)
    assert page.title.include?(I18n.t("#{view_key}.edit.title"))

    # Tag sub-form
    tag_form_assertions(@tag)

    # Main resource form
    edit_resource_form_assertions

    # Edit the data (only implemented for text fields)
    @edit_attributes.each do |field, value|
      fill_in "#{resource_class.model_name.param_key}[#{field}]", with: value
    end

    # Submit the form data
    click_button I18n.t('actions.update')
    sleep 0.5  # Give database time to commit
    # @resource.reload
    assert_current_path resource_path(@resource)
    @resource.reload
    assert_text @resource.label
    @edit_attributes.each do |field, value|
      assert_text value
      assert @resource.send(field) == value
    end
    assert_text I18n.t("flash.update.notice", resource_name: resource_class.model_name.human)

    # Make another edit to test the show view link, and then discard
    click_link(href: edit_resource_path(@resource))
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
    # Find the actual delete link and inspect its href
    accept_confirm do
      find("a[href='#{resource_path(@resource)}'][data-method='delete']").click
    end
    assert_current_path discipline_resource_index_path(@discipline)
    refute_selector "a[href='#{resource_path(@resource)}']"
    assert_text I18n.t("flash.destroy.notice", resource_name: @resource.model_name.human)
    @tag.reload
    assert_nil @tag.tagable_id
  end

  def test_admin_destroy_resource_from_the_show_view
    sign_in @admin
    # Mock current_project for this test
    ApplicationController.any_instance.stubs(:current_project).returns(@project)
    visit resource_path(@resource)
    assert_current_path resource_path(@resource)
    # Find the delete link and click it
    accept_confirm do
      find("a[href='#{resource_path(@resource)}'][data-method='delete']").click
    end
    assert_current_path discipline_resource_index_path(@discipline)
    refute_selector "a[href='#{resource_path(@resource)}']"
    assert_text I18n.t("flash.destroy.notice", resource_name: @resource.model_name.human)
    @tag.reload
    assert_nil @tag.tagable_id
  end

  private

    # Assertions
    # This assertion is specific to tagable indexes
    def discipline_resource_index_assertions
      assert_text I18n.t("#{view_key}.index.header", 
        scope_text: [@discipline.project.code, 
          I18n.t("activerecord.models.discipline.one"), 
          @discipline.code].join(' '))
      assert page.title.include?(I18n.t("#{view_key}.index.title"))
      
      index_field_assertions
    end

    def fill_in_model_specific_fields
      # Additional model specific requirements for filling the form that cannot be handled 
      # from the field type alone. These should be excluded from the new_fields list and tested
      # in the model system test.
    end
end