require "test_helper"
require_relative "../helpers/tagable_test_patterns"

class CablesControllerTest < ActionController::TestCase
  include TagableTestPatterns
  include Devise::Test::ControllerHelpers

  setup do
    # Set the discipline applicable to the resource, required before setup_common_test_data
    @resource_discipline_code = :elec
    setup_common_test_data
    setup_model_specific_data
    setup_tags_and_resources
  end

  def setup_model_specific_data
    @cable_type = create(:cable_type, project: @project)
  end

  # Common code for all models, but values are model specific
  def setup_tags_and_resources
    # Set up a user with edit permissions on this resource. 
    @accredited_team_member = create(:user)
    @accredited_team_member.grant(:team_member, @project)
    @accredited_team_member.grant(:electrical_designer)
    # Set up an existing tag with associated resource for index, show, edit, update, destroy tests
    @assigned_tag = create(:tag, prefix: 'EC', serial: 1001, project: @project, discipline: @resource_discipline)
    @resource = create(:cable, tag: @assigned_tag, cable_type: @cable_type)
    # Set up an unassigned tag for create and update tests
    @unassigned_tag = create(:tag, prefix: 'EC', serial: 1002, project: @project, discipline: @resource_discipline)
    # Every model sets a string of the wrong type for testing the type check
    @wrong_tagable_type = "Switchboard"
  end

  def params_with_existing_tag
    {
      tag_id: @unassigned_tag.id,
      cable: {
        cable_type_id: @cable_type.id
      }
    }
  end

  def params_with_new_tag
    {
      cable: {
        cable_type_id: @cable_type.id,
        tag: {
          discipline_id: @resource_discipline.id,
          prefix: 'EC',
          serial: 2001,
          suffix: '',
          service: 'One-shot cable',
          stage: 1
        }
      }
    }
  end

  # Set the minimum required params for a valid resource
  def valid_resource_params
    {
      cable_type_id: @cable_type.id
    }
  end

  # Set invalid resource params for tests
  def invalid_resource_params
      { cable_type_id: nil }
  end

  # Nominate an attribute to get changed during update tests
  def update_attribute_name
    :route_length
  end

  # Nominate a value to update the attribute to
  def updated_attribute_value
    15.0
  end

  # Override to specify the controller name for this test
  def controller_name_for_test
    'cables'
  end
end
