# frozen_string_literal: true

require "application_system_test_case"
require "helpers/tagable_system_tests"
module Electrical
  class CablesSystemTest < ApplicationSystemTestCase
    include Devise::Test::IntegrationHelpers
    include Warden::Test::Helpers
    include ActionView::Helpers::NumberHelper
    include TagableSystemTests

    setup do
      # Cables cannot use standard tagable setup, as cables need associated cable types.
      # setup_common_tagable_data setup_common_tagable_data
      setup_projects_and_users
      setup_disciplines(name: "Electrical", required_role: :designer)
      setup_accredited_users(role = :designer)
      setup_tags
      setup_model_specific_data
    end

    def setup_model_specific_data
      @tag.update(prefix: "EC")
      @tag.reload
      @tag2.update(prefix: "EC")
      @tag2.reload
      @unassigned_tag.update(prefix: "EC")
      @unassigned_tag.reload
      @cable_type = create(:electrical_cable_type, discipline: @discipline)
      @resource = create(:electrical_cable, cable_type: @cable_type, tag: @tag)
      @resource2 = create(:electrical_cable, cable_type: @cable_type, tag: @tag2)
      # List fields that should appear in index. 
      @index_fields = %w[ electrical_cable_type_id route_length ]

      # List index fields that should have ransack search capability.
      @search_fields = %w[ notes ]

      # List all fields that should appear in show (should be all)
      @show_fields = %w[ route_length vertical_allowance 
        termination_allowance start_mark end_mark notes ]

      # List all associations that should have a collapsible card on the show view
      @show_associations = [:tag, :electrical_cable_type, :from, :to]

      # List all fields that should appear in forms (should be all)
      @new_fields = { electrical_cable_type: nil, route_length: nil, vertical_allowance: nil, 
        termination_allowance: nil, start_mark: nil, end_mark: nil, from: nil, to: nil, notes: nil }
      @edit_fields = @new_fields

      # Set attribute/s to be modified in edit test
      # Only working with string/text fields at present
      @edit_attributes = { notes: "Updated notes" }
    end

    test "accredited user assign from and to" do
      # Build switchboard with circuits
      swbd_tag = create(:tag, :unique_tag, prefix: 'XB', discipline: @discipline)
      switchboard = create(:electrical_switchboard, :with_circuits, circuits_count: 2, tag: swbd_tag)
      circuit = switchboard.circuits.find_by(serial: 1)
      # Build load
      motor_tag = create(:tag, :unique_tag, prefix: 'PM', discipline: @discipline)
      motor = create(:electrical_motor, tag: motor_tag)
      motor_load = create(:electrical_demand, demandable: motor)

      sign_in @accredited_user
      # Mock current_project for this test
      ApplicationController.any_instance.stubs(:current_project).returns(@project)
      
      # Navigate to the cable edit page
      visit edit_electrical_cable_path(@resource)
      
      edit_resource_form_assertions

      find('#electrical_cable_from_type').select(I18n.t('activerecord.models.electrical/circuit.one'))
      find('#electrical_cable_from_id').select(circuit.id.to_s)
      find('#electrical_cable_to_type').select(I18n.t('activerecord.models.electrical/demand.one'))
      find('#electrical_cable_to_id').select(motor_load.id.to_s)

      # Submit the form data
      click_button I18n.t('actions.update')
      sleep 0.5  # Give database time to commit
      @resource.reload
      assert_equal circuit, @resource.from
      assert_equal motor_load, @resource.to
      assert_current_path electrical_cable_path(@resource)
      collapsible_assertions(@resource, :from, header: :association)
      collapsible_assertions(@resource, :to, header: :association)
    end
  end
end