# frozen_string_literal: true

require "test_helper"
require "helpers/controller_test_helper"
module Electrical
  class DemandsControllerTest < ActionController::TestCase
    include ControllerTestHelper
    include Devise::Test::ControllerHelpers

    setup do
      setup_controller_test
      setup_tags
      setup_model_specific_data
    end
    
    def setup_model_specific_data
      # Create a tag without any tagable
      @tag_no_tagable = create(:tag, :unique_tag, discipline: @discipline)

      # Create a tagable child of @tag
      @tagable = create(:electrical_light_cct, tag: @tag)
      @resource = create(:electrical_demand, demandable: @tagable)
      @other_tagable = create(:electrical_light_cct, tag: @other_tag)
      @other_resource = create(:electrical_demand, demandable: @other_tagable)

      # Create extra tags for a circuit and load connected with a cable
      @switchboard_tag = create(:tag, prefix: 'EX', serial: 1001, discipline: @discipline)
      @cable_tag = create(:tag, prefix: 'EC', serial: 1001, discipline: @discipline)
      @motor_tag = create(:tag, prefix: 'EM', serial: 1001, discipline: @discipline)
      
      # Create tagables with the tags
      @switchboard = create(:electrical_switchboard, tag: @switchboard_tag)
      @motor = create(:electrical_motor, tag: @motor_tag)
      @cable = create(:electrical_cable, tag: @cable_tag)

      # Create a circuit on the switchboard
      @circuit = create(:electrical_circuit, switchboard: @switchboard)

      # Create unassigned tag for building new demand
      @unassigned_tag = create(:tag, :unique_tag, discipline: @discipline)
      @unassigned_tag.update(tagable: create(:electrical_light_cct, tag: @unassigned_tag))
    end

  # Create Action Tests - Failure Cases
    test "cannot create with tag out of scope" do
      sign_in_and_set_project @accredited_user, @project
      assert_no_difference("#{resource_class}.count") do
        post :create, params: new_nesting_params.merge(create_params).merge(tag_id: @other_tag.id)
      end
      assert_conflict
    end

    test "cannot create with tag that has no tagable" do
      sign_in_and_set_project @accredited_user, @project
      assert_no_difference("#{resource_class}.count") do
        post :create, params: new_nesting_params.merge(create_params).merge(tag_id: @tag_no_tagable.id)
      end
      assert_conflict
    end

    test "cannot create with tag already has a demand" do
      sign_in_and_set_project @accredited_user, @project
      assert_no_difference("#{resource_class}.count") do
        post :create, params: new_nesting_params.merge(create_params).merge(tag_id: @tag.id)
      end
      assert_conflict
    end

    # Placeholoder for test "cannot create a tag that is not demandable"
    # No modules implemented yet that are not demandable
    
    private

      # Required for nested routes to new and create
      def new_nesting_params
        { tag_id: @unassigned_tag.id }
      end

      # Required for nested routes to new and create
      def index_nesting_params
        { discipline_id: @discipline.id }
      end

      # Set the minimum required params for a valid resource
      def create_params
          { electrical_demand: { 
              basis: 'power_pf',
              basis_notes: 'Test basis notes',
              supply: 220.0,
              config: :one,
              power: 100.0,
              vector: 0.0,
              power_factor: 0.8,
              current: 0.0,
              duty: 0.0
            } 
          }
      end

      # Some models have read only attributes, these need to be excluded from update tests
      # to avoid validation errors
      def update_params
          create_params
      end

      # Set an invalid resource param to test controller response
      def invalid_param
        { electrical_demand: { supply: "210V" } } # non-existent enum key
      end

      # Nominate an attribute to get changed during update tests
      def update_attribute_name
        :power
      end

      # Nominate a valid value to update the attribute to
      def updated_attribute_value
        200.0
      end
  end
end