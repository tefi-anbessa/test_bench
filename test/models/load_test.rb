require "test_helper"

class LoadTest < ActiveSupport::TestCase

  def setup
    # Set up test variables from fixtures
    @tag = tags(:ex2)
    @swbd = switchboards(:ex2)
    @load = loads(:ex2)
  end

  test "fixtures should be valid" do
    loads.each do |f|
      assert f.valid?, f.errors.full_messages.inspect
    end
  end

  test "setup should be valid" do
    assert @load.valid?, @load.errors.full_messages.inspect
    assert_equal @tag.switchboard, @swbd
    assert_equal @swbd.load, @load
  end

  # Set up test variables for new loads.
  test "create new load as loadable linked to existing tagable" do
    @new_tag = Tag.create!(prefix: "EX",
                    serial: 6,
                    suffix: "",
                    description: "VISITOR CENTRE DISTRIBUTION BOARD",
                    project: projects(:ab),
                    stage: 1,
                    notes: "Load test",
                    discipline: disciplines(:e)
                  )
    assert @new_tag.valid?
    assert @new_tag.persisted?
    assert_difference 'Switchboard.count', 1 do
      @new_tag.update(tagable: Switchboard.new(
        location:                   "Gatehouse",
        service:                    "Indoor tropical environment",
        ingress_protection:         "IP22",
        busbar_rating:              200.0,
        busbar_fault_rating:        5000.0,
        busbar_fault_duration:      0.5,
        cable_entry:                "Bottom",
        incomer_protection:         "None",
        metering:                   "VOLTS (SWITCH TO ANY PHASE)",
        neutral_bar_connections:    "1 x 50 mm2, 1 X 35 mm2, 1 x 10 mm2, 2 x 150 mm2",
        earth_bar_connections:      "9 X 2.5 mm2, 6 X 4 mm2, 2 x 150 mm2"
        )
      )
    end
    assert_equal @new_tag.tagable, @new_tag.switchboard
    @new_swbd = @new_tag.switchboard
    assert_difference 'Load.count', 1 do
      @new_swbd.create_load(basis: 2,
                      basis_notes: "power and pf provided",
                      supply: 240.0,
                      config: "three_4c",
                      power: 1500.0,
                      power_factor: 0.6,
                      duty: 0.1)
    end
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
    @pm = loads(:pm)
    @pm.save
    assert_equal @pm.power / (3 * @pm.supply * @pm.power_factor), @pm.current
  end

end
