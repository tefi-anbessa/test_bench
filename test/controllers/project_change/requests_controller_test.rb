# frozen_string_literal: true

require "helpers/controller_test_helper"
module ProjectChange
  class RequestsControllerTest < ActionController::TestCase
    include Devise::Test::ControllerHelpers
  include ControllerTestHelper

    setup do
    setup_projects_and_users # In test/helpers/test_setup_helpers.rb
    setup_disciplines(name: "Electrical") # Not used but required to pass setup test.
    # Set up users with edit permissions on the project.
    # (Abstracted test setup uses discipline roles.)
    @accredited_user = create(:user)
    @accredited_user.grant(:team_member, @project)
    @accredited_user_other_project = create(:user)
    @accredited_user_other_project.grant(:team_member, @other_project)

    # Set up in and out of scope instances of request
    @resource = create(:project_change_request, project: @project)
    @other_resource = create(:project_change_request, project: @other_project)
    end

    # For requests, team members can access new form.
    undef test_team_member_cannot_access_new_form

    # For requests, team members can create.
    undef test_team_member_cannot_create

    # For requests, team members can access edit form.
    undef test_team_member_cannot_access_edit_form

    # For requests, team member can update.
    undef test_team_member_cannot_update

    private

      # Required for nested routes
      def new_nesting_params
        { project_id: @project.id }
      end

      # Required for nested routes
      def index_nesting_params
        new_nesting_params
      end

      # Set the minimum required params for a valid resource
      def create_params
        { project_id: @project.id,
          project_change_request: {
            title: 'Test Change Request',
            reason: 'Test reason',
            summary: 'Test summary',
            duration: 'permanent'
          }
        }
      end

    def update_params
        { project_id: @project.id,
          project_change_request: {
            title: 'Updated Change Request',
            reason: 'Test reason',
            summary: 'Test summary',
            duration: 'permanent'
          }
        }
    end

      # Set invalid resource params for tests
      def invalid_param
        { project_change_request: {reason: nil } }
      end

      # Nominate an attribute to get changed during update tests
      def update_attribute_name
        :reason
      end

      # Nominate a valid value to update the attribute to
      def updated_attribute_value
        "updated reason"
      end
  end
end
