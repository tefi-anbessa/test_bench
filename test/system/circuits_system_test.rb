require "application_system_test_case"

class CircuitsSystemTest < ApplicationSystemTestCase
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

    # Switchboard with default 3 circuits
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

    # Circuit
    @circuit1 = @switchboard1.circuits.first
    @circuit1.update(
          phase: "L1",
          device: "MCCB",
          poles: 4,
          curve: "C",
          rating: 32,
          elcb: "other",
          contactor: false,
          notes: "CIRCUIT NOTES"
          )
    @circuit1.reload

    # Cable
    @cable_type = create(:cable_type, project: @project)
    @cable_tag = create(:tag, project: @project, stage: '1', discipline: @discipline_e, 
      prefix: 'EC', serial: '1', suffix: "i", service: 'TEST CABLE E:EC-0001.i', notes: "Lorem ipsum",
      tagable_type: "Cable")
    @cable_tag.reload
    @cable = create(:cable, tag: @cable_tag, cable_type: @cable_type, route_length: 55.5, 
                      vertical_allowance: 5.5, termination_allowance: 1.5, 
                      start_mark: "154", end_mark: "42", 
                      notes: "cable for circuits test")
    # Load
    @swbd_tag2 = create(:tag, project: @project, stage: '1', discipline: @discipline_e, 
      prefix: 'EX', serial: '2', suffix: "k", service: 'TEST SWITCHBOARD E:EX-0002.i', 
      notes: "Tag with no attached tagable", tagable_type: "Switchboard")
    @swbd_tag2.reload
    @swbd2 = create(:switchboard, tag: @swbd_tag2)
    @demand = create(:demand, 
      demandable: @swbd2, basis: 'summation', basis_notes: 'Test basis notes 7', supply: 220.0,
      config: 'three_4c'
    )
    @circuit1.feeder = @cable
    @demand.incomer= @cable

    # Set the current project for all tests that need it
    set_current_project(@project) if defined?(set_current_project)
  end
                        
  test "unauthenticated users should not see electrical drop down" do
    visit root_url
    refute_selector "#electrical-menu-btn"
  end

  # Circuit tests

  test "team member show circuits schedule on existing switchboard" do
    sign_in @team_member
    # Mock current_project for this test
    ApplicationController.any_instance.stubs(:current_project).returns(@project)
    visit switchboard_path(@switchboard1)
    assert_current_path switchboard_path(@switchboard1)

    # Find the circuits link and click on it
    find("a[href='#{switchboard_circuits_path(@switchboard1)}']").click
    assert_current_path switchboard_circuits_path(@switchboard1)
    assert_text I18n.t("circuits.index.header", label: @switchboard1.reload.label)
    assert page.title.include?(I18n.t("circuits.index.title"))
    refute_selector "a[href='#{new_switchboard_circuit_path(@switchboard1)}']"

    # Header fields - presently no ransack sort
    assert_text I18n.t("activerecord.attributes.circuit.phase")
    assert_text I18n.t("activerecord.attributes.circuit.device")
    assert_text I18n.t("activerecord.attributes.circuit.poles")
    assert_text I18n.t("activerecord.attributes.circuit.curve")
    assert_text I18n.t("activerecord.attributes.circuit.rating")
    assert_text I18n.t("activerecord.attributes.circuit.elcb")
    assert_text I18n.t("activerecord.attributes.circuit.contactor")
    assert_text I18n.t("activerecord.attributes.circuit.feeder")
    assert_text I18n.t("activerecord.attributes.circuit.demand")
    assert_text I18n.t('table.links')

