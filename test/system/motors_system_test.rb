require "application_system_test_case"
require_relative "../support/tagable_system_test_patterns"

class MotorsSystemTest < ApplicationSystemTestCase
  include TagableSystemTestPatterns
  include Devise::Test::IntegrationHelpers
  include Warden::Test::Helpers

  setup do
    # Set E as the resource discipline for creating tags
    @resource_discipline = create(:discipline, code: 'E', name: "Electrical")
    setup_common_tagable_data
    setup_model_specific_data
  end

  def setup_model_specific_data
    # Motor
    # Setup user with edit permissions on motor resources
    @accredited_team_member = create(:user)
    @accredited_team_member.grant(:team_member, @project)
    @accredited_team_member.grant(:electrical_designer)

    # Set up an existing tag with associated resource for index, show, edit, update, destroy tests
    @assigned_tag = create(:tag, prefix: 'PM', serial: 1001, project: @project, 
                            discipline: @resource_discipline)
    @resource = create(:motor, tag: @assigned_tag)
    @resource.reload
    # Set up an unassigned tag for create and update tests
    @unassigned_tag = create(:tag, prefix: 'PM', serial: 1002, project: @project, 
                              discipline: @resource_discipline, tagable_type: "Motor")
    @unassigned_tag.reload
  end

  test "unauthenticated users" do
    visit root_url
    refute_selector "#electrical-menu-btn"
  end

  test "team member navigating to index" do
    sign_in @team_member
    # Mock current_project for this test
    ApplicationController.any_instance.stubs(:current_project).returns(@project)
    visit root_url
    # Click the electrical drop down link
    find("#electrical-menu-btn").click
    
    within "[aria-labelledby='electrical-menu-btn']" do
      assert_selector "a", text: I18n.t('motor', scope: 'activerecord.models').pluralize
      click_on I18n.t('motor', scope: 'activerecord.models').pluralize
    end
    assert_current_path motors_path
    index_assertions
    refute_selector "a[href='#{new_motor_path}']" # Link to new motor
    assert_selector "a[href='#{motor_path(@resource)}']" # Link to motor show view
    refute_selector "a[href='#{edit_motor_path(@resource)}']" # team member cannot edit motor
    refute_selector "a[href='#{motor_path(@resource)}'][data-method='delete']" # team member cannot delete motor
  end

  test "accredited team member view index" do
    sign_in @accredited_team_member
    # Mock current_project for this test
    ApplicationController.any_instance.stubs(:current_project).returns(@project)
    visit motors_path
    assert_current_path motors_path
    # Links
    assert_selector "a[href='#{new_motor_path}']" # Link to new motor
    assert_selector "a[href='#{motor_path(@resource)}']" # Link to motor show view
    assert_selector "a[href='#{edit_motor_path(@resource)}']" # accredited team member can edit motor
    refute_selector "a[href='#{motor_path(@resource)}'][data-method='delete']" # accredited team member cannot delete motor
  end

  test "admin view index" do
    sign_in @admin
    # Mock current_project for this test
    ApplicationController.any_instance.stubs(:current_project).returns(@project)
    visit motors_path
    assert_current_path motors_path
    # Links
    assert_selector "a[href='#{new_motor_path}']" # Link to new motor
    assert_selector "a[href='#{motor_path(@resource)}']" # Link to motor show view
    assert_selector "a[href='#{edit_motor_path(@resource)}']" # accredited team member can edit motor
    assert_selector "a[href='#{motor_path(@resource)}'][data-method='delete']" # admin can delete motor
  end

  def index_assertions
    assert_text I18n.t("motors.index.header")
    assert page.title.include?(I18n.t("motors.index.title"))

    # Ransack search fields
    assert_selector "input[name='q[motor_type_cont]']"
    assert_selector "input[name='q[frame_size_cont]']"
    assert_selector "input[name='q[ingress_protection_cont]']"

    # Text headers
    assert_text I18n.t('activerecord.models.tag')
    # Ransack sort headers
    assert_selector "a[href*='q%5Bs%5D=motor_type']"
    assert_selector "a[href*='q%5Bs%5D=frame_size']"
    assert_selector "a[href*='q%5Bs%5D=ingress_protection']"
    
    # Data
    assert_text @resource.motor_type
    assert_text @resource.frame_size
    assert_text @resource.ingress_protection
    assert_text @resource.poles
    assert_text @resource.speed_rated
  end

  test "team member navigating to the resource show view" do
    sign_in @team_member
    # Mock current_project for this test
    ApplicationController.any_instance.stubs(:current_project).returns(@project)
    visit motors_path
    click_link(href: motor_path(@resource))
    assert_current_path motor_path(@resource)

    # Header bar navigation links
    assert_selector "a[href='#{motors_path}']"# Link back to motors index
    refute_selector "a[href='#{edit_motor_path(@resource)}']" # team member cannot edit motor
    refute_selector "a[href='#{motor_path(@resource)}'][data-method='delete']" # team member cannot delete motor
    # [TODO] test prev and next buttons
    show_assertions
  end

  test "accredited team member viewing the resource show view" do
    sign_in @accredited_team_member
    # Mock current_project for this test
    ApplicationController.any_instance.stubs(:current_project).returns(@project)
    visit motor_path(@resource)
    assert_current_path motor_path(@resource)

    # Header bar navigation links
    assert_selector "a[href='#{motors_path}']"# Link back to motors index
    assert_selector "a[href='#{edit_motor_path(@resource)}']" # accredited team member can edit motor
    refute_selector "a[href='#{motor_path(@resource)}'][data-method='delete']" # team member cannot delete motor
    # [TODO] test prev and next buttons
  end

  test "admin viewing the resource show view" do
    sign_in @admin
    # Mock current_project for this test
    ApplicationController.any_instance.stubs(:current_project).returns(@project)
    visit motor_path(@resource)
    assert_current_path motor_path(@resource)

    # Header bar navigation links
    assert_selector "a[href='#{motors_path}']"# Link back to motors index
    assert_selector "a[href='#{edit_motor_path(@resource)}']" # admin can edit motor
    assert_selector "a[href='#{motor_path(@resource)}'][data-method='delete']" # admin can delete motor
    # [TODO] test prev and next buttons
  end

  def show_assertions
    assert_text I18n.t("motors.show.header", label: @resource.label)
    assert page.title.include?(I18n.t("motors.show.title"))

    # Tag collapsible card
    tag_card_assertions

    # Field labels
    assert_text I18n.t('activerecord.attributes.motor.motor_type')
    assert_text I18n.t('activerecord.attributes.motor.frame_size')
    assert_text I18n.t('activerecord.attributes.motor.ingress_protection')
    assert_text I18n.t('activerecord.attributes.motor.poles')
    assert_text I18n.t('activerecord.attributes.motor.speed_rated')
    assert_text I18n.t('activerecord.attributes.motor.notes')

    # Field data
    assert_text Motor.human_enum_name(:motor_type, @resource.motor_type)
    assert_text "frame_#{@resource.frame_size}"
    assert_text @resource.ingress_protection
    assert_text @resource.poles
    assert_text @resource.speed_rated
    assert_text @resource.notes
  end

  def tag_card_assertions
    # Tag collapsible card
    assert_text I18n.t('activerecord.models.tag')
    assert_text @resource.tag.label
  end

  test "accredited team member navigate to the new tag and new resource form" do
    sign_in @accredited_team_member
    # Mock current_project for this test
    ApplicationController.any_instance.stubs(:current_project).returns(@project)
    visit motors_path
    click_link(href: new_motor_path)
    assert_current_path new_motor_path
    assert_text I18n.t("motors.new.header")
    assert page.title.include?(I18n.t("motors.new.title"))

    # Tag section
    tag_form_assertions
    resource_tag_form_assertions

    # Resource section
    resource_form_assertions
  end

  def resource_tag_form_assertions
    #resource specific tag fields
    assert_text @resource_discipline.name # Should have i18n translation.
  end

  def resource_form_assertions
    # Field labels
    assert_text I18n.t('activerecord.attributes.motor.motor_type')
    assert_text I18n.t('activerecord.attributes.motor.frame_size')
    assert_text I18n.t('activerecord.attributes.motor.ingress_protection')
    assert_text I18n.t('activerecord.attributes.motor.poles')
    assert_text I18n.t('activerecord.attributes.motor.speed_rated')
    assert_text I18n.t('activerecord.attributes.motor.notes')

    # Field data
    assert_selector "select[name='motor[motor_type]']"
    assert_selector "select[name='motor[frame_size]']"
    assert_selector "input[name='motor[ingress_protection]']"
    assert_selector "select[name='ip_1']"
    assert_selector "select[name='ip_2']"
    assert_selector "input[name='motor[poles]']"
    assert_selector "input[name='motor[speed_rated]']"
    assert_selector "textarea[name='motor[notes]']"

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