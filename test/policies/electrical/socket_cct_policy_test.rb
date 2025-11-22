require 'test_helper'
require_relative '../../helpers/resource_policy_test'
module Electrical

  class SocketCctPolicyTest < ActiveSupport::TestCase
    include ResourcePolicyTest
    def setup
      setup_resource_policy_test
    end

    def resource_class
      Electrical::SocketCct
    end

    def create_resource(tag:)
      # Use socket_cct factory to create socket_cct with tag association, using default prefix and unique serial.
      create(:electrical_socket_cct, tag: tag)
    end

    def new_resource(discipline:)
      # Use socket_cct factory to build new socket_cct with tag association, using default prefix and unique serial.
      build(:electrical_socket_cct, tag: create(:tag, discipline: discipline))
    end
  end
end