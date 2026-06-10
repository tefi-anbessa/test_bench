# frozen_string_literal: true

require "application_system_test_case"
require "helpers/tagable_system_tests"
module Electrical
  class LightCctsSystemTest < ApplicationSystemTestCase
    include Devise::Test::IntegrationHelpers
    include Warden::Test::Helpers
    include TagableSystemTests

    setup do
      setup_common_tagable_data
      setup_model_specific_data
    end

    def setup_model_specific_data
      @tag.update(prefix: "EL")
      @tag.reload
      @tag2.update(prefix: "EL")
      @tag2.reload
      @unassigned_tag.update(prefix: "EL")
      @unassigned_tag.reload
      # List fields that should appear in index. 
      @index_fields = [:light_fitting_type, :quantity, :notes ]

      # List index fields that should have ransack search capability.
      @search_fields = [:light_fitting_type, :notes]

      # List all fields that should appear in show (should be all)
      @show_fields = [:light_fitting_type, :quantity, :notes]

      # List all associations that should have a collapsible card on the show view
      @show_associations = [:tag, :electrical_demand]

      # List all fields that should appear in forms (should be all)
      @new_fields = {light_fitting_type: nil, quantity: nil, notes: nil}
      @edit_fields = @new_fields

      # Set an attribute/s to be modified in edit test
      # Only working with string/text fields at present
      @edit_attributes = { notes: "Updated notes" }
    end

    def fill_in_model_specific_fields
      # No special fields in light circuits
    end
  end
end