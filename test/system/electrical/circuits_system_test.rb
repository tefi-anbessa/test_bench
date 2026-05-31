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

      # List fields that should appear in index. 
      @index_fields = %w[phase device poles curve rating elcb contactor]

      # List index fields that should have ransack search capability.
      @search_fields = %w[phase]

      # List all fields that should appear in show (usually all)
      @show_fields = [:phase, :device, :poles, :rating, :curve, :elcb, :contactor, :notes]

      # List all associations that should have a collapsible card on the show view
      @show_associations = [:switchboard, :feeder, :demand]

      # List all fields that should appear in forms (usually all).
      # New and edit required separately because some models have read only fields that can't be edited.
      # Set a valid value for each field if required to be unique, set nil for factory default.
      # Document model has its own way to ensure uniqueness by setting serial internally.
      @new_fields = {serial: @circuit.next_serial, phase: nil, device: nil, poles: nil, curve: nil, 
          elcb: nil, contactor: nil, notes: nil}
      @edit_fields = @new_fields
     
      # Rating is a float field with drop down options
      @model_special_cases =  [:rating] 
      @edit_attributes = { serial: 4 }
      @index_header = I18n.t("electrical.circuits.index.header", scope_text: @switchboard1.long_label)
      @index_title = I18n.t("electrical.circuits.index.title")
    end

    def fill_in_model_specific_fields
      find("select[name='electrical_circuit[rating]'] option[value='32']").select_option
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

      # Variable assertions
      assert_link href: electrical_switchboard_circuits_path(@switchboard1)
      assert_selector "a[href='#{electrical_switchboard_circuits_path(@switchboard1)}']"
      assert_selector "a[href='#{electrical_circuit_path(@circuit)}']"
      refute_selector "a[href='#{edit_electrical_circuit_path(@circuit)}']"
      refute_selector "a[href='#{electrical_circuit_path(@circuit)}'][data-method='delete']"
      # TODO CHECK PRE AND NEXT LINKS

    end

    test "accredited user viewing the circuit show view" do
      sign_in @accredited_user
      # Mock current_project for this test
      ApplicationController.any_instance.stubs(:current_project).returns(@project)
      visit electrical_circuit_path(@circuit)
      assert_current_path electrical_circuit_path(@circuit)

      # Variable assertions
      assert_selector "a[href='#{edit_electrical_circuit_path(@circuit)}']"
      refute_selector "a[href='#{electrical_circuit_path(@circuit)}'][data-method='delete']"
    end

    test "admin viewing the circuit show view" do
      sign_in @admin
      # Mock current_project for this test
      ApplicationController.any_instance.stubs(:current_project).returns(@project)
      visit electrical_circuit_path(@circuit)
      assert_current_path electrical_circuit_path(@circuit)

      # Header links and text
      assert_link href: electrical_switchboard_circuits_path(@switchboard1)
      assert_selector "a[href='#{edit_electrical_circuit_path(@circuit)}']"
      assert_selector "a[href='#{electrical_circuit_path(@circuit)}'][data-method='delete']"
    end

    test "accredited user viewing new circuit form" do
      sign_in @accredited_user
      # Mock current_project for this test
      ApplicationController.any_instance.stubs(:current_project).returns(@project)
      visit electrical_switchboard_circuits_path(@switchboard1)
      assert_current_path electrical_switchboard_circuits_path(@switchboard1)

      find("a[href='#{new_electrical_switchboard_circuit_path(@switchboard1)}']").click
      assert_current_path new_electrical_switchboard_circuit_path(@switchboard1)

      assert_text I18n.t("electrical.circuits.new.header", label: @switchboard1.label)
      assert_text @switchboard1.tag.service
      assert page.title.include?(I18n.t("electrical.circuits.new.title"))

      new_resource_form_assertions
    end

    test "accredited user create new circuit" do
      sign_in @accredited_user
      # Mock current_project for this test
      ApplicationController.any_instance.stubs(:current_project).returns(@project)
      visit new_electrical_switchboard_circuit_path(@switchboard1)
      assert_current_path new_electrical_switchboard_circuit_path(@switchboard1)
      saved_circuit = @new_fields[:serial]
      new_resource_form_assertions
      fill_in_resource_fields

      # Submit the form data
      click_button I18n.t('actions.create')
      sleep 2.0  # Give database time to commit

      new_circuit = Electrical::Circuit.find_by(electrical_switchboard_id: @switchboard1.id, serial: saved_circuit)
      assert_current_path electrical_circuit_path(new_circuit)
      assert @switchboard1.circuits.include?(new_circuit)
    end

    test "accredited user edit circuit" do
      sign_in @accredited_user
      # Mock current_project for this test
      ApplicationController.any_instance.stubs(:current_project).returns(@project)
      visit electrical_switchboard_circuits_path(@switchboard1)
      assert_current_path electrical_switchboard_circuits_path(@switchboard1)

      original = @circuit.dup
      find("a[href='#{edit_electrical_circuit_path(@circuit)}']").click
      assert_current_path edit_electrical_circuit_path(@circuit)

      # Header 
      assert_text I18n.t("electrical.circuits.edit.header", label: @circuit.long_label)
      assert page.title.include?(I18n.t("electrical.circuits.edit.title"))
      assert_text @circuit.switchboard.tag.service
      edit_resource_form_assertions

      # Edit the data (only implemented for text fields)
      @edit_attributes.each do |field, value|
        fill_in "#{resource_class.model_name.param_key}[#{field}]", with: value
      end

      # Submit form
      click_button I18n.t('actions.update')
      sleep 0.5  # Give database time to commit
      @circuit.reload
      assert_current_path electrical_circuit_path(@circuit)
      assert_text @circuit.label
      @edit_attributes.each do |field, value|
        assert_text value
        assert @circuit.send(field) == value
      end
                              
      # Make another edit to test the show view link, and then discard
      click_link(href: edit_electrical_circuit_path(@circuit))
      assert_current_path edit_electrical_circuit_path(@circuit)

      # Make an edit to resotore the original values
      @edit_attributes.each do |field, value|
        fill_in "#{resource_class.model_name.param_key}[#{field}]", with: original.send(field)
      end
      
      accept_confirm do
        click_link(text: I18n.t('actions.discard'))
      end
      assert_current_path electrical_circuit_path(@circuit)
      # Confirm no edits were made on the 2nd time
      @edit_attributes.each do |field, value|
        assert_text value
        assert @circuit.send(field) == value
      end
    end

    test "admin destroy circuit from the index view" do
      sign_in @admin
      # Mock current_project for this test
      ApplicationController.any_instance.stubs(:current_project).returns(@project)
      visit electrical_switchboard_circuits_path(@switchboard1)
      # Find the delete link and click it
      accept_confirm do
        find("a[href='#{electrical_circuit_path(@circuit)}'][data-method='delete']").click
      end
      assert_current_path electrical_switchboard_circuits_path(@switchboard1)
      refute_selector "a[href='#{electrical_circuit_path(@circuit)}']"
      assert_text I18n.t("flash.destroy.notice", resource_name: I18n.t("activerecord.models.electrical/circuit.one"))
    end

    test "admin destroy circuit from the show view" do
      sign_in @admin
      # Mock current_project for this test
      ApplicationController.any_instance.stubs(:current_project).returns(@project)
      visit electrical_circuit_path(@circuit)
      accept_confirm do
        find("a[href='#{electrical_circuit_path(@circuit)}'][data-method='delete']").click
      end
      assert_current_path electrical_switchboard_circuits_path(@switchboard1)
      refute_selector "a[href='#{electrical_circuit_path(@circuit)}']"
      assert_text I18n.t("flash.destroy.notice", resource_name: I18n.t("activerecord.models.electrical/circuit.one"))
    end
  end
end