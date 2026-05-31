# frozen_string_literal: true
require "helpers/test_setup_helpers"
require "application_system_test_case"
require "helpers/system_test_helpers"
class TagsSystemTest < ApplicationSystemTestCase
  include Devise::Test::IntegrationHelpers
  include Warden::Test::Helpers
  include SystemTestHelpers

  setup do
    setup_common_data
    setup_accredited_users(:designer)
    setup_tags
    setup_model_specific_data
  end

  def setup_model_specific_data
    @resource = @tag
    @discipline_resource_index_header = I18n.t('tags.index.header', 
      scope_text: [@discipline.project.code, I18n.t("activerecord.models.discipline.one"), @discipline.long_label].join(' '))
    @project_resource_index_header = I18n.t('tags.index.header', 
      scope_text: [I18n.t("activerecord.models.project.one"), @project.label].join(': '))
    @project_resource_index_title = @discipline_resource_index_title = I18n.t('tags.index.title')
    # List fields that should appear in index. 
    # The generator will include test for sort link header for each column, 
    # and try to find an appropriate value field for the type.
    @index_fields = [:stage, :full_tag, :service, :location, :parent, :notes]

    # List index fields that should have ransack search capability.
    # The generator will only test for "contains" fields (_cont).
    # Don't include numeric or date fields, add model specific tests for these later in this file.
    @search_fields = [:prefix, :serial, :service, :location, :notes]

    # List all fields that should appear in show (usually all)
    @show_fields = [:stage, :location, :notes]
    @show_associations = [:parent, :tagable, :project, :discipline]

    # List all fields that should appear in forms (usually all).
    # New and edit required separately because some models have read only fields that can't be edited.
    # Set a valid value for each field if required to be unique, set nil for factory default.
    # Document model has its own way to ensure uniqueness by setting serial internally.
    @new_fields = { }
    @edit_fields = { }

    @model_special_cases = { parent: nil, tagable: nil }
    # Set an attribute/s to be modified in edit test
    # Only working with text fields at present
    @edit_attributes = { service: "REVISED FOR TEST" }
  end

  test "team member viewing the project tags index" do
    sign_in_and_set_project @team_member, @project
    # Mock current_project and pundit_user for this test
    ApplicationController.any_instance.stubs(:current_project).returns(@project)
    # ApplicationController.any_instance.stubs(:pundit_user).returns(ApplicationPolicy::UserContext.new(@team_member, @project))
    visit root_url
    find("#project-menu-btn").click
    # Click the project show link
    within "[aria-labelledby='project-menu-btn']" do
      assert_selector "a", text: [I18n.t('actions.show'), @project.code].join(" ")
      click_on [I18n.t('actions.show'), @project.code].join(" ")
    end
    assert_current_path project_path(@project)

    # Click the project tags link
    click_link(href: project_tags_path(@project))
    assert_current_path project_tags_path(@project)

    assert_text I18n.t("tags.index.header", 
      scope_text: [I18n.t("activerecord.models.project.one"), @project.label].join(' '))
    assert page.title.include?(I18n.t("tags.index.title"))

    # Links
    refute_link I18n.t('actions.new'), href: new_discipline_tag_path(@discipline) 
    assert_link I18n.t('actions.show'), href: tag_path(@tag)
    refute_link I18n.t('actions.edit'), href: edit_tag_path(@tag) # team member cannot edit tag
    refute_selector "a[href='#{tag_path(@tag)}'][data-method='delete']" # team member cannot delete tag

    # index search fields, headers, fields
    index_field_assertions
  end

  test "team member viewing the discipline tags index" do
    sign_in_and_set_project @team_member, @project
    # Mock current_project and pundit_user for this test
    ApplicationController.any_instance.stubs(:current_project).returns(@project)
    # ApplicationController.any_instance.stubs(:pundit_user).returns(ApplicationPolicy::UserContext.new(@team_member, @project))
    visit root_url
    find("#project-menu-btn").click
    # Click the project show link
    within "[aria-labelledby='project-menu-btn']" do
      assert_selector "a", text: [I18n.t('actions.show'), @project.code].join(" ")
      click_on [I18n.t('actions.show'), @project.code].join(" ")
    end
    assert_current_path project_path(@project)
    # Click the project tags link
    click_link(href: discipline_tags_path(@discipline))
    assert_current_path discipline_tags_path(@discipline)
    assert_text I18n.t("tags.index.header", 
      scope_text: [@project.code, I18n.t("activerecord.models.discipline.one"), @discipline.long_label].join(' '))
    assert page.title.include?(I18n.t("tags.index.title"))

    # Cannot create new tag without discipline
    refute_link I18n.t('actions.new'), href: new_discipline_tag_path(@discipline) 

    # index search fields
    tag_index_field_assertions

    # Links
    assert_link I18n.t('actions.show'), href: tag_path(@tag)
    refute_link I18n.t('actions.edit'), href: edit_tag_path(@tag) # team member cannot edit tag
    refute_selector "a[href='#{tag_path(@tag)}'][data-method='delete']" # team member cannot delete tag
  end

  test "accredited user viewing the project tags index" do
    sign_in @accredited_user
    # Mock current_project for this test
    ApplicationController.any_instance.stubs(:current_project).returns(@project)
    visit project_tags_path(@project)

    # Links
    assert_link I18n.t('actions.show'), href: tag_path(@tag)
    assert_link I18n.t('actions.edit'), href: edit_tag_path(@tag) # accredited user can edit tag
    refute_selector "a[href='#{tag_path(@tag)}'][data-method='delete']" # accredited user cannot delete tag
  end

  test "accredited user viewing the discipline tags index" do
    sign_in @accredited_user
    # Mock current_project for this test
    ApplicationController.any_instance.stubs(:current_project).returns(@project)
    visit discipline_tags_path(@discipline)
    assert_current_path discipline_tags_path(@discipline)

    # Links
    # Accredited user can link to new tag
    assert_link I18n.t('actions.new'), href: new_discipline_tag_path(@discipline) 
    assert_link I18n.t('actions.show'), href: tag_path(@tag)
    assert_link I18n.t('actions.edit'), href: edit_tag_path(@tag) # accredited user can edit tag
    refute_selector "a[href='#{tag_path(@tag)}'][data-method='delete']" # accredited user cannot delete tag
  end

  test "admin viewing the project tags index" do
    sign_in @admin
    # Mock current_project for this test
    ApplicationController.any_instance.stubs(:current_project).returns(@project)
    visit project_tags_path(@project)

    # Links
    assert_link I18n.t('actions.show'), href: tag_path(@tag)
    assert_link I18n.t('actions.edit'), href: edit_tag_path(@tag) # admin can edit tag
    assert_selector "a[href='#{tag_path(@tag)}'][data-method='delete']" # admin can delete 
  end

  test "admin user viewing the discipline tags index" do
    sign_in @project_admin
    # Mock current_project for this test
    ApplicationController.any_instance.stubs(:current_project).returns(@project)
    visit discipline_tags_path(@discipline)
    assert_current_path discipline_tags_path(@discipline)

    # Links
    assert_link I18n.t('actions.new'), href: new_discipline_tag_path(@discipline) 
    assert_link I18n.t('actions.show'), href: tag_path(@tag)
    assert_link I18n.t('actions.edit'), href: edit_tag_path(@tag) # accredited user can edit tag
    assert_selector "a[href='#{tag_path(@tag)}'][data-method='delete']" # accredited user cannot delete tag
  end

  test "team member viewing the tag show view" do
    sign_in @team_member
    ApplicationController.any_instance.stubs(:current_project).returns(@project)
    visit discipline_tags_path(@discipline)
    assert_current_path discipline_tags_path(@discipline)
    click_link(href: tag_path(@tag))
    assert_current_path tag_path(@tag)
    assert_text I18n.t("tags.show.header", label: @tag.long_label)
    assert page.title.include?(I18n.t("tags.show.title"))

    # Header bar navigation links
    assert_link I18n.t('actions.index'), href: project_tags_path(@project)# Link back to project tags index
    assert_link I18n.t('actions.index'), href: discipline_tags_path(@discipline)# Link back to discipline tags index
    refute_link I18n.t('actions.edit'), href: edit_tag_path(@tag) # team member cannot edit tag
    refute_selector "a[href='#{tag_path(@tag)}'][data-method='delete']" # team member cannot delete tag
    refute_link I18n.t('actions.new'), href: new_discipline_tag_path(@discipline) # team member cannot create new tag in discipline
    # [TODO] test prev and next buttons

    show_assertions
    # Field labels
    assert_text I18n.t('activerecord.attributes.tag.tagable_type')
    assert_text I18n.t('activerecord.attributes.tag.parent')

    # Field data
    assert_text I18n.t('show.unassigned', model: I18n.t("activerecord.attributes.tag.tagable_type"))
    assert_text I18n.t('show.unassigned', model: I18n.t("activerecord.attributes.tag.parent"))

    # Go to project tags index and get the same show view from there.
    click_link(href: project_tags_path(@project))
    assert current_path, project_tags_path(@project)
    click_link(href: tag_path(@tag))
    assert_current_path tag_path(@tag)

    # Confirm the disciplines tag index link works.
    click_link(href: discipline_tags_path(@discipline))
    assert_current_path discipline_tags_path(@discipline)
  end

  test "accredited user viewing the tag show view" do
    sign_in @accredited_user
    # Mock current_project for this test
    ApplicationController.any_instance.stubs(:current_project).returns(@project)
    visit tag_path(@tag)
    assert_current_path tag_path(@tag)

    # Header bar navigation links
    assert_link I18n.t('actions.index'), href: project_tags_path(@project)# Link back to project tags index
    assert_link I18n.t('actions.index'), href: discipline_tags_path(@discipline)# Link back to discipline tags index
    assert_link I18n.t('actions.edit'), href: edit_tag_path(@tag) # accredited user can edit tag
    refute_selector "a[href='#{tag_path(@tag)}'][data-method='delete']" # accredited user cannot delete tag
    assert_link I18n.t('actions.new'), href: new_discipline_tag_path(@discipline) # accredited user can create new tag in discipline
  end

  test "admin viewing the tag show view" do
    sign_in @admin
    # Mock current_project for this test
    ApplicationController.any_instance.stubs(:current_project).returns(@project)
    visit tag_path(@tag)
    assert_current_path tag_path(@tag)

    # Header bar navigation links
    assert_link I18n.t('actions.index'), href: project_tags_path(@project)# Link back to project tags index
    assert_link I18n.t('actions.index'), href: discipline_tags_path(@discipline)# Link back to discipline tags index
    assert_link I18n.t('actions.edit'), href: edit_tag_path(@tag) # admin can edit tag
    assert_selector "a[href='#{tag_path(@tag)}'][data-method='delete']" # admin can delete tag
    assert_link I18n.t('actions.new'), href: new_discipline_tag_path(@discipline) # admin can create new tag in discipline
  end

  test "accredited user viewing the tag new view" do
    sign_in @accredited_user
    # Mock current_project for this test
    ApplicationController.any_instance.stubs(:current_project).returns(@project)
    visit discipline_tags_path(@discipline)
    click_link(href: new_discipline_tag_path(@discipline))
    assert_current_path new_discipline_tag_path(@discipline)
    assert_text I18n.t("tags.new.header", discipline: @discipline.code)
    assert page.title.include?(I18n.t("tags.new.title"))

    tag_form_field_assertions
    assert_selector "select[name='prefix_select']" # prefix schema for Electrical discipline
  end

  test "discipline sets the prefix schema" do
    # Additional discipline setup
    test_sample_disciplines_setup
    sign_in @c_user # Accredited for discipline C
    # Mock current_project for this test
    ApplicationController.any_instance.stubs(:current_project).returns(@project)
    # Discipline C defaults to default schema
    visit new_discipline_tag_path(@discipline_c)
    assert_current_path new_discipline_tag_path(@discipline_c)

    assert_selector "input[name='tag[prefix]']"
    sign_out @c_user

    sign_in @m_user # Accredited for discipline M
    # Discipline M defaults to dim1 schema
    visit new_discipline_tag_path(@discipline_m)
    assert_current_path new_discipline_tag_path(@discipline_m)

    assert_selector "select[name='prefix_select']"
    sign_out @m_user
    
    sign_in @accredited_user # Accredited for discipline E default

    visit discipline_tags_path(@discipline)
    click_link(href: new_discipline_tag_path(@discipline))
    assert_current_path new_discipline_tag_path(@discipline)

    # Default discipline is E and default schema for E is dim2.
    assert_selector "select[name='prefix_select']"
    sign_out @accredited_user
    
    sign_in @j_user # Accredited for discipline J
  
    visit new_discipline_tag_path(@discipline_j)
    assert_current_path new_discipline_tag_path(@discipline_j)

    assert_selector "select[name='measured_variable']"
    assert_selector "select[name='modifier']"
    assert_selector "select[name='function']"
    assert_selector "select[name='modifier_function']"
    assert_selector "[data-tag-target='prefixField'][readonly]"
    sign_out @j_user
  end

  test "accredited users create new tags" do
    # Additional discipline setup
    test_sample_disciplines_setup
    @count = 0
    sign_in @c_user
    # Mock current_project for this test
    ApplicationController.any_instance.stubs(:current_project).returns(@project)
    visit new_discipline_tag_path(@discipline_c)
    assert_current_path new_discipline_tag_path(@discipline_c)

    # Build civil tag C:S-0001.A
    fill_in_tag_fields
    fill_in "tag[prefix]", with: "S"

    click_button I18n.t('actions.create')
    sleep 0.1  # Give database time to commit
    new_tag = Tag.find_by(prefix: "S", serial: @count)
    assert_current_path tag_path(new_tag)
    assert_text I18n.t("flash.create.notice", resource_name: I18n.t("activerecord.models.tag", count: 1))
    sign_out @c_user

    sign_in @m_user # Accredited for discipline M
    # Mock current_project for this test
    ApplicationController.any_instance.stubs(:current_project).returns(@project)
    # Discipline M defaults to dim1 schema
    visit new_discipline_tag_path(@discipline_m)
    assert_current_path new_discipline_tag_path(@discipline_m)

    # Build mechanical tag M:A-0002.A
    fill_in_tag_fields
    select("A", from: "prefix_select", match: :first)

    click_button I18n.t('actions.create')
    sleep 0.1  # Give database time to commit
    new_tag = Tag.find_by(prefix: "A", serial: @count)
    assert_current_path tag_path(new_tag)
    assert_text I18n.t("flash.create.notice", resource_name: I18n.t("activerecord.models.tag", count: 1))
    sign_out @m_user

    sign_in @accredited_user # Accredited for discipline E default
    # Mock current_project for this test
    ApplicationController.any_instance.stubs(:current_project).returns(@project)
    visit new_discipline_tag_path(@discipline)

    # Build electrical tag E-PM-0003.A 
    fill_in_tag_fields
    select("B", from: "prefix_select", match: :first)

    click_button I18n.t('actions.create')
    sleep 0.1  # Give database time to commit
    new_tag = Tag.find_by(prefix: "B", serial: @count)
    assert_current_path tag_path(new_tag)
    assert_text I18n.t("flash.create.notice", resource_name: I18n.t("activerecord.models.tag", count: 1))
    sign_out @accredited_user

    sign_in @j_user
    # Mock current_project for this test
    ApplicationController.any_instance.stubs(:current_project).returns(@project)
    visit new_discipline_tag_path(@discipline_j)
    assert_current_path new_discipline_tag_path(@discipline_j)
    # Build instrument tag J:AT-0004.A
    fill_in_tag_fields
    select("A", from: "measured_variable", match: :first)
    select("T", from: "function", match: :first)

    click_button I18n.t('actions.create')
    sleep 0.1  # Give database time to commit
    new_tag = Tag.find_by(prefix: "AT", serial: @count, suffix: "A")
    assert_current_path tag_path(new_tag)
    assert_text "AT0004A"
    assert_text I18n.t("flash.create.notice", resource_name: I18n.t("activerecord.models.tag", count: 1))
    sign_out @j_user
  end

  test "accredited user edit tag with default schema" do
    @count = 10
    sign_in @accredited_user
    # Mock current_project for this test
    ApplicationController.any_instance.stubs(:current_project).returns(@project)
    visit tag_path(@tag)
    click_link(href: edit_tag_path(@tag))
    assert_current_path edit_tag_path(@tag)
    assert_text I18n.t("tags.edit.header", label: @tag.reload.label)
    assert page.title.include?(I18n.t("tags.edit.title"))

    # This test is rather brittle. Depends on schema for discpline chosen to be tested.
    tag_form_field_assertions
    assert_selector "select[name='prefix_select']" # prefix schema for Electrical discipline

    # assert_selector "[data-tag-target='prefixField'][readonly]"

    # Update the form
    fill_in "tag_location", with: "NEW LOCATION"
    click_button I18n.t('actions.update')
    sleep 1.0  # Give server time to respond
    @tag.reload
    assert_current_path tag_path(@tag)
    assert_text "NEW LOCATION"
    assert_text I18n.t("flash.update.notice", resource_name: I18n.t("activerecord.models.tag.one"))

    # Make another edit to test the show view link, and then discard
    visit tag_path(@tag)
    click_link(href: edit_tag_path(@tag))
    assert_current_path edit_tag_path(@tag)
    fill_in "tag_serial", with: "0201"
    
    fill_in "tag_service", with: "RESTORED SERVICE"
    accept_confirm do
      click_link(text: I18n.t('actions.discard'))
    end
    @tag.reload
    assert_current_path tag_path(@tag)
    refute_text "RESTORED SERVICE"
  end

  test "admin destroy tag from the index view" do
    sign_in @admin
    # Mock current_project for this test
    ApplicationController.any_instance.stubs(:current_project).returns(@project)
    visit project_tags_path(@project)
     # Find the actual delete link and inspect its href
    accept_confirm do
      find("a[href='#{tag_path(@tag)}'][data-method='delete']").click
    end
    assert_current_path discipline_tags_path(@discipline)
    refute_selector "a[href='#{tag_path(@tag)}']"
    assert_text I18n.t("flash.destroy.notice", resource_name: I18n.t("activerecord.models.tag.one"))
  end

  test "admin destroy tag from the show view" do
    sign_in @admin
    # Mock current_project for this test
    ApplicationController.any_instance.stubs(:current_project).returns(@project)
    visit tag_path(@tag)
     # Find the actual delete link and inspect its href
    accept_confirm do
      find("a[href='#{tag_path(@tag)}'][data-method='delete']").click
    end
    assert_current_path discipline_tags_path(@discipline)
    refute_selector "a[href='#{tag_path(@tag)}']"
    assert_text I18n.t("flash.destroy.notice", resource_name: I18n.t("activerecord.models.tag.one"))
  end

  # Parent hierarchy additions
  test "create new tag as child" do
    sign_in @accredited_user # Accredited for discipline E default
    # Mock current_project for this test
    ApplicationController.any_instance.stubs(:current_project).returns(@project)
    visit new_discipline_tag_path(@discipline)

    # Build electrical tag E-PM-0003.A 
    @count = 11
    fill_in_tag_fields
    select("B", from: "prefix_select", match: :first)
    assert_selector "select[name='tag[parent_id]']"
    select(@tag.full_tag, from: "tag[parent_id]", match: :first)

    click_button I18n.t('actions.create')
    sleep 0.1  # Give database time to commit
    new_tag = Tag.find_by(prefix: "B", serial: @count)
    assert_current_path tag_path(new_tag)
    assert_text I18n.t("flash.create.notice", resource_name: I18n.t("activerecord.models.tag", count: 1))

    # Verify parent relationship
    assert_equal @tag.id, new_tag.parent_id

    # Associations
    # Parent collapsible card - test assumes @resource is the child tag
    @resource = new_tag
    collapsible_assertions(new_tag, :parent)
    assert_link href: tag_path(@tag)

    find_link(href: tag_path(@tag)).click
    assert_current_path tag_path(@tag)

    # Children collapsible card
    @resource = @tag
    children_collapsible_assertions(@tag, :children)
    assert_link href: tag_path(new_tag)

    sign_out @accredited_user
  end

  private

    def tag_index_field_assertions
      # index search fields and sort link headers
      assert_field "q[prefix_cont]"
      assert_field "q[serial_eq]"
      assert_field "q[service_cont]"
      assert_field "q[location_cont]"
      assert_field "q[notes_cont]"
      assert_sort_link :stage, I18n.t("activerecord.attributes.tag.stage")
      assert_sort_link :full_tag, I18n.t("activerecord.attributes.tag.full_tag")
      assert_sort_link :service, I18n.t("activerecord.attributes.tag.service")
      assert_sort_link :location, I18n.t("activerecord.attributes.tag.location")
      assert_sort_link :tagable_type, I18n.t("activerecord.attributes.tag.tagable_type")

      # index fields
      assert_text @tag.stage
      assert_text @tag.label
      assert_text @tag.prefix
      assert_text @tag.serial
      assert_text @tag.service
      assert_text @tag.location
      assert_text @tag.tagable.model_name.human if @tag.tagable.present?
    end

    def tag_form_field_assertions
      # Data fields
      assert_field "tag[stage]"
      assert_field "tag[serial]"
      assert_field "tag[suffix]"
      assert_field "tag[service]"
      assert_field "tag[location]"
      assert_field "tag[notes]"
      assert_selector "select[name='tag[tagable_type]']"

      # Form buttons
      assert_selector "button[type='submit']"
      assert_selector "a.btn.btn-warning", text: I18n.t('actions.discard')
    end

    def test_sample_disciplines_setup
      # Discipline J defaults to isa51 schema
      @discipline_j = @project.disciplines.find_by(code: 'J')
      @j_user = create(:user)
      @j_user.grant(:designer, @discipline_j)
    
      # Discipline M defaults to dim1 schema
      @discipline_m = @project.disciplines.find_by(code: 'M')
      @m_user = create(:user)
      @m_user.grant(:designer, @discipline_m)
    
      # Discipline C defaults to default schema
      @discipline_c = @project.disciplines.find_by(code: 'C')
      @c_user = create(:user)
      @c_user.grant(:designer, @discipline_c)
    end

    def fill_in_tag_fields
      fill_in "tag_stage", with: "1"
      fill_in "tag_serial", with: @count += 1
      fill_in "tag_suffix", with: "A"
      fill_in "tag_service", with: "TAG TEST #{@count}"
    end
end
