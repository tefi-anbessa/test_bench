require "application_system_test_case"
require File.join(Rails.root, 'test', 'helpers', 'tagable_system_test_patterns')

module Electrical
  class CablesSystemTest < ApplicationSystemTestCase
    include TagableSystemTestPatterns
    include Devise::Test::IntegrationHelpers
    include Warden::Test::Helpers
    include ActionView::Helpers::NumberHelper

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
      @unassigned_tag.update(prefix: "EC")
      @unassigned_tag.reload
      @cable_type = create(:electrical_cable_type, discipline: @discipline)
      @resource = create(:electrical_cable, cable_type: @cable_type, tag: @tag)
      # List fields that should appear in index. 
      @index_fields = %w[ electrical_cable_type_id route_length ]

      # List index fields that should have ransack search capability.
      @search_fields = %w[ notes ]

      # List all fields that should appear in show (should be all)
      @show_fields = %w[ route_length vertical_allowance 
        termination_allowance start_mark end_mark from to notes ]

      # List all fields that should appear in forms (should be all)
      @form_fields = %w[ electrical_cable_type_id route_length vertical_allowance 
        termination_allowance start_mark end_mark from_type to_type notes ]

    end
  end
end