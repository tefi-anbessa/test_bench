require "test_helper"

class RoleTest < ActiveSupport::TestCase

    test "fixtures should be valid" do
      roles.each do |r|
        assert r.valid?, r.errors.full_messages.inspect
      end
    end

    test "resource type must be resourcified" do
      test = roles(:role1)
      test.resource_type = "Discipline".constantize
      assert_not test.valid?
    end
end
