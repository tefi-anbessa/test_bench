require "test_helper"
require_relative "../helpers/tagable_test_patterns"

class SwitchboardsControllerTest < ActionController::TestCase
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
    # Switchboards have circuits as child models - create after tags are available
    # Will be created in setup_tags_and_resources after @assigned_tag exists
  end

  # Common code for all models, but values are model specific
  def setup_tags_and_resources
    # Set up a user with edit permissions on this resource.
    @accredited_team_member = create(:user)
    @accredited_team_member.grant(:team_member, @project)
    @accredited_team_member.grant(Switchboard.required_role)
    # Set up an existing tag with associated resource for index, show, edit, update, destroy tests
    @assigned_tag = create(:tag, prefix: 'EX', serial: 1001, discipline: @resource_discipline)
    @resource = create(:switchboard, tag: @assigned_tag)
    # Set up an unassigned tag for create and update tests
    @unassigned_tag = create(:tag, prefix: 'EX', serial: 1002, discipline: @resource_discipline)
    # Every model sets a string of the wrong type for testing the type check
    @wrong_tagable_type = "Motor"
    # Switchboards have circuits as child models - create after tags are available
    @switchboard_with_circuits = create(:switchboard, :with_circuits, circuits_count: 3)
  end

  def params_with_existing_tag
    {
      tag_id: @unassigned_tag.id,
      switchboard: {
        voltage_rating: '600/1000V',
        busbar_rating: '600A'
      }
    }
  end

  def params_with_new_tag
    {
      switchboard: {
        voltage_rating: '600/1000V',
        busbar_rating: '600A',
        tag: {
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
      voltage_rating: '600/1000V',
      busbar_rating: '600A'
    }
  end

  # Set invalid resource params for tests
  def invalid_resource_params
    { voltage_rating: 999 }  # Invalid voltage rating (enum only allows 0-9)
  end

  # Nominate an attribute to get changed during update tests
  def update_attribute_name
    :ingress_protection
  end

  # Nominate a value to update the attribute to
  def updated_attribute_value
    '11'
  end

  # Override to specify the controller name for this test
  def controller_name_for_test
    'switchboards'
  end

  # Tests for model specific behaviour
  # Switchboards controller allows creation of "empty" circuits at the same time as create or update.
  test "electrical designer can create new switchboard and add circuits" do
    sign_in @accredited_team_member
    assert_difference('Switchboard.count', 1) do
      assert_difference('Circuit.count', 2) do
        post :create, params: {
          switchboard: {
            voltage_rating: '600/1000V',
            busbar_rating: '600A',
            tag: {
              discipline_id: @resource_discipline.id,
              prefix: 'EX',
              serial: 2002,
              suffix: '',
              service: 'Test switchboard',
              stage: 1
            }, 
          circuits: 2
          }
        }
      end
    end
    tag = Tag.find_by(prefix: 'EX', serial: 2002)
    expected_messages = [
      I18n.t('flash.tagables.created_and_assigned', 
        resource_name: Switchboard.model_name.human,
        id: tag.tagable.id,
        tag: tag.label),
      I18n.t('flash.assigned', count: 2, resource_name: Circuit.model_name.human)
    ]
    assert_flash_messages :success, expected_messages
  end
end
