# frozen_string_literal: true
require "application_system_test_case"
require "helpers/system_test_helpers"
class SwatchesSystemTest < ApplicationSystemTestCase
  include Devise::Test::IntegrationHelpers
  include Warden::Test::Helpers
  include ActionView::Helpers::NumberHelper
  include SystemTestHelpers

  setup do
    setup_projects_and_users
    setup_model_specific_data
  end

  def setup_model_specific_data
    @project.update(swatch: @swatch)
    @resource = @swatch
    @index_header = I18n.t("swatches.index.header")
    @index_title = I18n.t("swatches.index.title")
    # List fields that should appear in index. 
    @index_fields = [:name, :bg, :text, :form_bg, :form_field, :card_bg, :card_header_bg, :card_border, 
      :badge_bg, :badge_text, :link_text, :link_hover]

    # List index fields that should have ransack search capability.
    # The generator will only test for "contains" fields (_cont).
    # Don't include numeric or date fields, add model specific tests for these later in this file.
    @search_fields = []

    # List all fields that should appear in show (usually all)
    @show_fields = [:name, :bg, :text, :form_bg, :form_field, :card_bg, :card_header_bg, :card_border, 
      :badge_bg, :badge_text, :link_text, :link_hover]
    @show_associations = []

    # List all fields that should appear in forms (usually all)
    @form_fields = [:name, :bg, :text, :form_bg, :form_field, :card_bg, :card_header_bg, :card_border, 
      :badge_bg, :badge_text, :link_text, :link_hover]
  end

  test "admin navigating to index" do
    sign_in @admin
    # Mock current_project for this test
    ApplicationController.any_instance.stubs(:current_project).returns(@project)
    visit root_path
    click_link(href: swatches_path)
    assert_current_path swatches_path
    index_assertions
    assert_nav_button(:new, path: new_swatch_path) # Link to new resource
    
    assert_nav_button(:show, @swatch, icon_only: true)
    assert_nav_button(:edit, @swatch, path: edit_swatch_path(@swatch), icon_only: true) # admin can edit resource
    refute_delete(swatch_path(@swatch)) # admin cannot delete swatch
  end

  test "app owner viewing index" do
    sign_in @app_owner
    # Mock current_project for this test
    ApplicationController.any_instance.stubs(:current_project).returns(@project)
    visit swatches_path
    assert_current_path swatches_path
    assert_nav_button(:new, path: new_swatch_path) # Link to new resource
    
    assert_nav_button(:show, @swatch, icon_only: true)
    assert_nav_button(:edit, @swatch, path: edit_swatch_path(@swatch), icon_only: true) # app owner can edit resource
    assert_nav_button(:delete, @swatch, path: swatch_path(@swatch), icon_only: true) # app owner can delete resource
  end

  test "team member view show" do
    # There is no path for team members to view swatches, only for admins.
    # Permissions allow it though...
    sign_in @team_member
    # Mock current_project for this test
    ApplicationController.any_instance.stubs(:current_project).returns(@project)
    visit swatch_path(@swatch)
    assert_current_path swatch_path(@swatch)
    assert_text I18n.t("swatches.show.header", label: @swatch.label)
    assert page.title.include?(I18n.t("swatches.show.title"))

    refute_selector "a[href='#{new_swatch_path}']" # team member has no link to new resource

    assert_nav_button(:index, path: swatches_path) # link to index
    refute_selector "a[href='#{edit_swatch_path(@swatch)}']" # team member cannot edit resource
    refute_delete(swatch_path(@swatch)) # admin cannot delete swatch

    swatch_show_assertions
  end

  test "team member testing prev and next in show view" do
    # Create a second swatch to enable prev/next navigation
    @swatch2 = create(:swatch, name: 'swatch2')
    sign_in @team_member
    ApplicationController.any_instance.stubs(:current_project).returns(@project)
    visit swatch_path(@swatch)
    assert_current_path swatch_path(@swatch)

    # Header bar navigation links should include disabled prev button 
    # and working next button (only 2 tags created)
    assert_nav_button_disabled(:previous)
    assert_nav_button(:next, @swatch2)

    click_link I18n.t('actions.next')
    assert_current_path swatch_path(@swatch2)

    # Header bar navigation links should include working prev button 
    # and disabled next button (only 2 tags created)
    assert_nav_button(:previous, @swatch)
    assert_nav_button_disabled(:next)

    click_link I18n.t('actions.previous')
    assert_current_path swatch_path(@swatch)
  end

  test "admin view show" do
    sign_in @admin
    # Mock current_project for this test
    ApplicationController.any_instance.stubs(:current_project).returns(@project)
    visit swatch_path(@swatch)
    assert_current_path swatch_path(@swatch)

    assert_nav_button(:new, path: new_swatch_path) # Link to new resource

    assert_nav_button(:index, path: swatches_path) # link to index
    assert_nav_button(:edit, @swatch, path: edit_swatch_path(@swatch)) # admin can edit resource
    refute_delete(swatch_path(@swatch)) # admin cannot delete resource

    swatch_show_assertions
  end

  test "app_owner view show" do
    sign_in @app_owner
    # Mock current_project for this test
    ApplicationController.any_instance.stubs(:current_project).returns(@project)
    visit swatch_path(@swatch)
    assert_current_path swatch_path(@swatch)
    assert_nav_button(:new, path: new_swatch_path) # Link to new resource

    assert_nav_button(:index, path: swatches_path) # link to index
    assert_nav_button(:edit, @swatch, path: edit_swatch_path(@swatch)) # admin can edit resource
    assert_nav_button(:delete, @swatch, path: swatch_path(@swatch))
  end

  test "admin view the new form" do
    # Test link from index page
    sign_in @admin
    # Mock current_project for this test
    ApplicationController.any_instance.stubs(:current_project).returns(@project)
    visit root_path
    assert_selector "a[href='#{swatches_path}']"
    click_link(href: swatches_path)
    assert_current_path swatches_path
    click_link(href: new_swatch_path) # Link from index to new resource
    assert_current_path new_swatch_path

    # Field labels
    @form_fields.each do |field|
      assert_text resource_class.human_attribute_name(field)
    end
    assert_selector "input[type='text'][name='swatch[name]']"
    @form_fields.excluding(:name).each do |field|
      assert_selector "input[type='color'][name='swatch[#{field}]']"
    end
    # Form buttons
    assert_selector "button[type='submit']"
    assert_selector "a.btn.btn-warning", text: I18n.t('actions.discard')
  end

  test "admin create new resource" do
    # Test link from show page
    sign_in @admin
    # Mock current_project for this test
    ApplicationController.any_instance.stubs(:current_project).returns(@project)
    visit swatch_path(@swatch)
    click_link(href: new_swatch_path) # Link from show to new resource
    assert_current_path new_swatch_path
    
    fill_in "swatch[name]", with: "system_test_create"
    @form_fields.excluding(:name).each do |field|
        name = "#{resource_class.model_name.param_key}[#{field}]"
        value = @resource.send(field)
        fill_in name, with: value
    end
    # Submit the form data
    click_button I18n.t('actions.create')
    sleep 1.0  # Give database time to commit
    new_swatch = Swatch.find_by(name: 'system_test_create')
    assert_current_path swatch_path(new_swatch)
  end

  test "admin edit resource" do
    sign_in @admin
    # Mock current_project for this test
    ApplicationController.any_instance.stubs(:current_project).returns(@project)
    visit swatches_path
    assert_current_path swatches_path

    click_link(href: edit_swatch_path(@swatch)) # Link from index to edit resource
    assert_current_path edit_swatch_path(@swatch)
    
    fill_in "swatch[name]", with: "system_test_edit"
    @form_fields.excluding(:name).each do |field|
        name = "#{resource_class.model_name.param_key}[#{field}]"
        value = @resource.send(field)
        fill_in name, with: value.succ
    end
    # Submit the form data
    click_button I18n.t('actions.update')
    sleep 1.0  # Give database time to commit
    assert_current_path swatch_path(@swatch)
    @swatch.reload
    assert_equal 'system_test_edit', @swatch.name
    # Edit again from show view, exercise the discard change button
    click_link(href: edit_swatch_path(@swatch)) # Link from show to edit resource
    assert_current_path edit_swatch_path(@swatch)

    fill_in "swatch[name]", with: "system_test_edit_again"
    accept_confirm do
      click_link(text: I18n.t('actions.discard'))
    end
    @swatch.reload
    assert_equal 'system_test_edit', @swatch.name
  end

  test "app owner destroy resource" do
    @unattached_swatch = create(:swatch, name: "unattached_swatch")
    sign_in @app_owner
    # Mock current_project for this test
    ApplicationController.any_instance.stubs(:current_project).returns(@project)
    visit swatch_path(@unattached_swatch)
    assert_current_path swatch_path(@unattached_swatch)
    # Click the delete button - helper method has built in confirm.
    click_delete(swatch_path(@unattached_swatch))
    assert_current_path swatches_path
    refute_selector "a[href='#{swatch_path(@unattached_swatch)}']"
  end

  private

    def swatch_show_assertions
      assert_text I18n.t("#{view_key}.show.header", label: @resource.long_label)
      assert page.title.include?(I18n.t("#{view_key}.show.title"))

      # Navigation
      assert_nav_button(:index, Swatch.new, path: swatches_path) # Link back to swatches index

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