require_relative '../helpers/resource_policy_test'

class MotorPolicyTest < ActiveSupport::TestCase
  include ResourcePolicyTest
  def setup
    setup_resource_policy_test
  end
  def resource_class
    Motor
  end

  def create_resource(tag:)
    # Use motor factory to create motor with tag association, using default prefix and unique serial.
    create(:motor, tag: tag)
  end

  def new_resource(discipline:)
    # Use motor factory to build new motor with tag association, using default prefix and unique serial.
    build(:motor, tag: create(:tag, discipline: discipline))
  end

  def self.required_role
    :electrical_designer
  end
end