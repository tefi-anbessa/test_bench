# frozen_string_literal: true
require "application_system_test_case"
require "helpers/discipline_resource_system_tests"
module Electrical
  class CableTypesSystemTest < ApplicationSystemTestCase
    include Devise::Test::IntegrationHelpers
    include Warden::Test::Helpers
    include ActionView::Helpers::NumberHelper
    include DisciplineResourceSystemTests

    setup do
      setup_common_data
      setup_model_specific_data
    end

    def setup_model_specific_data
      @resource = create(:electrical_cable_type, discipline: @discipline)
      @discipline_resource_index_header = I18n.t('electrical.cable_types.index.header', 
        scope_text: [@discipline.project.code, @discipline.class.model_name.human, @discipline.long_label].join(' '))
      @project_resource_index_header = I18n.t('electrical.cable_types.index.header', 
        scope_text: [I18n.t("activerecord.models.project.one"), @project.label].join(': '))
      @project_resource_index_title = @discipline_resource_index_title = I18n.t('electrical.cable_types.index.title')
      # List fields that should appear in index. 
      # The generator will include test for sort link header for each column, 
      # and try to find an appropriate value field for the type.
      @index_fields = [:code, :notes]

      # List index fields that should have ransack search capability.
      # The generator will only test for "contains" fields (_cont).
      # Don't include numeric or date fields, add model specific tests for these later in this file.
      @search_fields = [:code, :notes]

      # List all fields that should appear in show (usually all)
      @show_fields = [:conductor_material, :groups, :construction, :csa, :neutral_csa, :earth_csa,
            :insulation, :bedding, :armour, :sheath, :bedding_od, :overall_od,
            :temperature_rating, :voltage_rating, :notes, :code]

      # List all fields that should appear in forms (usually all).
      # New and edit required separately because some models have read only fields that can't be edited.
      # Set a valid value for each field if required to be unique, set nil for factory default.
      # Document model has its own way to ensure uniqueness by setting serial internally.
      @new_fields = {conductor_material: nil, groups: nil, construction: nil, csa: nil, neutral_csa: nil, 
        earth_csa: nil, insulation: nil, bedding: nil, armour: nil, sheath: nil, bedding_od: nil, overall_od: nil, 
        temperature_rating: nil, voltage_rating: nil, notes: nil}
      @edit_fields = @new_fields

      # Set an attribute/s to be modified in edit test
      # Only working with text fields at present
      @edit_attributes = { notes: "REVISED FOR TEST" }
    end

    def fill_in_model_specific_fields
      # No special fields in cable types
    end
  end
end