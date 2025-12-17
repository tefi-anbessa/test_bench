require "application_system_test_case"
require File.join(Rails.root, 'test', 'helpers', 'tagable_system_test_patterns')
module Electrical
  class MotorsSystemTest < ApplicationSystemTestCase
    include TagableSystemTestPatterns
    include Devise::Test::IntegrationHelpers
    include Warden::Test::Helpers
    include ActionView::Helpers::NumberHelper

    setup do
      setup_common_tagable_data
      setup_model_specific_data
    end

    def setup_model_specific_data
      # List fields that should appear in index
      @index_fields = %w[motor_type frame_size ingress_protection poles speed_rated]
      # List fields that should have ransack search capability
      # Ignore poles and speed rated as they are a numeric fields searched with _eq and standard test does not match.
      @search_fields = %w[motor_type frame_size ingress_protection notes]
      # List all fields that should appear in show
      @show_fields = %w[motor_type frame_size ingress_protection poles speed_rated notes]
      # List all fields that should appear in forms
      @form_fields = %w[motor_type frame_size ingress_protection poles speed_rated notes]
    end
  end
end