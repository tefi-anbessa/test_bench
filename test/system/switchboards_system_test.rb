require "application_system_test_case"

class SwitchboardsSystemTest < ApplicationSystemTestCase
  include Devise::Test::IntegrationHelpers
  include Warden::Test::Helpers

  setup do
    @user = create(:user)
    @project = create(:project)
    @discipline_b = create(:discipline, code: 'B')
    @discipline_e = create(:discipline, code: 'E')
    @discipline_j = create(:discipline, code: 'J')
    @discipline_p = create(:discipline, code: 'P')

    @app_owner = create(:user)
    @app_owner.grant(:app_owner)

    @admin = create(:user)
    @admin.grant(:admin)

    @project_manager = create(:user)
    @project_manager.grant(:project_manager, @project)

    @team_member = create(:user)
    @team_member.grant(:team_member, @project)

    @electrical_designer = create(:user)
    @electrical_designer.grant(:team_member, @project)
    @electrical_designer.grant(:electrical_designer)

    @regular_user = create(:user)

    #Switchboard
    @swbd_tag1 = create(:tag, project: @project, stage: '1', discipline: @discipline_e, 
      prefix: 'EX', serial: '1', suffix: "i", service: 'TEST SWITCHBOARD E:EX-0001.i', notes: "Lorem ipsum",
      tagable_type: "Switchboard")
    @switchboard1 = create(:switchboard, :with_circuits, location: "LOCATION 1", tag: @swbd_tag1,
                      ingress_protection: "IP44", voltage_rating: 3, busbar_rating: "100A", 
                      busbar_fault_rating: "100A", busbar_fault_duration: "1s",
                      cable_entry: "Top", incomer_protection: "Isolator 3P", metering: "Metering 3P",
                      neutral_bar_connections: "Neutral Bar Connections 3P", earth_bar_connections: "Earth Bar Connections 3P",
                      notes: "Lorem ipsum")
    @switchboard1.reload
    @circuit1 = @switchboard1.circuits.first
    @swbd_tag2 = create(:tag, project: @project, stage: '1', discipline: @discipline_e, 
      prefix: 'EX', serial: '2', suffix: "k", service: 'TEST SWITCHBOARD E:EX-0002.i', 
      notes: "Tag with no attached tagable", tagable_type: "Switchboard")
    @swbd_tag2.reload

    @cable_type1 = create(:cable_type, project: @project)
    @cable_type2 = create(:cable_type, csa: 4.0, project: @project)

    @cable_tag = create(:tag, project: @project, stage: '1', discipline: @discipline_e, 
      prefix: 'EC', serial: '1', suffix: "i", service: 'TEST CABLE E:EC-0001.i', notes: "Lorem ipsum",
      tagable_type: "Cable")
    @cable_tag.reload
    @cable = create(:cable, tag: @cable_tag, route_length: 55.5, vertical_allowance: 5.5,
                      termination_allowance: 1.5, start_mark: "154", end_mark: "42", 
                      notes: "test cable for electrical designer")
    # Set the current project for all tests that need it
    set_current_project(@project) if defined?(set_current_project)
    @cable_tag2 = create(:tag, project: @project, stage: '1', discipline: @discipline_e, 
      prefix: 'EC', serial: '2', suffix: "k", service: 'TEST CABLE E:EC-0002.k', notes: "Persisted tag",
      tagable_type: "Cable")
    @cable_tag2.reload
  end

  test "unauthenticated users should not see electrical drop down" do
    visit root_url
    refute_selector "#electrical-menu-btn"
  end

  test "team member viewing the switchboard index" do
    sign_in @team_member
    # Mock current_project for this test
    ApplicationController.any_instance.stubs(:current_project).returns(@project)
    visit root_url
    
    # Click the tag index link
    find("#electrical-menu-btn").click
    
    within "[aria-labelledby='electrical-menu-btn']" do
      assert_selector "a", text: I18n.t('switchboard', scope: 'activerecord.models').pluralize
      click_on I18n.t('switchboard', scope: 'activerecord.models').pluralize
    end
    assert_current_path switchboards_path
    assert_text I18n.t("switchboards.index.header")
    assert page.title.include?(I18n.t("switchboards.index.title"))

    # index search fields and headers
    assert_selector "input[name='q[location_cont]']"
    assert_selector "input[name='q[busbar_rating_cont]']"
    assert_selector "input[name='q[incomer_protection_cont]']"
    assert_selector "input[name='q[metering_cont]']"
    assert_text I18n.t('activerecord.models.tag')
    assert_selector "a[href*='q%5Bs%5D=location']"
    assert_selector "a[href*='q%5Bs%5D=ingress_protection']"
    assert_selector "a[href*='q%5Bs%5D=voltage_rating']"
    assert_selector "a[href*='q%5Bs%5D=busbar_rating']"
    assert_selector "a[href*='q%5Bs%5D=busbar_fault_rating']"
    assert_selector "a[href*='q%5Bs%5D=busbar_fault_duration']"
    assert_text I18n.t('activerecord.attributes.switchboard.circuits')

    assert_text @switchboard1.tag.label
    assert_text @switchboard1.location
    assert_text @switchboard1.ingress_protection
    assert_text @switchboard1.voltage_rating
    assert_text @switchboard1.busbar_rating
    assert_text @switchboard1.busbar_fault_rating
    assert_text @switchboard1.busbar_fault_duration
    assert_text @switchboard1.circuits.count
    assert_equal @switchboard1.circuits.count, 3 # Factory trait :with_circuits creates 3 circuits

    # Links
    assert_selector "a[href='#{switchboard_path(@switchboard1)}']"
    refute_selector "a[href='#{edit_switchboard_path(@switchboard1)}']" # team member cannot edit switchboard
    refute_selector "a[href='#{switchboard_path(@switchboard1)}'][data-method='delete']" # team member cannot delete switchboard
  end

  test "electrical designer viewing the switchboard index" do
    sign_in @electrical_designer
    # Mock current_project for this test
    ApplicationController.any_instance.stubs(:current_project).returns(@project)
    visit switchboards_path
    assert_current_path switchboards_path

    assert_selector "a[href='#{edit_switchboard_path(@switchboard1)}']" # electrical designer can edit switchboard
    refute_selector "a[href='#{switchboard_path(@switchboard1)}'][data-method='delete']" # electrical designer cannot delete switchboard
  end

  test "admin viewing the switchboard index" do
    sign_in @admin
    # Mock current_project for this test
    ApplicationController.any_instance.stubs(:current_project).returns(@project)
    visit switchboards_path
    assert_current_path switchboards_path

    assert_selector "a[href='#{switchboard_path(@switchboard1)}'][data-method='delete']" # admin can delete switchboard
  end

  test "team member viewing the switchboard show view" do
    sign_in @team_member
    # Mock current_project for this test
    ApplicationController.any_instance.stubs(:current_project).returns(@project)
    visit switchboards_path
    click_link(href: switchboard_path(@switchboard1))
    assert_current_path switchboard_path(@switchboard1)
    assert_text I18n.t("switchboards.show.header", label: @switchboard1.label)
    assert page.title.include?(I18n.t("switchboards.show.title"))

    # Header bar navigation links
    assert_selector "a[href='#{switchboards_path}']"# Link back to switchboards index
    refute_selector "a[href='#{edit_switchboard_path(@switchboard1)}']" # team member cannot edit switchboard
    refute_selector "a[href='#{switchboard_path(@switchboard1)}'][data-method='delete']" # team member cannot delete switchboard
    # [TODO] test prev and next buttons

    # Tag collapsible card
    assert_text I18n.t('activerecord.models.tag')
    assert_text @switchboard1.tag.full_tag

    # Field labels
    assert_text I18n.t('activerecord.attributes.switchboard.location')
    assert_text I18n.t('activerecord.attributes.switchboard.ingress_protection')
    assert_text I18n.t('activerecord.attributes.switchboard.voltage_rating')
    assert_text I18n.t('activerecord.attributes.switchboard.busbar_rating')
    assert_text I18n.t('activerecord.attributes.switchboard.busbar_fault_rating')
    assert_text I18n.t('activerecord.attributes.switchboard.busbar_fault_duration')
    assert_text I18n.t('activerecord.attributes.switchboard.cable_entry')
    assert_text I18n.t('activerecord.attributes.switchboard.incomer_protection')
    assert_text I18n.t('activerecord.attributes.switchboard.metering')
    assert_text I18n.t('activerecord.attributes.switchboard.neutral_bar_connections')
    assert_text I18n.t('activerecord.attributes.switchboard.earth_bar_connections')
    assert_text I18n.t('activerecord.attributes.switchboard.circuits')

    # Field data
    assert_text @switchboard1.location
    assert_text @switchboard1.ingress_protection
    assert_text @switchboard1.voltage_rating
    assert_text @switchboard1.busbar_rating
    assert_text @switchboard1.busbar_fault_rating
    assert_text @switchboard1.busbar_fault_duration
    assert_text @switchboard1.cable_entry
    assert_text @switchboard1.incomer_protection
    assert_text @switchboard1.metering
    assert_text @switchboard1.neutral_bar_connections
    assert_text @switchboard1.earth_bar_connections
    assert_text @switchboard1.circuits.count
  end

  test "electrical designer view the switchboard show view" do
    sign_in @electrical_designer
    # Mock current_project for this test
    ApplicationController.any_instance.stubs(:current_project).returns(@project)
    visit switchboards_path
    click_link(href: switchboard_path(@switchboard1))
    assert_current_path switchboard_path(@switchboard1)

    # Header bar navigation links
    assert_selector "a[href='#{edit_switchboard_path(@switchboard1)}']" # electrical designer can edit switchboard
    refute_selector "a[href='#{switchboard_path(@switchboard1)}'][data-method='delete']" # electrical designer cannot delete switchboard
  end

  test "admin view the switchboard show view" do
    sign_in @admin
    # Mock current_project for this test
    ApplicationController.any_instance.stubs(:current_project).returns(@project)
    visit switchboards_path
    find("a[href='#{switchboard_path(@switchboard1)}'][title=#{I18n.t('actions.show')}").click
    assert_current_path switchboard_path(@switchboard1)

    # Header bar navigation links
    assert_selector "a[href='#{edit_switchboard_path(@switchboard1)}']" # admin can edit switchboard
    assert_selector "a[href='#{switchboard_path(@switchboard1)}'][data-method='delete']" # admin can delete switchboard
  end

  test "electrical designer view the new tag and new switchboard form" do
    sign_in @electrical_designer
    # Mock current_project for this test
    ApplicationController.any_instance.stubs(:current_project).returns(@project)
    visit switchboards_path
    click_link(href: new_switchboard_path)
    assert_current_path new_switchboard_path
    assert_text I18n.t("switchboards.new.header")
    assert page.title.include?(I18n.t("switchboards.new.title"))

    # Data fields, tag section
    assert_selector "input[name='switchboard[tag][stage]']"
    assert_selector "select[name='switchboard[tag][discipline_id]']"
    assert_selector "input[name='switchboard[tag][serial]']"
    assert_selector "input[name='switchboard[tag][suffix]']"
    assert_selector "input[name='switchboard[tag][service]']"
    assert_selector "textarea[name='switchboard[tag][notes]']"
    assert_selector "select[name='switchboard[tag][tagable_type]']"

    # Data fields, switchboard section
    assert_selector "input[name='switchboard[location]']"
    assert_selector "select[name='ip_1']"
    assert_selector "select[name='ip_2']"
    assert_selector "input[name='switchboard[ingress_protection]']"
    assert_selector "select[name='switchboard[voltage_rating]']"
    assert_selector "input[name='switchboard[busbar_rating]']"
    assert_selector "input[name='switchboard[busbar_fault_rating]']"
    assert_selector "input[name='switchboard[busbar_fault_duration]']"
    assert_selector "input[name='switchboard[cable_entry]']"
    assert_selector "textarea[name='switchboard[incomer_protection]']"
    assert_selector "textarea[name='switchboard[metering]']"
    assert_selector "textarea[name='switchboard[neutral_bar_connections]']"
    assert_selector "textarea[name='switchboard[earth_bar_connections]']"
    assert_selector "textarea[name='switchboard[notes]']"
    assert_selector "input[name='circuits']"

    # Form buttons
    assert_selector "button[type='submit']"
    assert_selector "a.btn.btn-warning", text: I18n.t('actions.discard')
  end

  test "electrical designer create new tag and new switchboard" do
    sign_in @electrical_designer
    # Mock current_project for this test
    ApplicationController.any_instance.stubs(:current_project).returns(@project)
    visit switchboards_path
    click_link(href: new_switchboard_path)
    assert_current_path new_switchboard_path

    # Tag fields
    if has_selector?("select[name='switchboard[tag][project_id]']")
      select(@project.code, from: "switchboard[tag][project_id]")
    end
    fill_in "switchboard[tag][stage]", with: "3"
    fill_in "switchboard[tag][serial]", with: "5555"
    fill_in "switchboard[tag][suffix]", with: "HIGH"
    fill_in "switchboard[tag][service]", with: "TEST CABLE 5555"
    fill_in "switchboard[tag][notes]", with: "TAG NOTES NONSENSE"

    # Switchboard fields
    fill_in "switchboard[location]", with: "LOCATION TEST"
    select "4", from: 'ip_1', match: :first
    select "6", from: 'ip_2', match: :first
    select "300/500", from: "switchboard[voltage_rating]", match: :first
    fill_in "switchboard[busbar_rating]", with: "63"
    fill_in "switchboard[busbar_fault_rating]", with: "200"
    fill_in "switchboard[busbar_fault_duration]", with: "0.5"
    fill_in "switchboard[cable_entry]", with: "TOP"
    fill_in "switchboard[incomer_protection]", with: "Isolator 4P"
    fill_in "switchboard[metering]", with: "Metering 4P"
    fill_in "switchboard[neutral_bar_connections]", with: "Neutral Bar Connections 4P"
    fill_in "switchboard[earth_bar_connections]", with: "Earth Bar Connections 4P"
    fill_in "switchboard[notes]", with: "SWITCHBOARD NOTES 5555"
    fill_in "circuits", with: "2"

    # Submit the form data
    click_button I18n.t('actions.save')
    sleep 0.5  # Give database time to commit
    new_tag = Tag.find_by(prefix: "EX", serial: "5555", suffix: "HIGH")
    assert_current_path switchboard_path(new_tag.switchboard)
    assert_text "E:EX-5555.HIGH"
    assert_text I18n.t('flash.tagables.created_and_assigned',
                            resource_name: Switchboard.model_name.human,
                            id: new_tag.switchboard.id,
                            tag: new_tag.label)
  end

  test "electrical designer create new switchboard on existing tag" do
    sign_in @electrical_designer
    # Mock current_project for this test
    ApplicationController.any_instance.stubs(:current_project).returns(@project)
    visit tag_path(@swbd_tag2)
    click_link(href: new_tag_switchboard_path(@swbd_tag2))
    assert_current_path new_tag_switchboard_path(@swbd_tag2)
    assert_text I18n.t("switchboards.new.header")
    assert page.title.include?(I18n.t("switchboards.new.title"))

    # Tag collapsible card header
    assert_text @swbd_tag2.label

    # Switchboard fields
    fill_in "switchboard[location]", with: "LOCATION WEST"
    select "3", from: 'ip_1', match: :first
    select "5", from: 'ip_2', match: :first
    select "600/1000", from: "switchboard[voltage_rating]", match: :first
    fill_in "switchboard[busbar_rating]", with: "100"
    fill_in "switchboard[busbar_fault_rating]", with: "2000"
    fill_in "switchboard[busbar_fault_duration]", with: "1.0"
    fill_in "switchboard[cable_entry]", with: "SIDE"
    fill_in "switchboard[incomer_protection]", with: "Isolator 3P"
    fill_in "switchboard[metering]", with: "Metering 3P"
    fill_in "switchboard[neutral_bar_connections]", with: "Neutral Bar Connections 3P"
    fill_in "switchboard[earth_bar_connections]", with: "Earth Bar Connections 3P"
    fill_in "switchboard[notes]", with: "SWITCHBOARD NOTES EXISTING TAG"
    fill_in "circuits", with: "4"

    # Submit the form data
    click_button I18n.t('actions.save')
    sleep 0.5  # Give database time to commit
    @swbd_tag2.reload
    assert_current_path switchboard_path(@swbd_tag2.switchboard)
    assert_text "E:EX-0002.k"
    assert_text I18n.t('flash.tagables.assigned_to',
                        resource_name: Switchboard.model_name.human,
                        id: @swbd_tag2.switchboard.id,
                        tag: @swbd_tag2.label)
  end

  test "electrical designer edit switchboard" do
    sign_in @electrical_designer
    # Mock current_project for this test
    ApplicationController.any_instance.stubs(:current_project).returns(@project)
    visit switchboard_path(@switchboard1)
    click_link(href: edit_switchboard_path(@switchboard1))
    assert_current_path edit_switchboard_path(@switchboard1)
    assert_text I18n.t("switchboards.edit.header", label: @switchboard1.reload.label)
    assert page.title.include?(I18n.t("switchboards.edit.title"))

    # Tag collapsible card header
    assert_text @swbd_tag1.reload.label

    # Data fields, switchboard section
    assert_selector "input[name='switchboard[location]']"
    assert_selector "select[name='ip_1']"
    assert_selector "select[name='ip_2']"
    assert_selector "input[name='switchboard[ingress_protection]']"
    assert_selector "select[name='switchboard[voltage_rating]']"
    assert_selector "input[name='switchboard[busbar_rating]']"
    assert_selector "input[name='switchboard[busbar_fault_rating]']"
    assert_selector "input[name='switchboard[busbar_fault_duration]']"
    assert_selector "input[name='switchboard[cable_entry]']"
    assert_selector "textarea[name='switchboard[incomer_protection]']"
    assert_selector "textarea[name='switchboard[metering]']"
    assert_selector "textarea[name='switchboard[neutral_bar_connections]']"
    assert_selector "textarea[name='switchboard[earth_bar_connections]']"
    assert_selector "textarea[name='switchboard[notes]']"
    assert_selector "input[name='circuits']"

    # Edit the data
    find("select[name='switchboard[voltage_rating]'] option[value='300/500V']").select_option
    fill_in "switchboard[notes]", with: "REVISED FOR TEST"

    # Submit the form data
    click_button I18n.t('actions.save')
    sleep 0.5  # Give database time to commit
    @switchboard1.reload
    assert_current_path switchboard_path(@switchboard1)
    assert_text "E:EX-0001.i"
    assert_text "REVISED FOR TEST"
    assert_equal @switchboard1.voltage_rating, "300/500V"
    assert_text I18n.t("flash.actions.update.notice", resource_name: Switchboard.model_name.human)

    # Make another edit to test the show view link, and then discard
    click_link(href: edit_switchboard_path(@switchboard1))
    find("select[name='switchboard[voltage_rating]'] option[value='450/750V']").select_option
    fill_in "switchboard[notes]", with: "REINSTATED FOR TEST"
    
    accept_confirm do
      click_link(text: I18n.t('actions.discard'))
    end
    assert_current_path switchboard_path(@switchboard1)
    refute_equal @switchboard1.voltage_rating, "450/750V"
    refute_text "REINSTATED FOR TEST"
  end

  test "admin destroy switchboard from the index view" do
    sign_in @admin
    # Mock current_project for this test
    ApplicationController.any_instance.stubs(:current_project).returns(@project)
    visit switchboards_path
     # Find the actual delete link and inspect its href
    accept_confirm do
      find("a[href='#{switchboard_path(@switchboard1)}'][data-method='delete']").click
    end
    assert_current_path switchboards_path
    refute_selector "a[href='#{switchboard_path(@switchboard1)}']"
    assert_text I18n.t("flash.actions.destroy.notice", resource_name: I18n.t("activerecord.models.switchboard"))
  end

  test "admin destroy switchboard from the show view" do
    sign_in @admin
    # Mock current_project for this test
    ApplicationController.any_instance.stubs(:current_project).returns(@project)
    visit switchboard_path(@switchboard1)
     # Find the actual delete link and inspect its href
    accept_confirm do
      find("a[href='#{switchboard_path(@switchboard1)}'][data-method='delete']").click
    end
    assert_current_path switchboards_path
    refute_selector "a[href='#{switchboard_path(@switchboard1)}']"
    assert_text I18n.t("flash.actions.destroy.notice", resource_name: I18n.t("activerecord.models.switchboard"))
  end
end