require "test_helper"

class CableTest < ActiveSupport::TestCase
  def setup
    @cable = cables(:ec1)
    @tag = @cable.tag
    @circuit = @cable.circuit
  end

  test "setup should be valid" do
    assert @cable.valid?, @cable.errors.full_messages.inspect
    assert @tag.valid?, @tag.errors.full_messages.inspect
    assert @circuit.valid?, @circuit.errors.full_messages.inspect
  end

  test "fixtures should be valid" do
    cables.each do |f|
      assert f.valid?, f.errors.full_messages.inspect
    end
  end

  test "create cable as tagable linked to existing tag" do
    @ec6 = Tag.create(prefix: "EC",
                    serial: 6,
                    suffix: "",
                    description: "WATER PACKAGE FEEDER",
                    project: projects(:ab),
                    stage: 1,
                    notes: "CABLE TEST",
                    discipline: disciplines(:e)
                  )
    assert @ec6.valid?
    assert @ec6.persisted?
    assert_difference 'Cable.count', 1 do
      @ec6.update(tagable: Cable.new(
                  cable_type: cable_types(:one),
                  route_length: 9.99,
                  vertical_allowance: 2.0,
                  termination_allowance: 5.0,
                  start_mark: 1,
                  end_mark: 10)
                )
      end
    assert_equal @ec6.tagable, @ec6.cable
  end

  test "destroy cable should nullify tagable and circuit" do
    @cable.destroy
    @tag.reload
    assert_not_nil @tag
    assert_nil @tag.tagable
    @circuit.reload
    assert_not_nil @circuit
    assert_nil @circuit.cable
  end

  test "destroy tag should destroy cable" do
    assert_difference 'Cable.count', -1 do
      @tag.destroy
    end
  end

    test "destroy circuit should nullify circuit in cable" do
      assert_no_difference 'Cable.count' do
        @circuit.destroy
        @cable.reload
        assert_nil @cable.circuit
      end
    end
end
