# frozen_string_literal: true
require "test_helper"
require "helpers/tagable_controller_tests"
module Electrical
  class SwitchboardsControllerTest < ActionController::TestCase
    include TagableControllerTests
    include Devise::Test::ControllerHelpers

    setup do
      setup_controller_test
      setup_model_specific_data
    end

    def setup_model_specific_data
      # Switchboards have circuits as child models - create after tags are available
      @switchboard_with_circuits = create(:electrical_switchboard, :with_circuits, circuits_count: 3)
    end

    # Set the expected params for a valid resource
    def create_params
      {
        voltage_rating: '600/1000V',
        busbar_rating: '600A',
        busbar_fault_rating: 2000.0,
        busbar_fault_duration: 0.5,
        cable_entry: 'Bottom',
        incomer_protection: 'Isolator 4P',
        metering: 'None',
        neutral_bar_connections: 'None',
        earth_bar_connections: 'None',
        ingress_protection: '20',
        notes: 'Test switchboard'
      }
    end

    # Set invalid resource param for tests
    def invalid_param
      { voltage_rating: 999 }  # Invalid voltage rating (enum only allows 0-9)
    end

    # Nominate an attribute to get changed during update tests
    def update_attribute_name
      :ingress_protection
    end

    # Nominate a value to update the attribute to
    def updated_attribute_value
      '11'
    end

    # Tests for model specific behaviour
    # Switchboards controller allows creation of "empty" circuits at the same time as create or update.
    test "electrical designer can create new switchboard and add circuits" do
      sign_in_and_set_project @accredited_user, @project
      assert_difference('Switchboard.count', 1) do
        assert_difference('Circuit.count', 2) do
          post :create, params: {
            discipline_id: @discipline.id,
            electrical_switchboard: {
              voltage_rating: '600/1000V',
              busbar_rating: 200.0,
              busbar_fault_rating: 2000.0,
              busbar_fault_duration: 0.5,
              cable_entry: 'Bottom',
              incomer_protection: 'Isolator 4P',
              metering: 'None',
              neutral_bar_connections: 'None',
              earth_bar_connections: 'None',
              ingress_protection: '20',
              notes: 'Test switchboard',
              tag: {
                prefix: 'EX',
                serial: 2002,
                suffix: '',
                service: 'Test switchboard',
                stage: 1
              }, 
            circuits: 2
            }
          }
        end
      end
      tag = Tag.find_by(prefix: 'EX', serial: 2002)
      expected_messages = [
        I18n.t('flash.tagables.created_and_assigned', 
          resource_name: Electrical::Switchboard.model_name.human,
          id: tag.tagable.id,
          tag: tag.label),
        I18n.t('flash.assigned', count: 2, resource_name: I18n.t('activerecord.models.electrical/circuit', count: 2))
      ]
      assert_flash_messages :success, expected_messages
    end
  end
end