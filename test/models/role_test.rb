require "test_helper"

class RoleTest < ActiveSupport::TestCase

    test "fixtures should be valid" do
      roles.each do |f|
        assert f.valid?, f.errors.full_messages.inspect
      end
    end

    test "resource type must be resourcified" do
      test = Role.new
      test.resource_type = "Discipline".constantize
      assert_not test.valid?
    end
end
