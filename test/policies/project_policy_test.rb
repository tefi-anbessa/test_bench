require 'test_helper'

class ProjectPolicyTest < ActiveSupport::TestCase
  include Devise::Test::IntegrationHelpers

  def test_scope
    sign_in users(:owner)
    assert_equal policy_scope(Project).count, Project.count
  end

  def test_show
  end

  def test_create
  end

  def test_update
  end

  def test_destroy
  end
end
