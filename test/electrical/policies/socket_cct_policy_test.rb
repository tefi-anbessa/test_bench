require_relative '../helpers/resource_policy_test'

class SocketCctPolicyTest < ActiveSupport::TestCase
  include ResourcePolicyTest
  def setup
    setup_resource_policy_test
  end

  def resource_class
    SocketCct
  end

  def create_resource(tag:)
    # Use socket_cct factory to create socket_cct with tag association, using default prefix and unique serial.
    create(:socket_cct, tag: tag)
  end

  def new_resource(discipline:)
    # Use socket_cct factory to build new socket_cct with tag association, using default prefix and unique serial.
    build(:socket_cct, tag: create(:tag, discipline: discipline))
  end
end