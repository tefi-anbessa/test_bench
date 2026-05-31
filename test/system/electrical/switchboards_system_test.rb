# frozen_string_literal: true
# 
require "application_system_test_case"
require "helpers/tagable_system_tests"
module Electrical
  class SwitchboardsSystemTest < ApplicationSystemTestCase
    include Devise::Test::IntegrationHelpers
    include Warden::Test::Helpers
    include TagableSystemTests

    setup do
      setup_common_tagable_data
      setup_model_specific_data
    end

    def setup_model_specific_data
      # Set prefix to one of the options available on the selector for the discipline prefix schema.
      @tag.update(prefix: "EX")
      @tag.reload
      @unassigned_tag.update(prefix: "EX")
      @unassigned_tag.reload
      @switchboard1_tag = create(:tag, project: @project, stage: '1', discipline: @discipline, 
        prefix: 'EX', serial: '1', suffix: "i", service: 'TEST SWITCHBOARD E:EX-0001.i', notes: "Lorem ipsum",
        tagable_type: "Electrical::Switchboard")
      @switchboard1 = create(:electrical_switchboard, :with_circuits, tag: @switchboard1_tag,
                        ingress_protection: "IP44", voltage_rating: 3, busbar_rating: "100A", 
                        busbar_fault_rating: "100A", busbar_fault_duration: "1s",
                        cable_entry: "Top", incomer_protection: "Isolator 3P", metering: "Metering 3P",
                        neutral_bar_connections: "Neutral Bar Connections 3P", earth_bar_connections: "Earth Bar Connections 3P",
                        notes: "Lorem ipsum")
      @circuit1 = @switchboard1.circuits.first
      @switchboard2_tag = create(:tag, project: @project, stage: '1', discipline: @discipline, 
        prefix: 'EX', serial: '2', suffix: "k", service: 'TEST SWITCHBOARD E:EX-0002.i', 
        notes: "Tag with no attached tagable", tagable_type: "Electrical::Switchboard")

      @cable_type1 = create(:electrical_cable_type, discipline: @discipline)
      @cable_type2 = create(:electrical_cable_type, csa: 4.0, discipline: @discipline)

      @cable_tag = create(:tag, project: @project, stage: '1', discipline: @discipline, 
        prefix: 'EC', serial: '1', suffix: "i", service: 'TEST FEEDER', notes: "",
        tagable_type: "Electrical::Cable")
      @cable = create(:electrical_cable, tag: @cable_tag, route_length: 55.5, vertical_allowance: 5.5,
                        termination_allowance: 1.5, start_mark: "154", end_mark: "42", 
                        notes: "test cable for switchboard system test")
      # List fields that should appear in index. 
      # The generator will include test for sort link header for each column, 
      # and try to find an appropriate value field for the type.
      @index_fields = [:ingress_protection, :voltage_rating,
          :busbar_rating, :busbar_fault_rating, :busbar_fault_duration]

      # List index fields that should have ransack search capability.
      # The generator will only test for "contains" fields (_cont).
      # Don't include numeric or date fields, add model specific tests for these later in this file.
      @search_fields = [:voltage_rating, :busbar_rating, :incomer_protection, :metering, :notes]

      # List all fields that should appear in show (usually all)
      @show_fields = [:ingress_protection, :voltage_rating,
          :busbar_rating, :busbar_fault_rating, :busbar_fault_duration, 
          :cable_entry, :incomer_protection, :metering, 
          :neutral_bar_connections, :earth_bar_connections, :notes]

      # List all associations that should have a collapsible card on the show view
      @show_associations = [:tag]

      # List all fields that should appear in forms (usually all).
      # New and edit required separately because some models have read only fields that can't be edited.
      # Set a valid value for each field if required to be unique, set nil for factory default.
      # Document model has its own way to ensure uniqueness by setting serial internally.
      @new_fields = {busbar_rating: nil, 
        busbar_fault_rating: nil, busbar_fault_duration: nil, cable_entry: nil, incomer_protection: nil, 
        metering: nil, neutral_bar_connections: nil, earth_bar_connections: nil, notes: nil}
      @edit_fields = @new_fields

      # Set an attribute/s to be modified in edit test
      # Only working with string/text fields at present
      @edit_attributes = { incomer_protection: "None" }
      @model_special_cases = { ingress_protection: nil, voltage_rating: nil }
    end

    def fill_in_model_specific_fields
      find("select[name='ip_1'] option[value='1']").select_option
      find("select[name='ip_2'] option[value='1']").select_option
      find("select[name='electrical_switchboard[voltage_rating]'] option[value='#{@resource.voltage_rating}']").select_option
    end

    test "accredited user create tag and switchboard with circuits" do
      sign_in @accredited_user
      # Mock current_project for this test
      ApplicationController.any_instance.stubs(:current_project).returns(@project)

      visit new_discipline_resource_path(@discipline)
      assert_current_path new_discipline_resource_path(@discipline)

      fill_in_tag_fields
      fill_in_resource_fields
      fill_in "circuits", with: 5

      # Submit the form data
      click_button I18n.t('actions.create')
      sleep 1.0  # Give database time to commit
      # Form data uses @tag as a template, serial increased + 1.
      new_tag = Tag.find_by(discipline: @discipline,
        prefix: @saved_prefix, 
        serial: @saved_serial,
        suffix: @tag.suffix)
      assert_current_path resource_path(new_tag.tagable)
      assert_equal new_tag.tagable.class, resource_class
      assert_equal new_tag.tagable.circuits.count, 5
      
    end
  end
end