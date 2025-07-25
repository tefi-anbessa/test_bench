require "test_helper"

class CircuitTest < ActiveSupport::TestCase
  self.use_instantiated_fixtures = true

  def setup
    @circuit = circuits(:pm)
    @load = @circuit.load
    @cable = @circuit.cable
  end

  test "setup should be valid" do
    assert @load.valid?, @load.errors.full_messages.inspect
    assert @circuit.valid?, @circuit.errors.full_messages.inspect
  end

  test "fixtures should be valid" do
    circuits.each do |f|
      assert f.valid?, f.errors.full_messages.inspect
    end
  end



end
