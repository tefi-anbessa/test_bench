# frozen_string_literal: true
require "application_system_test_case"
require "helpers/system_test_helpers"
module Electrical
  class CircuitsSystemTest < ApplicationSystemTestCase
    include Devise::Test::IntegrationHelpers
    include Warden::Test::Helpers
    include SystemTestHelpers

    setup do
      setup_projects_and_users
      setup_disciplines(name: "Electrical", required_role: :designer)
      setup_accredited_users(role = :designer)
      setup_model_specific_data
    end

    def setup_model_specific_data

      # Switchboard with default 3 circuits
      @swbd1_tag = create(:tag, discipline: @discipline, stage: '1', 
        prefix: 'EX', serial: '1', suffix: "i", service: 'TEST SWITCHBOARD 1',
        tagable_type: "Electrical::Switchboard")
      @switchboard1 = create(:electrical_switchboard, :with_circuits, tag: @swbd1_tag,
                        ingress_protection: "IP44", voltage_rating: 3, busbar_rating: "100A", 
                        busbar_fault_rating: "200A", busbar_fault_duration: "1s",
                        cable_entry: "Top", incomer_protection: "Isolator 3P", metering: "Metering 3P",
                        neutral_bar_connections: "Neutral Bar Connections 3P", earth_bar_connections: "Earth Bar Connections 3P",
                        notes: "Lorem ipsum")

      # Circuit
      @circuit = @switchboard1.circuits.first
      @circuit.update(
            phase: "L1",
            device: "MCCB",
            poles: 4,
            curve: "C",
            rating: 32,
            elcb: "other",
            contactor: false,
            notes: "CIRCUIT NOTES"
            )
      @circuit.reload
      @resource = @circuit

      # Cable
      @cable_type = create(:electrical_cable_type, discipline: @discipline)
      @cable_tag = create(:tag, stage: '1', discipline: @discipline, 
        prefix: 'EC', serial: '1', service: 'TEST CABLE E:EC-0001',
        tagable_type: "Electrical::Cable")
      @cable = create(:electrical_cable, tag: @cable_tag, cable_type: @cable_type, route_length: 55.5, 
                        vertical_allowance: 5.5, termination_allowance: 1.5, 
                        start_mark: "154", end_mark: "42", 
                        notes: "cable for circuits system test")
      # Loads
      @swbd2_tag = create(:tag, stage: '1', discipline: @discipline, 
        prefix: 'EX', serial: '2', service: 'TEST SWITCHBOARD 2', tagable_type: "Electrical::Switchboard")
      @switchboard2 = create(:electrical_switchboard, tag: @swbd2_tag)
      @demand = create(:electrical_demand, 
        demandable: @switchboard2, basis: 'summation', basis_notes: 'Test basis notes 7', supply: 220.0,
        config: 'three_4c'
      )
      @circuit.update(feeder: @cable)
      @demand.update(incomer: @cable)

      @index_fields = %w[phase device poles curve rating elcb contactor]
      @search_fields = %w[phase]
      @show_fields = [:phase, :device, :poles, :curve, :rating, :elcb, :contactor, :notes]
      @new_fields = {serial: @circuit.serial.succ, phase: nil, device: nil, poles: nil, curve: nil, 
          rating: nil, elcb: nil, contactor: nil, notes: nil}
      @edit_fields = @new_fields
     
      @model_special_cases = { serial: nil  }
      @edit_attributes = { serial: 4 }
      @index_header = I18n.t("electrical.circuits.index.header", scope_text: @switchboard1.long_label)
      @index_title = I18n.t("electrical.circuits.index.title")
    end

    # Circuit tests

    test "team member show circuits schedule on existing switchboard" do
      sign_in @team_member
      # Mock current_project for this test
      ApplicationController.any_instance.stubs(:current_project).returns(@project)
      visit electrical_switchboard_path(@switchboard1)
      assert_current_path electrical_switchboard_path(@switchboard1)

      # Find the circuits link and click on it
      find("a[href='#{electrical_switchboard_circuits_path(@switchboard1)}']").click
      assert_current_path electrical_switchboard_circuits_path(@switchboard1)

      # Variable assertions
      refute_selector "a[href='#{new_electrical_switchboard_circuit_path(@switchboard1)}']"
      assert_selector "a[href='#{electrical_circuit_path(@circuit)}']"
      refute_selector "a[href='#{edit_electrical_circuit_path(@circuit)}']"
      refute_selector "a[href='#{electrical_circuit_path(@circuit)}'][data-method='delete']"

      index_assertions

      # Model specific assertions
      assert_text @circuit.long_label
      assert_selector "a[href*='q%5Bs%5D=serial']"
      # assert_selector "svg.bi.bi-check" if @circuit.contactor?
      assert_selector "a[href='#{electrical_cable_path(@circuit.feeder)}']" if @circuit.feeder.present?
      assert_selector "a[href='#{electrical_demand_path(@circuit.demand)}']" if @circuit.demand.present?
    end

    test "accredited user show circuits on existing switchboard" do
      sign_in @accredited_user
      # Mock current_project for this test
      ApplicationController.any_instance.stubs(:current_project).returns(@project)
      visit electrical_switchboard_circuits_path(@switchboard1)
      assert_current_path electrical_switchboard_circuits_path(@switchboard1)
      assert_selector "a[href='#{new_electrical_switchboard_circuit_path(@switchboard1)}']"
      assert_selector "a[href='#{electrical_circuit_path(@circuit)}']"
      assert_selector "a[href='#{edit_electrical_circuit_path(@circuit)}']"
      refute_selector "a[href='#{electrical_circuit_path(@circuit)}'][data-method='delete']"
    end

    test "admin show circuits on existing switchboard" do
      sign_in @admin
      # Mock current_project for this test
      ApplicationController.any_instance.stubs(:current_project).returns(@project)
      visit electrical_switchboard_circuits_path(@switchboard1)
      assert_current_path electrical_switchboard_circuits_path(@switchboard1)
      assert_selector "a[href='#{new_electrical_switchboard_circuit_path(@switchboard1)}']"
      assert_selector "a[href='#{electrical_circuit_path(@circuit)}']"
      assert_selector "a[href='#{edit_electrical_circuit_path(@circuit)}']"
      assert_selector "a[href='#{electrical_circuit_path(@circuit)}'][data-method='delete']"
    end

    test "team member show circuit" do
      sign_in @team_member
      # Mock current_project for this test
      ApplicationController.any_instance.stubs(:current_project).returns(@project)
      visit electrical_switchboard_path(@switchboard1)
      assert_current_path electrical_switchboard_path(@switchboard1)

      find("a[href='#{electrical_switchboard_circuits_path(@switchboard1)}']").click
      assert_current_path electrical_switchboard_circuits_path(@switchboard1)

      find("a[href='#{electrical_circuit_path(@circuit)}']").click
      assert_current_path electrical_circuit_path(@circuit)
      
      show_assertions
      assert_text I18n.t("activerecord.attributes.electrical.circuit.serial")

      # Variable assertions
      assert_selector "a[href='#{electrical_switchboard_circuits_path(@switchboard1)}']"
      refute_selector "a[href='#{electrical_circuit_path(@circuit1)}']"
      refute_selector "a[href='#{edit_electrical_circuit_path(@circuit1)}']"
      refute_selector "a[href='#{electrical_circuit_path(@circuit1)}'][data-method='delete']"
      # TODO CHECK PRE AND NEXT LINKS

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
end