require "test_helper"

class CableTest < ActiveSupport::TestCase
  def setup
    @cable = Cable.new(cable_type: cable_types(:one),
                        feeder: loads(:ex4),
                        incomer: loads(:pm),
                        route_length: 9.99,
                        vertical_allowance: 2.0,
                        termination_allowance: 5.0,
                        start_mark: 1,
                        end_mark: 10)
  end

  test "setup should be valid" do
    assert @cable.valid?, @cable.errors.full_messages.inspect
  end

  test "fixtures should be valid" do
    cables.each do |f|
      assert f.valid?, f.errors.full_messages.inspect
    end
  end
=begin
=end
end
