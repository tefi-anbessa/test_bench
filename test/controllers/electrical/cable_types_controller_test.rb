#frozen_string_literal: true

require "test_helper"
require "helpers/controller_test_helper"
module Electrical
  class CableTypesControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers
  include ControllerTestHelper

    setup do
      # Cannot use standard setup because CableType is a catalog model, uses catalog_required_role.
      setup_projects_and_users
      setup_disciplines(name: "Electrical", required_role: :designer)
      setup_accredited_users(:designer)
      setup_discipline_resources
      setup_model_specific_data
    end

    def setup_model_specific_data
      @discipline.update(catalog_required_role: :custodian)
      @other_discipline.update(catalog_required_role: :custodian)
      @accredited_user.grant(:custodian, @discipline)
      @accredited_user_other_project.grant(:custodian, @other_discipline)
    end

    test "model specific setup is valid" do
      assert @accredited_user.has_role?(:custodian, @discipline)
      assert @accredited_user_other_project.has_role?(:custodian, @other_discipline)
    end

    private

      # Required for nested routes
      def new_nesting_params
        { discipline_id: @discipline.id }
      end

      # Required for nested routes
      def index_nesting_params
        new_nesting_params
      end

      # Set the expected params for a valid resource create
      def create_params
        { electrical_cable_type: 
          {
          conductor_material: "Cu",
          csa: 4.0,
          groups: 3,
          construction: 'core',
          neutral_csa: 4.0,
          earth_csa: 2.5,
          insulation: "XLPE",
          bedding: "PVC",
          armour: "SWA",
          sheath: "PVC",
          temperature_rating: "75˚C",
          voltage_rating: "600/1000V",
          bedding_od: 12.5,
          overall_od: 17.2
          }
        }
      end
      
      # No read only attributes
      def update_params
        create_params
      end

      # Set one invalid resource param for tests
      def invalid_param
        { electrical_cable_type: { conductor_material: "Au" } }
      end

      # Nominate an attribute to get changed during update tests
      def update_attribute_name
        :groups
      end

      # Nominate a valid value to update the attribute to
      def updated_attribute_value
        4
      end
  end
end
