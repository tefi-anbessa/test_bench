require "test_helper"
require_relative "../support/tagable_test_patterns"

class SwitchboardsControllerTest < ActionController::TestCase
  include TagableTestPatterns
  include Devise::Test::ControllerHelpers

  setup do
    # Set the discipline applicable to the resource, required before setup_common_test_data
    @resource_discipline = create(:discipline, code: 'E')
    setup_common_test_data
    setup_model_specific_data
    setup_tags_and_resources
  end

  def setup_model_specific_data
    # Switchboards have circuits as child models - create after tags are available
    # Will be created in setup_tags_and_resources after @assigned_tag exists
  end

  # Common code for all models, but values are model specific
  def setup_tags_and_resources
    # Set up a user with edit permissions on this resource.
    @accredited_team_member = create(:user)
    @accredited_team_member.grant(:team_member, @project)
    @accredited_team_member.grant(:electrical_designer)
    # Set up an existing tag with associated resource for index, show, edit, update, destroy tests
    @assigned_tag = create(:tag, prefix: 'EX', serial: 1001, project: @project, discipline: @resource_discipline)
    @resource = create(:switchboard, tag: @assigned_tag)
    # Set up an unassigned tag for create and update tests
    @unassigned_tag = create(:tag, prefix: 'EX', serial: 1002, project: @project, discipline: @resource_discipline)
    # Every model sets a string of the wrong type for testing the type check
    @wrong_tagable_type = "Motor"
    # Switchboards have circuits as child models - create after tags are available
    @switchboard_with_circuits = create(:switchboard, :with_circuits, circuits_count: 3)
  end

  def params_with_existing_tag
    {
      tag_id: @unassigned_tag.id,
      switchboard: {
        location: 'Test Location',
        voltage_rating: '600/1000V',
        busbar_rating: '600A'
      }
    }
  end

  def params_with_new_tag
    {
      switchboard: {
        location: 'Test Location',
        voltage_rating: '600/1000V',
        busbar_rating: '600A',
        tag: {
          project_id: @project.id,
          discipline_id: @resource_discipline.id,
          prefix: 'EX',
          serial: 2002,
          suffix: '',
          service: 'Test switchboard',
          stage: 1
        }
      }
    }
  end

  # Set the minimum required params for a valid resource
  def valid_resource_params
    {
      location: 'Test Location',
      voltage_rating: '600/1000V',
      ingress_protection: 'IP55'
    }
  end

  # Set invalid resource params for tests
  def invalid_resource_params
    { voltage_rating: 999 }  # Invalid voltage rating (enum only allows 0-9)
  end

  # Nominate an attribute to get changed during update tests
  def update_attribute_name
    :location
  end

  # Nominate a value to update the attribute to
  def updated_attribute_value
    'Updated Location'
  end

  # Override to specify the controller name for this test
  def controller_name_for_test
    'switchboards'
  end
end
