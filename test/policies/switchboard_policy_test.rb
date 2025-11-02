require_relative '../helpers/resource_policy_test'

class SwitchboardPolicyTest < ActiveSupport::TestCase
  include ResourcePolicyTest
  def setup
    setup_resource_policy_test
  end

  def resource_class
    Switchboard
  end

  def create_resource(tag:)
    # Use switchboard factory to create switchboard with tag association, using default prefix and unique serial.
    create(:switchboard, tag: tag)
  end

  def new_resource(discipline:)
    # Use switchboard factory to build new switchboard with tag association, using default prefix and unique serial.
    build(:switchboard, tag: create(:tag, discipline: discipline))
  end
end