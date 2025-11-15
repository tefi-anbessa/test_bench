require_relative '../helpers/resource_policy_test'

class CablePolicyTest < ActiveSupport::TestCase
  include ResourcePolicyTest
  def setup
    setup_resource_policy_test
  end
  def resource_class
    Cable
  end

  def create_resource(tag:)
    # Use cable factory to create cable with tag association, using default prefix and unique serial.
    create(:cable, tag: tag)
  end

  def new_resource(discipline:)
    # Use cable factory to build new cable with tag association, using default prefix and unique serial.
    build(:cable, tag: create(:tag, discipline: discipline))
  end

  def self.required_role
    :electrical_designer
  end
end