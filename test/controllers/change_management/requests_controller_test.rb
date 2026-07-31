# frozen_string_literal: true

require "helpers/controller_test_helper"
module ChangeManagement
  class RequestsControllerTest < ActionController::TestCase
    include Devise::Test::ControllerHelpers
    include ControllerTestHelper

    setup do
      @nesting = :project
      setup_projects_and_users # In test/helpers/test_setup_helpers.rb
      setup_disciplines(name: "Electrical") # Not used but required to pass setup test.
      # Set up users with edit permissions on the project.
      # (Abstracted test setup uses discipline roles.)
      @accredited_user = create(:user)
      @accredited_user.grant(:team_member, @project)
      @accredited_user_other_project = create(:user)
      @accredited_user_other_project.grant(:team_member, @other_project)

      # Set up in and out of scope instances of request
      @resource = create(:change_management_request, project: @project)
      @other_resource = create(:change_management_request, project: @other_project)
    end

    # Tweak required to setup test roles
    undef test_setup_is_valid
    def test_setup_is_valid
      assert @project.valid?
      assert @project.persisted?
      assert @discipline.valid?
      assert @discipline.persisted?
      assert @admin.valid?
      assert @admin.persisted?
      assert @project_manager.valid?
      assert @project_manager.persisted?
      assert @team_member.valid?
      assert @team_member.persisted?
      assert @regular_user.valid?
      assert @regular_user.persisted?
      assert @accredited_user.valid?
      assert @accredited_user.persisted?
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

      # Set the minimum required params for a valid resource
      def create_params
        { project_id: @project.id,
          change_management_request: {
            title: 'Test Change Request',
            reason: 'Test reason',
            summary: 'Test summary',
            duration: 'permanent'
          }
        }
      end

    def update_params
        { project_id: @project.id,
          change_management_request: {
            title: 'Updated Change Request',
            reason: 'Test reason',
            summary: 'Test summary',
            duration: 'permanent'
          }
        }
    end

      # Set invalid resource params for tests
      def invalid_param
        { change_management_request: {reason: nil } }
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
