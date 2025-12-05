require "application_system_test_case"
require File.join(Rails.root, 'test', 'helpers', 'tagable_system_test_patterns')
module Electrical
  class MotorsSystemTest < ApplicationSystemTestCase
    include TagableSystemTestPatterns
    include Devise::Test::IntegrationHelpers
    include Warden::Test::Helpers
    include ActionView::Helpers::NumberHelper

    setup do
      setup_common_tagable_data
      setup_model_specific_data
    end

    def setup_model_specific_data
      # List fields that should appear in index
      @index_fields = %w[motor_type frame_size ingress_protection poles speed_rated]
      # List fields that should have ransack search capability
      # Ignore poles as it is a numeric field searched with _eq and standard test does not match.
      @search_fields = %w[motor_type frame_size ingress_protection  speed_rated notes]
      # List all fields that should appear in show
      @show_fields = %w[motor_type frame_size ingress_protection poles speed_rated notes]
      # List all fields that should appear in forms
      @form_fields = %w[motor_type frame_size ingress_protection poles speed_rated notes]
    end

    test "unauthenticated users" do
      visit root_url
      refute_selector "#electrical-menu-btn"
    end

    test "accredited team member view index" do
      sign_in @accredited_team_member
      # Mock current_project for this test
      ApplicationController.any_instance.stubs(:current_project).returns(@project)
      visit index_path
      assert_current_path send("#{resource_class.model_name.route_key}_path")
      # Links
      assert_selector "a[href='#{new_resource_path}']" # Link to new motor
      assert_selector "a[href='#{resource_path(@resource)}']" # Link to motor show view
      assert_selector "a[href='#{edit_resource_path(@resource)}']" # accredited team member can edit motor
      refute_selector "a[href='#{resource_path(@resource)}'][data-method='delete']" # accredited team member cannot delete motor
    end

    test "admin view index" do
      sign_in @admin
      # Mock current_project for this test
      ApplicationController.any_instance.stubs(:current_project).returns(@project)
      visit index_path
      assert_current_path index_path
      # Links
      assert_selector "a[href='#{new_resource_path}']" # Link to new motor
      assert_selector "a[href='#{resource_path(@resource)}']" # Link to motor show view
      assert_selector "a[href='#{edit_resource_path(@resource)}']" # accredited team member can edit motor
      assert_selector "a[href='#{resource_path(@resource)}'][data-method='delete']" # admin can delete motor
    end

    test "team member navigating to the resource show view" do
      sign_in @team_member
      # Mock current_project for this test
      ApplicationController.any_instance.stubs(:current_project).returns(@project)
      visit index_path
      click_link(href: resource_path(@resource))
      assert_current_path resource_path(@resource)

      # Header bar navigation links
      assert_selector "a[href='#{index_path}']"# Link back to motors index
      refute_selector "a[href='#{edit_resource_path(@resource)}']" # team member cannot edit motor
      refute_selector "a[href='#{resource_path(@resource)}'][data-method='delete']" # team member cannot delete motor
      # [TODO] test prev and next buttons
      show_assertions
    end

    test "accredited team member viewing the resource show view" do
      sign_in @accredited_team_member
      # Mock current_project for this test
      ApplicationController.any_instance.stubs(:current_project).returns(@project)
      visit resource_path(@resource)
      assert_current_path resource_path(@resource)

      # Header bar navigation links
      assert_selector "a[href='#{index_path}']"# Link back to motors index
      assert_selector "a[href='#{edit_resource_path(@resource)}']" # accredited team member can edit motor
      refute_selector "a[href='#{resource_path(@resource)}'][data-method='delete']" # team member cannot delete motor
      # [TODO] test prev and next buttons
    end

    test "admin viewing the resource show view" do
      sign_in @admin
      # Mock current_project for this test
      ApplicationController.any_instance.stubs(:current_project).returns(@project)
      visit resource_path(@resource)
      assert_current_path resource_path(@resource)

      # Header bar navigation links
      assert_selector "a[href='#{index_path}']"# Link back to motors index
      assert_selector "a[href='#{edit_resource_path(@resource)}']" # admin can edit motor
      assert_selector "a[href='#{resource_path(@resource)}'][data-method='delete']" # admin can delete motor
      # [TODO] test prev and next buttons
    end

    test "accredited team member navigate to the new tag and new resource form" do
      sign_in @accredited_team_member
      # Mock current_project for this test
      ApplicationController.any_instance.stubs(:current_project).returns(@project)
      visit index_path
      click_link(href: new_resource_path)
      assert_current_path new_resource_path
      assert_text I18n.t("#{view_key}.new.header")
      assert page.title.include?(I18n.t("#{view_key}.new.title"))

      # Tag section
      tag_form_assertions

      # Resource section
      resource_form_assertions
    end

    def resource_form_assertions
    # Field labels
    @form_fields.each do |field|
      assert_text resource_class.human_attribute_name(field)
    end

    # Data fields
    @form_fields.each do |field|
      name = "#{@resource_class.model_name.param_key}[#{field}]"
      value = @resource.send(field)
      case field_types[field]
      when :enum
        assert_selector "select[name=#{name}]"
        if @resource.persisted?
          if I18n.exists?("activerecord.attributes.#{resource_class.model_name.i18n_key}.#{field.pluralize}.#{value}")
            assert_text resource_class.human_enum_name(field, value)
          else
            assert_text value
          end
        end
      when :float, :decimal
        assert_selector "input[type='number'][name=#{name}]"
        assert_text number_to_human(value, precision: 4, units: { unit: field == :speed_rated ? "rpm" : "" }).strip
      when :boolean
        assert_selector "input[type='checkbox'][name=#{name}]"
      when :date, :datetime
        assert_selector "input[type='datetime-local'][name='#{name}']"
        assert_text I18n.l(value, format: :default)
      when :text
        assert_selector "textarea[name=#{name}]"
        assert_text value
      else # string, text, integer, etc.
        assert_selector "input[type='text'][name=#{name}]"
        assert_text value
      end
    end

      # Form buttons
      assert_selector "button[type='submit']"
      assert_selector "a.btn.btn-warning", text: I18n.t('actions.discard')
    end

    test "accredited team member create new tag and new resource" do
      sign_in @accredited_team_member
      # Mock current_project for this test
      ApplicationController.any_instance.stubs(:current_project).returns(@project)
      visit motors_path
      click_link(href: new_motor_path)
      assert_current_path new_motor_path

      resource_form_assertions

      # Tag fields
      # Current project selection not working properly in test, so selector appears (should be hidden field)
      if has_selector?("select[name='motor[tag][project_id]']")
        select(@project.code, from: "motor[tag][project_id]")
      end
      fill_in "motor[tag][stage]", with: "3"
      fill_in "motor[tag][serial]", with: "5555"
      fill_in "motor[tag][suffix]", with: "HIGH"
      fill_in "motor[tag][service]", with: "TEST 5555"
      fill_in "motor[tag][notes]", with: "TAG NOTES"

      # motor fields
      fill_in_resource_fields

      # Submit the form data
      click_button I18n.t('actions.save')
      sleep 0.5  # Give database time to commit
      new_tag = Tag.find_by(prefix: "EM", serial: "5555", suffix: "HIGH")
      assert_current_path motor_path(new_tag.motor)
      assert_text "E:EM-5555.HIGH"
      assert_text I18n.t('flash.tagables.created_and_assigned',
                              resource_name: Motor.model_name.human,
                              id: new_tag.motor.id,
                              tag: new_tag.label)
    end

    test "accredited team member create new resource with existing tag" do
      sign_in @accredited_team_member
      # Mock current_project for this test
      ApplicationController.any_instance.stubs(:current_project).returns(@project)
      visit tag_path(@unassigned_tag)
      assert_current_path tag_path(@unassigned_tag)
      click_link(href: new_tag_motor_path(@unassigned_tag))
      assert_current_path new_tag_motor_path(@unassigned_tag)
      fill_in_resource_fields

      # Submit the form data
      click_button I18n.t('actions.save')
      sleep 0.5  # Give database time to commit
      assert_current_path motor_path(@unassigned_tag.reload.motor)
      assert_text @unassigned_tag.label
      assert_text I18n.t('flash.tagables.assigned_to',
                              resource_name: Motor.model_name.human,
                              id: @unassigned_tag.motor.id,
                              tag: @unassigned_tag.label)
    end

    def fill_in_resource_fields
      # motor fields
      select "4", from: 'ip_1', match: :first
      select "6", from: 'ip_2', match: :first
      select I18n.t("activerecord.attributes.motor.motor_types.induction"), from: "motor[motor_type]"
      select "200", from: "motor[frame_size]"
      fill_in "motor[poles]", with: "4"
      fill_in "motor[speed_rated]", with: "1500"
      fill_in "motor[notes]", with: "MOTOR NOTES"
    end

    test "accredited team member edit resource" do
      sign_in @accredited_team_member
      # Mock current_project for this test
      ApplicationController.any_instance.stubs(:current_project).returns(@project)
      visit motor_path(@resource)
      assert_current_path motor_path(@resource)
      click_link(href: edit_motor_path(@resource))
      assert_current_path edit_motor_path(@resource)
      assert_text I18n.t("motors.edit.header", label: @resource.label)
      assert page.title.include?(I18n.t("motors.edit.title"))

      # Tag collapsible card
      tag_card_assertions

      resource_form_assertions

      # Edit the data
      select I18n.t("activerecord.attributes.motor.motor_types.servo"), from: "motor[motor_type]"
      fill_in "motor[notes]", with: "REVISED FOR TEST"

      # Submit the form data
      click_button I18n.t('actions.update')
      sleep 0.5  # Give database time to commit
      @resource.reload
      assert_current_path motor_path(@resource)
      assert_text @resource.label
      assert_text "REVISED FOR TEST"
      assert_equal @resource.motor_type, "servo"
      assert_text I18n.t("flash.actions.update.notice", resource_name: Motor.model_name.human)

      # Make another edit to test the show view link, and then discard
      click_link(href: edit_motor_path(@resource))
      select I18n.t("activerecord.attributes.motor.motor_types.synchronous"), from: "motor[motor_type]"
      fill_in "motor[notes]", with: "REINSTATED FOR TEST"
      
      accept_confirm do
        click_link(text: I18n.t('actions.discard'))
      end
      assert_current_path motor_path(@resource)
      refute_equal @resource.motor_type, "synchronous"
      refute_text "REINSTATED FOR TEST"
    end

    test "admin destroy resource from the index view" do
      sign_in @admin
      # Mock current_project for this test
      ApplicationController.any_instance.stubs(:current_project).returns(@project)
      visit motors_path
      # Find the actual delete link and inspect its href
      accept_confirm do
        find("a[href='#{motor_path(@resource)}'][data-method='delete']").click
      end
      assert_current_path motors_path
      refute_selector "a[href='#{motor_path(@resource)}']"
      assert_text I18n.t("flash.actions.destroy.notice", resource_name: I18n.t("activerecord.models.motor"))
    end

    test "admin destroy resource from the show view" do
      sign_in @admin
      # Mock current_project for this test
      ApplicationController.any_instance.stubs(:current_project).returns(@project)
      visit motor_path(@resource)
      # Find the actual delete link and inspect its href
      accept_confirm do
        find("a[href='#{motor_path(@resource)}'][data-method='delete']").click
      end
      assert_current_path motors_path
      refute_selector "a[href='#{motor_path(@resource)}']"
      assert_text I18n.t("flash.actions.destroy.notice", resource_name: I18n.t("activerecord.models.motor"))
    end

  end
end