require "test_helper"

class LoadTest < ActiveSupport::TestCase
  self.use_instantiated_fixtures = true

  def setup
    @tag = tags(:ex2)
    @load = @tag.build_tagable(basis: 2,
                      basis_notes: "power and pf provided",
                      supply: 240.0,
                      config: "three_4c",
                      power: 1500.0,
                      power_factor: 0.6,
                      duty: 0.1)
  end

  test "fixtures should be valid" do
    loads.each do |f|
      assert f.valid?, f.errors.full_messages.inspect
    end
  end

  test "setup should be valid" do
    assert @load.valid?, @load.errors.full_messages.inspect
  end

  test "non-standard supply should override blank" do
    @load.supply = ""
    @load.other_supply = 250.0
    assert @load.valid?
    assert_equal 250.0, @load.supply
  end

  test "configuration should be present" do
    @load.config = nil
    refute @load.valid?
  end

  test "supply should be positive" do
    @load.supply = 0.0
    refute @load.valid?
    @load.supply = -240.0
    refute @load.valid?
  end

  test "power_factor should be in valid range" do
    @load.power_factor = 0.0
    refute @load.valid?
    @load.power_factor = 1.01
    refute @load.valid?
    @load.power_factor = -1.01
    refute @load.valid?
  end

  test "load calculator should work" do
    @load.save
    assert_equal @load.power / (3 * @load.supply * @load.power_factor),@load.current
  end

end
