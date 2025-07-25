require "test_helper"

class SwitchboardTest < ActiveSupport::TestCase

  def setup

    @load = loads(:ex2)
    @switchboard = @load.build_loadable(
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
  end

  test "fixtures should be valid" do
    switchboards.each do |f|
      assert f.valid?, f.errors.full_messages.inspect
    end
  end

  test "setup should be valid" do
    assert @switchboard.valid?, @switchboard.errors.full_messages.inspect
  end

end
