require "application_system_test_case"
module Instrument
  class PressureGaugesSystemTest < ApplicationSystemTestCase
    include Devise::Test::IntegrationHelpers
    include Warden::Test::Helpers
    include ActionView::Helpers::NumberHelper

    setup do
      setup_projects_and_users
      # Discipline defaults to (name: "Electrical", required_role: :designer)
      # Set as required
      setup_disciplines
      # Role for accredited users defaults to (role = :designer)
      # Set as required
      setup_accredited_users
      setup_model_specific_data
    end

    def setup_model_specific_data

      # List fields that should appear in index. 
      # The generator will include test for sort link header for each included field, 
      # and test for an appropriate value field for the type.
      @index_fields = %i[measurement_type pressure_unit range_min range_max fluid_phase process_fluid accuracy_class dial_size connection_type connection_size case_material wetted_material movement_type liquid_filled fill_fluid ip_rating safety_pattern accessories notes]

      # List index fields that should have ransack search capability.
      # The generator will only build and test for "contains" predicates (_cont).
      # Don't include numeric or date fields here, add model specific tests for these later in this file if required.
      @search_fields = %i[measurement_type pressure_unit fluid_phase process_fluid accuracy_class dial_size connection_type connection_size case_material wetted_material movement_type fill_fluid ip_rating accessories notes]

      # List all attribute fields that should appear in show.
      @show_fields = %i[measurement_type pressure_unit range_min range_max fluid_phase process_fluid accuracy_class dial_size connection_type connection_size case_material wetted_material movement_type liquid_filled fill_fluid ip_rating safety_pattern accessories notes]

      # List all associations that should have a collapsible card on the show view.
      @show_associations = %i[]

      # List all fields that should appear in forms (usually all).
      # New and edit required separately because some models have read only fields that can't be edited.
      # Set a differrent valid value for the field if it is required to be unique, otherwise set nil for factory default.
      @new_fields = { measurement_type: nil, pressure_unit: nil, range_min: nil, range_max: nil, fluid_phase: nil, process_fluid: nil, accuracy_class: nil, dial_size: nil, connection_type: nil, connection_size: nil, case_material: nil, wetted_material: nil, movement_type: nil, liquid_filled: nil, fill_fluid: nil, ip_rating: nil, safety_pattern: nil, accessories: nil, notes: nil }
      @edit_fields = @new_fields
    end

    def fill_in_model_specific_fields
      # Code for filling in any fields that don't follow the assumed pattern of the field type.
      # E.g. numeric fields with a drop down selector.
    end
  end
end
