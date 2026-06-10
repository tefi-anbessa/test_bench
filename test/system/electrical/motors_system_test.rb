# frozen_string_literal: true

require "application_system_test_case"
require "helpers/tagable_system_tests"
module Electrical
  class MotorsSystemTest < ApplicationSystemTestCase
    include Devise::Test::IntegrationHelpers
    include Warden::Test::Helpers
    include TagableSystemTests

    setup do
      setup_common_tagable_data
      setup_model_specific_data
    end

    def setup_model_specific_data
      # Set prefix to one of the options available on the selector for the discipline prefix schema.
      # Next/previous tests assume sort order is @tag before @tag2, factory should generate consecutive serials.
      @tag.update(prefix: "PM")
      @tag.reload
      @tag2.update(prefix: "PM")
      @tag2.reload
      @unassigned_tag.update(prefix: "PM")
      @unassigned_tag.reload

      # List fields that should appear in index
      @index_fields = %w[motor_type frame_size ingress_protection poles speed_rated]

      # List fields that should have ransack search capability
      # Ignore poles and speed rated as they are a numeric fields searched with _eq and standard test does not match.
      @search_fields = %w[motor_type frame_size ingress_protection notes]

      # List all fields that should appear in show
      @show_fields = %w[motor_type frame_size ingress_protection poles speed_rated notes]

      # List all associations that should have a collapsible card on the show view
      @show_associations = [:tag, :electrical_demand]

      # List all fields that should appear in forms
      @new_fields = {motor_type: nil, frame_size: nil, poles: nil, speed_rated: nil, notes: nil}
      @edit_fields = @new_fields

      # Set an attribute/s to be modified in edit test
      # Only working with string/text fields at present
      @edit_attributes = { poles: 2 }
      @model_special_cases = { ingress_protection: nil }
    end

    def fill_in_model_specific_fields
      find("select[name='ip_1'] option[value='1']").select_option
      find("select[name='ip_2'] option[value='1']").select_option
    end
  end
end