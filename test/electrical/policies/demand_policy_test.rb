require_relative '../helpers/resource_policy_test'

class DemandPolicyTest < ActiveSupport::TestCase
  include ResourcePolicyTest
  def setup
    setup_resource_policy_test
  end

  def resource_class
    Demand
  end

  def create_resource(tag:)
    # Uses demand factory to create demand with tag association, using default prefix and unique serial.
    create(:demand, demandable: create(:motor, tag: tag))
  end

  def new_resource(discipline:)
    # Uses demand factory to build new demand with tag association, using default prefix and unique serial.
    build(:demand, demandable: create(:motor, tag: create(:tag, discipline: discipline)))
  end

  def self.required_role
    :electrical_designer
  end
end