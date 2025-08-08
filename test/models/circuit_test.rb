require "test_helper"

class CircuitTest < ActiveSupport::TestCase
  self.use_instantiated_fixtures = true

  def setup
    @circuit = circuits(:pm)
    @load = loads(:pm)
    @cable = cables(:ec1)
    @swbd = switchboards(:ex4)
  end

  test "setup should be valid" do
    assert @load.valid?, @load.errors.full_messages.inspect
    assert @circuit.valid?, @circuit.errors.full_messages.inspect
    assert @cable.valid?, @cable.errors.full_messages.inspect
    assert_equal @load.circuit, @circuit
    assert_equal @cable.circuit, @circuit
    assert_includes(@swbd.circuits, @circuit)
  end

  test "fixtures should be valid" do
    circuits.each do |f|
      assert f.valid?, f.errors.full_messages.inspect
    end
  end

  test "create new circuit on parent switchboard" do
    assert_difference 'Circuit.count', 1 do
      @swbd.circuits.create!(serial: 1)
    end
    # ensure unique serial numbers for each board
    # only tests the  model validation, can't figure out how to test the database because the test throws the expected error.
    assert_not @swbd.circuits.new(serial: 1).valid?
  end

  test "destroy circuit should remove from switchboard" do
    assert_difference 'Circuit.count', -1 do
      @circuit.destroy
      assert_not_includes(@swbd.circuits, @circuit)
    end
  end

  test "destroy circuit should nullify references" do
    @circuit.destroy
    assert_nil @load.circuit
    assert_nil @cable.circuit
  end
end