# Data fields
    assert_text @circuit1.label
    assert_text @circuit1.phase
    assert_text @circuit1.device
    assert_text @circuit1.poles
    assert_text @circuit1.curve
    assert_text @circuit1.rating
    assert_text @circuit1.elcb
    assert_selector "svg.bi.bi-check" if @circuit1.contactor?
    assert_selector "a[href='#{cable_path(@circuit1.feeder)}']" if @circuit1.feeder.present?
    assert_selector "a[href='#{demand_path(@circuit1.demand)}']" if @circuit1.demand.present?
    assert_selector "a[href='#{circuit_path(@circuit1)}']"
    refute_selector "a[href='#{edit_circuit_path(@circuit1)}']"
    refute_selector "a[href='#{circuit_path(@circuit1)}'][data-method='delete']"
  end

  test "electrical designer show circuits on existing switchboard" do
    sign_in @electrical_designer
    # Mock current_project for this test
    ApplicationController.any_instance.stubs(:current_project).returns(@project)
    visit switchboard_circuits_path(@switchboard1)
    assert_current_path switchboard_circuits_path(@switchboard1)
    assert_selector "a[href='#{new_switchboard_circuit_path(@switchboard1)}']"
    assert_selector "a[href='#{circuit_path(@circuit1)}']"
    assert_selector "a[href='#{edit_circuit_path(@circuit1)}']"
    refute_selector "a[href='#{circuit_path(@circuit1)}'][data-method='delete']"
  end

  test "admin show circuits on existing switchboard" do
    sign_in @admin
    # Mock current_project for this test
    ApplicationController.any_instance.stubs(:current_project).returns(@project)
    visit switchboard_circuits_path(@switchboard1)
    assert_current_path switchboard_circuits_path(@switchboard1)
    assert_selector "a[href='#{new_switchboard_circuit_path(@switchboard1)}']"
    assert_selector "a[href='#{circuit_path(@circuit1)}']"
    assert_selector "a[href='#{edit_circuit_path(@circuit1)}']"
    assert_selector "a[href='#{circuit_path(@circuit1)}'][data-method='delete']"
  end

  test "team member show circuit" do
    sign_in @team_member
    # Mock current_project for this test
    ApplicationController.any_instance.stubs(:current_project).returns(@project)
    visit switchboards_path
    click_link(href: switchboard_path(@switchboard1))
    assert_current_path switchboard_path(@switchboard1)
    find("a[href='#{switchboard_circuits_path(@switchboard1)}']").click
    assert_current_path switchboard_circuits_path(@switchboard1)
    find("a[href='#{circuit_path(@circuit1)}']").click
    assert_current_path circuit_path(@circuit1)
    assert page.title.include?(I18n.t("circuits.show.title"))

    # Header links and text
    assert_selector "a[href='#{switchboard_circuits_path(@switchboard1)}']"
    circuit_label = [@circuit1.switchboard&.label, @circuit1.label].join(': ')
    assert_selector "span.badge", text: /#{I18n.t("circuits.show.header", label: circuit_label)}/
    assert_text @circuit1.switchboard.tag.service
    refute_selector "a[href='#{edit_circuit_path(@circuit1)}']"
    refute_selector "a[href='#{circuit_path(@circuit1)}'][data-method='delete']"
    # TODO CHECK PRE AND NEXT LINKS

    # Switchboard collapsible card
    assert_text @circuit1.switchboard.label

    # Circuit card labels
    assert_text I18n.t("activerecord.attributes.circuit.serial")
    assert_text I18n.t("activerecord.attributes.circuit.phase")
    assert_text I18n.t("activerecord.attributes.circuit.device")
    assert_text I18n.t("activerecord.attributes.circuit.poles")
    assert_text I18n.t("activerecord.attributes.circuit.curve")
    assert_text I18n.t("activerecord.attributes.circuit.rating")
    assert_text I18n.t("activerecord.attributes.circuit.elcb")
    assert_text I18n.t("activerecord.attributes.circuit.contactor")
    assert_text I18n.t("activerecord.attributes.circuit.feeder")
    assert_text I18n.t("activerecord.attributes.circuit.demand")
    assert_text I18n.t("activerecord.attributes.circuit.notes")
    assert_text I18n.t("activerecord.attributes.circuit.feeder")
    assert_text I18n.t("activerecord.attributes.circuit.demand")

    # Circuit card fields
    assert_text @circuit1.serial
    assert_text @circuit1.phase
    assert_text @circuit1.device
    assert_text @circuit1.poles
    assert_text @circuit1.curve
    assert_text @circuit1.rating
    assert_text @circuit1.elcb
    assert_text @circuit1.contactor ? t("form.true") : '-'
    assert_text @circuit1.feeder.label if @circuit1.feeder.present?
    assert_text @circuit1.demand.label if @circuit1.demand.present?
    assert_text @circuit1.notes
  end

  test "electrical designer viewing the circuit show view" do
    sign_in @electrical_designer
    # Mock current_project for this test
    ApplicationController.any_instance.stubs(:current_project).returns(@project)
    visit circuit_path(@circuit1)
    assert_current_path circuit_path(@circuit1)

    # Header links and text
    assert_selector "a[href='#{edit_circuit_path(@circuit1)}']"
    refute_selector "a[href='#{circuit_path(@circuit1)}'][data-method='delete']"
  end

  test "admin viewing the circuit show view" do
    sign_in @admin
    # Mock current_project for this test
    ApplicationController.any_instance.stubs(:current_project).returns(@project)
    visit circuit_path(@circuit1)
    assert_current_path circuit_path(@circuit1)

    # Header links and text
    assert_selector "a[href='#{edit_circuit_path(@circuit1)}']"
    assert_selector "a[href='#{circuit_path(@circuit1)}'][data-method='delete']"
  end

  test "electrical designer viewing new circuit form" do
    sign_in @electrical_designer
    # Mock current_project for this test
    ApplicationController.any_instance.stubs(:current_project).returns(@project)
    visit switchboard_circuits_path(@switchboard1)
    assert_current_path switchboard_circuits_path(@switchboard1)
    find("a[href='#{new_switchboard_circuit_path(@switchboard1)}']").click
    assert_current_path new_switchboard_circuit_path(@switchboard1)
    assert_text I18n.t("circuits.new.header", label: @switchboard1.label)
    assert_text @switchboard1.tag.service
    assert page.title.include?(I18n.t("circuits.new.title"))

    # Circuit form labels
    assert_text I18n.t("activerecord.attributes.circuit.serial")
    assert_text I18n.t("activerecord.attributes.circuit.phase")
    assert_text I18n.t("activerecord.attributes.circuit.device")
    assert_text I18n.t("activerecord.attributes.circuit.poles")
    assert_text I18n.t("activerecord.attributes.circuit.curve")
    assert_text I18n.t("activerecord.attributes.circuit.rating")
    assert_text I18n.t("activerecord.attributes.circuit.elcb")
    assert_text I18n.t("activerecord.attributes.circuit.contactor")
    assert_text I18n.t("activerecord.attributes.circuit.notes")

    # Circuit form fields
    assert_selector "input[name='circuit[serial]']"
    assert_selector "select[name='circuit[phase]']"
    assert_selector "select[name='circuit[device]']"
    assert_selector "select[name='circuit[poles]']"
    assert_selector "select[name='circuit[curve]']"
    assert_selector "select[name='circuit[rating]']"
    assert_selector "select[name='circuit[elcb]']"
    assert_selector "input[name='circuit[contactor]'][type='checkbox']"
    assert_selector "textarea[name='circuit[notes]']"

    # Form buttons
    assert_selector "button[type='submit']"
    assert_selector "a.btn.btn-warning", text: I18n.t('actions.discard')
  end

  test "electrical designer create new circuit" do
    sign_in @electrical_designer
    # Mock current_project for this test
    ApplicationController.any_instance.stubs(:current_project).returns(@project)
    visit new_switchboard_circuit_path(@switchboard1)
    assert_current_path new_switchboard_circuit_path(@switchboard1)
    next_circuit = @switchboard1.circuits.count + 1

    # Fill in form details
    fill_in "circuit[serial]", with: next_circuit
    select "L1", from: "circuit[phase]"
    select "MCB", from: "circuit[device]"
    select "2", from: "circuit[poles]"
    select "B", from: "circuit[curve]"
    select "6", from: "circuit[rating]"
    select "30mA", from: "circuit[elcb]"
    check "circuit[contactor]"
    fill_in "circuit[notes]", with: "CIRCUIT NOTES NONSENSE"

    # Submit form
    click_button I18n.t('actions.save')
    sleep 0.5  # Give database time to commit
    new_circuit = Circuit.find_by(switchboard: @switchboard1, serial: next_circuit)
    circuit_label = [new_circuit.switchboard&.label, new_circuit.label].join(': ')
    assert_current_path circuit_path(new_circuit)
    assert_selector "span.badge", text: /#{circuit_label}/
    assert_text I18n.t('flash.actions.create.notice',
                            resource_name: Circuit.model_name.human)

    # Circuit card fields
    assert_text next_circuit
    assert_text "L1"
    assert_text "MCB"
    assert_text "2"
    assert_text "B"
    assert_text "6"
    assert_text "30mA"
    assert_text I18n.t("form.true")
    assert_text "CIRCUIT NOTES NONSENSE"
  end

  test "electrical designer edit circuit" do
    sign_in @electrical_designer
    # Mock current_project for this test
    ApplicationController.any_instance.stubs(:current_project).returns(@project)
    visit switchboard_circuits_path(@switchboard1)
    assert_current_path switchboard_circuits_path(@switchboard1)
    find("a[href='#{edit_circuit_path(@circuit1)}']").click
    assert_current_path edit_circuit_path(@circuit1)

    # Header 
    circuit_label = [@circuit1.switchboard&.label, @circuit1.label].join(': ')
    assert page.title.include?(I18n.t("circuits.edit.title"))
    assert_text I18n.t("circuits.edit.header", label: circuit_label)
    assert_text @circuit1.switchboard.tag.service
    next_circuit = @switchboard1.circuits.count + 1

    # Fill in form details
    fill_in "circuit[serial]", with: next_circuit
    select "L2", from: "circuit[phase]"
    select "MCCB", from: "circuit[device]"
    select "4", from: "circuit[poles]"
    select "C", from: "circuit[curve]"
    select "32", from: "circuit[rating]"
    select "other", from: "circuit[elcb]"
    uncheck "circuit[contactor]"
    fill_in "circuit[notes]", with: "CIRCUIT NOTES EDIT"

    # Submit form
    click_button I18n.t('actions.save')
    sleep 0.5  # Give database time to commit
    @circuit1.reload
    assert_current_path circuit_path(@circuit1)
    assert_text next_circuit
    assert_text "L2"
    assert_text "MCCB"
    assert_text "4"
    assert_text "C"
    assert_text "32"
    assert_text "other"
    refute_text I18n.t("form.true")
    assert_text "CIRCUIT NOTES EDIT"
    assert_text I18n.t('flash.actions.update.notice',
                            resource_name: Circuit.model_name.human)
                            
    # Make another edit to test the show view link, and then discard
    click_link(href: edit_circuit_path(@circuit1))
    assert_current_path edit_circuit_path(@circuit1)

    # Make an edit
    fill_in "circuit[notes]", with: "CIRCUIT NOTES REVERT"
    
    accept_confirm do
      click_link(text: I18n.t('actions.discard'))
    end
    assert_current_path circuit_path(@circuit1)
    refute_text "CIRCUIT NOTES REVERT"
  end

  test "admin destroy circuit from the index view" do
    sign_in @admin
    # Mock current_project for this test
    ApplicationController.any_instance.stubs(:current_project).returns(@project)
    visit switchboard_circuits_path(@switchboard1)
     # Find the delete link and click it
    accept_confirm do
      find("a[href='#{circuit_path(@circuit1)}'][data-method='delete']").click
    end
    assert_current_path switchboard_circuits_path(@switchboard1)
    refute_selector "a[href='#{circuit_path(@circuit1)}']"
    assert_text I18n.t("flash.actions.destroy.notice", resource_name: I18n.t("activerecord.models.circuit"))
  end

  test "admin destroy circuit from the show view" do
    sign_in @admin
    # Mock current_project for this test
    ApplicationController.any_instance.stubs(:current_project).returns(@project)
    visit circuit_path(@circuit1)
    accept_confirm do
      find("a[href='#{circuit_path(@circuit1)}'][data-method='delete']").click
    end
    assert_current_path switchboard_circuits_path(@switchboard1)
    refute_selector "a[href='#{circuit_path(@circuit1)}']"
    assert_text I18n.t("flash.actions.destroy.notice", resource_name: I18n.t("activerecord.models.circuit"))
  end
end