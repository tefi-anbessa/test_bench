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
    assert (@resource2.full_tag > @resource.full_tag)
  end

  def test_unauthenticated_users
    visit root_url
    refute_selector "a[href='projects_url']"
  end

  def test_team_member_navigating_to_discipline_tagable_index
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

    find("#discipline-#{@discipline.id}").click
    assert_current_path discipline_path(@discipline)

    find("a[href='#{discipline_tagable_resources_path(@discipline)}']").click
    assert_current_path discipline_tagable_resources_path(@discipline)

    assert_tagable_nav_button(:show, @resource)
    # Variable assertions
    refute_selector "a[href='#{new_discipline_tagable_path(@discipline, tagable_type: resource_name)}']" # Link to new resource
    refute_selector "a[href='#{edit_tag_tagable_path(@tag)}']" # team member cannot edit resource
    refute_delete(tag_tagable_path(@tag)) # team member cannot delete resource

    discipline_resource_index_assertions
  end

  def test_accredited_user_view_index
    sign_in @accredited_user
    # Mock current_project for this test
    ApplicationController.any_instance.stubs(:current_project).returns(@project)
    visit discipline_tagable_resources_path(@discipline)
    assert_current_path discipline_tagable_resources_path(@discipline)

    # Variable assertions
    assert_tagable_nav_button(:new, @discipline) # Link to new resource
    assert_tagable_nav_button(:edit, @resource, icon_only: true) # accredited user can edit resource
    refute_delete(tag_tagable_path(@tag)) # accredited user cannot delete resource

    discipline_resource_index_assertions
  end

  def test_admin_view_index
    sign_in @admin
    # Mock current_project for this test
    ApplicationController.any_instance.stubs(:current_project).returns(@project)
    visit discipline_tagable_resources_path(@discipline)
    assert_current_path discipline_tagable_resources_path(@discipline)

    # Variable assertions
    assert_tagable_nav_button(:new, @discipline) # Link to new resource
    assert_tagable_nav_button(:edit, @resource, icon_only: true) # admin can edit resource
    assert_tagable_nav_button(:delete, @resource, icon_only: true) # admin can delete resource

    discipline_resource_index_assertions
  end

  def test_team_member_navigating_to_the_resource_show_view
    sign_in @team_member
    # Mock current_project for this test
    ApplicationController.any_instance.stubs(:current_project).returns(@project)
    visit discipline_tagable_resources_path(@discipline)
    assert_current_path discipline_tagable_resources_path(@discipline)

    click_link(href: tag_tagable_path(@tag))
    assert_current_path tag_tagable_path(@tag)

    # Variable assertions
    refute_selector "a[href='#{edit_tag_tagable_path(@tag)}']" # edit resource
    refute_delete(tag_tagable_path(@tag)) # delete resource
    refute_selector "a[href='#{new_discipline_tagable_path(@discipline, tagable_type: resource_name)}']" # Link to new resource
    
    # Test prev and next buttons
    assert_nav_button_disabled(:previous)
    assert_tagable_nav_button(:next, @resource2)

    tagable_show_assertions
  end

  def test_team_member_test_next_and_previous_buttons
    sign_in @team_member
    # Mock current_project for this test
    ApplicationController.any_instance.stubs(:current_project).returns(@project)
    visit tag_tagable_path(@tag)
    assert_current_path tag_tagable_path(@tag)
    
    # Header bar should include disabled previous button and enabled next button
    assert_nav_button_disabled(:previous)
    assert_tagable_nav_button(:next, @resource2)
    
    click_link I18n.t('actions.next')
    assert_current_path tag_tagable_path(@tag2)

    # Header bar should include enabled previous button and disabled next button
    assert_tagable_nav_button(:previous, @resource)
    assert_nav_button_disabled(:next)

    click_link I18n.t('actions.previous')
    assert_current_path tag_tagable_path(@tag)
  end

  def test_accredited_user_resource_show_view
    sign_in @accredited_user
    # Mock current_project for this test
    ApplicationController.any_instance.stubs(:current_project).returns(@project)
    visit tag_tagable_path(@tag)
    assert_current_path tag_tagable_path(@tag)

    # Variable assertions
    assert_tagable_nav_button(:edit, @resource)
    refute_delete(tag_tagable_path(@tag))
    assert_tagable_nav_button(:new, @discipline) 

    tagable_show_assertions
  end

  def test_admin_resource_show_view
    sign_in @project_admin
    # Mock current_project for this test
    ApplicationController.any_instance.stubs(:current_project).returns(@project)
    visit tag_tagable_path(@tag)
    assert_current_path tag_tagable_path(@tag)

    # Variable assertions
    assert_tagable_nav_button(:edit, @resource)
    assert_tagable_nav_button(:delete, @resource)
    assert_tagable_nav_button(:new, @discipline)

    tagable_show_assertions
  end

  def test_accredited_user_navigating_to_new_resource_view_from_show
    sign_in @accredited_user
    # Mock current_project for this test
    ApplicationController.any_instance.stubs(:current_project).returns(@project)
    visit tag_tagable_path(@tag)
    assert_current_path tag_tagable_path(@tag)

    find("a[href='#{new_discipline_tagable_path(@discipline, tagable_type: resource_name)}']").click
    assert_current_path new_discipline_tagable_path(@discipline, tagable_type: resource_name)
    assert_text I18n.t("#{view_key}.new.header", scope_text: @discipline.long_label)
    assert page.title.include?(I18n.t("#{view_key}.new.title"))

    tag_form_assertions(nil)
    new_resource_form_assertions
  end

  def test_accredited_user_create_new_tag_and_resource_from_index
    sign_in @accredited_user
    # Mock current_project for this test
    ApplicationController.any_instance.stubs(:current_project).returns(@project)
    visit discipline_tagable_resources_path(@discipline)
    assert_current_path discipline_tagable_resources_path(@discipline)

    find("a[href='#{new_discipline_tagable_path(@discipline, tagable_type: resource_name)}']").click
    assert_current_path new_discipline_tagable_path(@discipline, tagable_type: resource_name)

    tag_form_assertions(nil)
    new_resource_form_assertions

    fill_in_tag_fields
    fill_in_resource_fields

    # Submit the form data
    click_button I18n.t('actions.create')
    sleep 1.0  # Give database time to commit
    # Form data uses @tag as a template, serial increased + 1.
    new_tag = Tag.find_by(discipline: @discipline,
      prefix: @saved_prefix, 
      serial: @saved_serial,
      suffix: @tag.suffix)
    assert_current_path tag_tagable_path(new_tag)
    assert_equal new_tag.tagable.class, resource_class
  end

  def test_accredited_user_create_new_resource_with_existing_tag_from_show
    @unassigned_tag.update(tagable_type: resource_class.name)
    sign_in @accredited_user
    # Mock current_project for this test
    ApplicationController.any_instance.stubs(:current_project).returns(@project)
    visit tag_path(@unassigned_tag)
    assert_current_path tag_path(@unassigned_tag)
    find("a[href='#{new_tag_tagable_path(@unassigned_tag, tagable_type: resource_name)}']").click
    assert_current_path new_tag_tagable_path(@unassigned_tag, tagable_type: resource_name)
    fill_in_resource_fields

    # Submit the form data
    click_button I18n.t('actions.create')
    sleep 1.0  # Give database time to commit
    @unassigned_tag.reload
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
    visit discipline_tagable_resources_path(@discipline)
    assert_current_path discipline_tagable_resources_path(@discipline)
    original = @resource.dup
    find("a[href='#{edit_tag_tagable_path(@tag)}']").click
    assert_current_path edit_tag_tagable_path(@tag)
    
    assert_text I18n.t("#{view_key}.edit.header", label: @resource.long_label)
    assert page.title.include?(I18n.t("#{view_key}.edit.title"))

    # Tag details
    tag_detail_assertions(@tag)

    # Main resource form
    edit_resource_form_assertions

    # Edit the data (only implemented for text fields)
    @edit_attributes.each do |field, value|
      fill_in "#{resource_class.model_name.param_key}[#{field}]", with: value
    end

    # Submit the form data
    click_button I18n.t('actions.update')
    sleep 0.5  # Give database time to commit
    assert_current_path tag_tagable_path(@tag)
    @resource.reload
    assert_text @resource.label
    @edit_attributes.each do |field, value|
      assert_text value
      assert @resource.send(field) == value
    end
    assert_text I18n.t("flash.update.notice", resource_name: resource_class.model_name.human)

    # Make another edit to test the show view link, and then discard
    click_link(href: edit_tag_tagable_path(@tag))
    assert_current_path edit_tag_tagable_path(@tag)

    @edit_attributes.each do |key, value|
      fill_in "#{resource_class.model_name.param_key}[#{key}]", with: original.send(key)
    end
    
    accept_confirm do
      click_link(text: I18n.t('actions.discard'))
    end
    assert_current_path tag_tagable_path(@tag)
    @edit_attributes.each do |key, value|
      assert_text value
      assert_equal value, @resource.send(key)
    end
  end

  def test_admin_destroy_resource_from_the_index_view
    sign_in @admin
    # Mock current_project for this test
    ApplicationController.any_instance.stubs(:current_project).returns(@project)
    visit discipline_tagable_resources_path(@discipline)
    assert_current_path discipline_tagable_resources_path(@discipline)

    click_delete(tag_tagable_path(@tag))
    assert_current_path discipline_tagable_resources_path(@discipline)
    refute_selector "a[href='#{tag_tagable_path(@tag)}']"
    assert_text I18n.t("flash.destroy.notice", resource_name: resource_class.model_name.human)
    @tag.reload
    assert_nil @tag.tagable_id
  end

  def test_admin_destroy_resource_from_the_show_view
    sign_in @admin
    # Mock current_project for this test
    ApplicationController.any_instance.stubs(:current_project).returns(@project)
    visit tag_tagable_path(@tag)
    assert_current_path tag_tagable_path(@tag)
    
    click_delete(tag_tagable_path(@tag))
    assert_current_path discipline_tagable_resources_path(@discipline)
    refute_selector "a[href='#{tag_tagable_path(@tag)}']"
    assert_text I18n.t("flash.destroy.notice", resource_name: resource_class.model_name.human)
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

      assert_nav_button(:show_discipline, @discipline) # Link back to discipline show view
      assert_nav_button(:show, path: tag_tagable_path(@tag), icon_only: true) # Link to resource show view
      
      index_field_assertions
    end

    def fill_in_model_specific_fields
      # Additional model specific requirements for filling the form that cannot be handled 
      # from the field type alone. These should be excluded from the new_fields list and tested
      # in the model system test.
    end

    # Same as system test helpers show assertions, with different index back link. Opportunity to DRY this.
    def tagable_show_assertions
      assert_text I18n.t("#{view_key}.show.header", label: @resource.long_label)
      assert page.title.include?(I18n.t("#{view_key}.show.title"))

      # Navigation
      # Link back to discipline resource index
      assert_nav_button(:index, path: discipline_tagables_path(@discipline, tagable_type: resource_name))

      # Field labels
      @show_fields.each do |field|
        assert_text I18n.t("activerecord.attributes.#{resource_class.model_name.i18n_key}.#{field}")
      end

      # Field data 
      field_display_assertions(@show_fields)

      # Associations
      @show_associations.each do |association|
        if @resource.send(association).present?
          collapsible_assertions(@resource, association)
        else
          # Text for unassigned association varies depending on association type.
          # If it is important, test it in the calling class.
        end
      end
    end
end