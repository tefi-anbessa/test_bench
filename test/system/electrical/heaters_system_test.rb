# frozen_string_literal: true

require "application_system_test_case"
require "helpers/tagable_system_tests"
module Electrical
  class HeatersSystemTest < ApplicationSystemTestCase
    include Devise::Test::IntegrationHelpers
    include Warden::Test::Helpers
    include TagableSystemTests

    setup do
      setup_common_tagable_data
      setup_model_specific_data
    end

    def setup_model_specific_data
      @tag.update(prefix: "EH")
      @tag.reload
      @unassigned_tag.update(prefix: "EH")
      @unassigned_tag.reload
      # List fields that should appear in index. 
      @index_fields = %w[ heater_type application ingress_protection sheath_material insulation_material ]

      # List index fields that should have ransack search capability.
      @search_fields = %w[heater_type application ingress_protection sheath_material insulation_material ]

      # List all fields that should appear in show (should be all)
      @show_fields = %w[heater_type application ingress_protection sheath_temperature_max power_density_min 
      power_density_max sheath_material insulation_material]

      # List all associations that should have a collapsible card on the show view
      @show_associations = [:tag, :electrical_demand]

      # List all fields that should appear in forms (should be all)
      @new_fields = {heater_type: nil, application: nil, sheath_temperature_max: nil, power_density_min: nil, 
      power_density_max: nil, sheath_material: nil, insulation_material: nil}
      @edit_fields = @new_fields

      # Set an attribute/s to be modified in edit test
      # Only working with string/text fields at present
      @edit_attributes = { notes: "Updated notes" }
    end

    def fill_in_model_specific_fields
      find("select[name='ip_1'] option[value='1']").select_option
      find("select[name='ip_2'] option[value='1']").select_option
    end
  end
end