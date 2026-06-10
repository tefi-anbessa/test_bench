# frozen_string_literal: true
require "application_system_test_case"
require "helpers/system_test_helpers"
module Electrical
  class DemandsSystemTest < ApplicationSystemTestCase
    include Devise::Test::IntegrationHelpers
    include Warden::Test::Helpers
    include ActionView::Helpers::NumberHelper
    include SystemTestHelpers

    setup do
      setup_projects_and_users
      setup_disciplines(name: "Electrical", required_role: :designer)
      setup_accredited_users(role = :designer)
      setup_tags
      setup_model_specific_data
    end

    def setup_model_specific_data
      @tag.update(prefix: "PM")
      @tag2.update(prefix: "PM")
      @tagable = create(:electrical_motor, tag: @tag)
      @tagable2 = create(:electrical_motor, tag: @tag2)
      @resource = create(:electrical_demand, demandable: @tagable)
      @resource2 = create(:electrical_demand, demandable: @tagable2)
      @discipline_resource_index_header = I18n.t('electrical.demands.index.header', 
              scope_text: [@discipline.project.code, I18n.t("activerecord.models.discipline.one"), @discipline.code].join(' '))
      @project_resource_index_title = @discipline_resource_index_title = I18n.t('electrical.demands.index.title')
      # List fields that should appear in index. 
      # The generator will include test for sort link header for each column, 
      # and try to find an appropriate value field for the type.
      @index_fields = %i[notes basis config]

      # List index fields that should have ransack search capability.
      # The generator will only test for "contains" fields (_cont).
      # Don't include numeric or date fields, add model specific tests for these later in this file.
      @search_fields = %i[basis basis_notes config]

      # List all fields that should appear in show (usually all)
      @show_fields = %i[notes basis basis_notes config supply power vector power_factor current duty]
      @show_associations = %i[demandable]

      # List all fields that should appear in forms (usually all).
      # New and edit required separately because some models have read only fields that can't be edited.
      # Set a valid value for each field if required to be unique, set nil for factory default.
      # Document model has its own way to ensure uniqueness by setting serial internally.
      @new_fields = {basis: nil, basis_notes: nil, notes: nil, config: nil, power: nil, 
      vector: nil, power_factor: nil, current: nil, duty: nil}
      @edit_fields = @new_fields

      # Set an attribute/s to be modified in edit test
      # Only working with text fields at present
      @edit_attributes = { title: "REVISED FOR TEST" }
    end

    def fill_in_model_specific_fields
      # supply: nil, 
    end
    
    # Tests copied from TagableSystemTests and modified to suit.
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

    test "model specific test setup is valid" do
      assert @tagable.valid?
      assert @tagable.persisted?
      assert @tagable2.valid?
      assert @tagable2.persisted?
      assert @resource.valid?
      assert @resource.persisted?
      assert @resource2.valid?
      assert @resource2.persisted?
      assert @resource2.tag.full_tag > @resource.tag.full_tag
    end

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

      find("#discipline-#{@discipline.id}").click
      assert_current_path discipline_path(@discipline)

      find("a[href='#{discipline_resource_index_path(@discipline)}']").click
      assert_current_path discipline_resource_index_path(@discipline)

      assert_nav_button(:show, @resource)
      # Variable assertions
      refute_selector "a[href='#{edit_resource_path(@resource)}']" # team member cannot edit resource
      refute_delete(resource_path(@resource)) # team member cannot delete resource

      demand_index_assertions
    end

    def test_accredited_user_view_index
      sign_in @accredited_user
      # Mock current_project for this test
      ApplicationController.any_instance.stubs(:current_project).returns(@project)
      visit discipline_resource_index_path(@discipline)
      assert_current_path discipline_resource_index_path(@discipline)

      # Variable assertions
      assert_nav_button(:edit, @resource, path: edit_resource_path(@resource), icon_only: true) # accredited user can edit resource
      refute_delete(resource_path(@resource)) # accredited user cannot delete resource

      demand_index_assertions
    end

    def test_admin_view_index
      sign_in @admin
      # Mock current_project for this test
      ApplicationController.any_instance.stubs(:current_project).returns(@project)
      visit discipline_resource_index_path(@discipline)
      assert_current_path discipline_resource_index_path(@discipline)

      # Variable assertions
      assert_nav_button(:edit, @resource, path: edit_resource_path(@resource), icon_only: true) # admin can edit resource
      assert_nav_button(:delete, @resource, icon_only: true) # admin can delete resource

      demand_index_assertions
    end

    def test_team_member_navigating_to_the_resource_show_view
      sign_in @team_member
      # Mock current_project for this test
      ApplicationController.any_instance.stubs(:current_project).returns(@project)
      visit discipline_resource_index_path(@discipline)
      click_link(href: resource_path(@resource))
      assert_current_path resource_path(@resource)

      # Variable assertions
      refute_selector "a[href='#{edit_resource_path(@resource)}']" # edit resource
      refute_delete(resource_path(@resource)) # delete resource
      
      # Test prev and next buttons
      assert_nav_button_disabled(:previous)
      assert_nav_button(:next, @resource2)

      demand_show_assertions
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

      # Variable assertions
      assert_nav_button(:edit, @resource, path: edit_resource_path(@resource))
      refute_delete(resource_path(@resource))

      demand_show_assertions
    end

    def test_admin_resource_show_view
      sign_in @project_admin
      # Mock current_project for this test
      ApplicationController.any_instance.stubs(:current_project).returns(@project)
      visit resource_path(@resource)
      assert_current_path resource_path(@resource)

      # Variable assertions
      assert_nav_button(:edit, @resource, path: edit_resource_path(@resource))
      assert_nav_button(:delete, @resource)

      demand_show_assertions
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

      # Demand form
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

      private

      # Assertions
      # This assertion is specific to demand model
      def demand_index_assertions
        assert_text I18n.t("#{view_key}.index.header", 
          scope_text: [@discipline.project.code, 
            I18n.t("activerecord.models.discipline.one"), 
            @discipline.code].join(' '))
        assert page.title.include?(I18n.t("#{view_key}.index.title"))

        assert_nav_button(:show_discipline, @discipline) # Link back to discipline show view
        assert_nav_button(:show, @resource, icon_only: true) # Link to resource show view
        
        index_field_assertions
      end

    # Same as system test helpers show assertions, with different index back link. Opportunity to DRY this.
    def demand_show_assertions
      assert_text I18n.t("#{view_key}.show.header", label: @resource.long_label)
      assert page.title.include?(I18n.t("#{view_key}.show.title"))

      # Navigation
      # Link back to discipline resource index
      assert_nav_button(:index, path: discipline_resource_index_path(@discipline))

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
end
