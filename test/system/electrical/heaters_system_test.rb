require "application_system_test_case"
require File.join(Rails.root, 'test', 'helpers', 'tagable_system_test_patterns')
module Electrical
  class HeatersSystemTest < ApplicationSystemTestCase
    include TagableSystemTestPatterns
    include Devise::Test::IntegrationHelpers
    include Warden::Test::Helpers
    include ActionView::Helpers::NumberHelper

    setup do
      setup_common_tagable_data
      setup_model_specific_data
    end

    def setup_model_specific_data
      # List fields that should appear in index. 
      @index_fields = %w[ heater_type application ingress_protection sheath_material insulation_material ]

      # List index fields that should have ransack search capability.
      @search_fields = %w[heater_type application ingress_protection sheath_material insulation_material ]

      # List all fields that should appear in show (should be all)
      @show_fields = %w[heater_type application ingress_protection sheath_temperature_max power_density_min 
      power_density_max sheath_material insulation_material]

      # List all fields that should appear in forms (should be all)
      @form_fields = %w[heater_type application ingress_protection sheath_temperature_max power_density_min 
      power_density_max sheath_material insulation_material]
    end
  end
end