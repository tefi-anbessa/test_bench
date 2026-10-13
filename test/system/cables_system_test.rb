# frozen_string_literal: true

require "application_system_test_case"
require "helpers/tagable_system_tests"
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
    @resource = create(:cable, cable_type: @cable_type, tag: @tag)
    @resource2 = create(:cable, cable_type: @cable_type, tag: @tag2)
    # List fields that should appear in index.
    @index_fields = %w[ route_length ]

    # List index fields that should have ransack search capability.
    @search_fields = %w[ notes ]

    # List all fields that should appear in show (should be all)
    @show_fields = %w[ route_length vertical_allowance
      termination_allowance start_mark end_mark notes ]

    # List all associations that should have a collapsible card on the show view
    @show_associations = [:tag, :cable_type, :from, :to]

    # List all fields that should appear in forms (should be all) - cable_type
    # is excluded here and handled in fill_in_model_specific_fields below: its
    # type half is a hidden field (implied by discipline, not user-chosen),
    # which doesn't fit the generic :polymorphic field assumptions (same
    # reasoning as ingress_protection's own :special field handling).
    @new_fields = { route_length: nil, vertical_allowance: nil,
      termination_allowance: nil, start_mark: nil, end_mark: nil, from: nil, to: nil, notes: nil }
    @edit_fields = @new_fields
    @model_special_cases = { cable_type: nil }

    # Set attribute/s to be modified in edit test
    # Only working with string/text fields at present
    @edit_attributes = { notes: "Updated notes" }
  end

  def fill_in_model_specific_fields
    find("select[name='cable[cable_type_id]'] option[value='#{@cable_type.id}']").select_option
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
    visit edit_tag_tagable_path(@resource.tag)

    edit_resource_form_assertions

    find('#cable_from_type').select(I18n.t('activerecord.models.electrical/circuit.one'))
    find('#cable_from_id').select(circuit.label)
    find('#cable_to_type').select(I18n.t('activerecord.models.electrical/demand.one'))
    find('#cable_to_id').select(motor_load.label)

    # Submit the form data
    click_button I18n.t('actions.update')
    sleep 0.5  # Give database time to commit
    @resource.reload
    assert_equal circuit, @resource.from
    assert_equal motor_load, @resource.to
    assert_current_path tag_tagable_path(@resource.tag)
    collapsible_assertions(@resource, :from, header: :association)
    collapsible_assertions(@resource, :to, header: :association)
  end
end
