require_relative '../helpers/resource_policy_test'

class CircuitPolicyTest < ActiveSupport::TestCase
  include ResourcePolicyTest
  def setup
    setup_resource_policy_test
  end
  
  def resource_class
    Circuit
  end

  def create_resource(tag:)
    # Use circuit factory to create circuit with tag association, using default prefix and unique serial.
    create(:circuit, switchboard: create(:switchboard, tag: tag))
  end

  def new_resource(discipline:)
    # Use circuit factory to build new circuit belonging to switchboard with tag association, using default prefix and unique serial.
    build(:circuit, switchboard: create(:switchboard, tag: create(:tag, discipline: discipline)))
  end

  def self.required_role
    :electrical_designer
  end
end