require "test_helper"

class SwitchboardTest < ActiveSupport::TestCase

  def setup
    @tag = tags(:ex2)
    @switchboard = @tag.switchboard
  end

  test "fixtures should be valid" do
    switchboards.each do |f|
      assert f.valid?, f.errors.full_messages.inspect
    end
  end

  test "setup should be valid" do
    assert @tag.valid?
    assert @switchboard.valid?, @switchboard.errors.full_messages.inspect
  end

  test "create switchboard as tagable linked to existing tag" do
    @ex5 = Tag.create(prefix: "EX",
                    serial: 5,
                    suffix: "",
                    description: "DUMMY SWITCHBOARD",
                    project: projects(:ab),
                    stage: 1,
                    notes: "SWBD TEST",
                    discipline: disciplines(:e)
                  )
    assert @ex5.valid?
    assert @ex5.persisted?
    assert_difference 'Switchboard.count', 1 do
      @ex5.update(tagable: Switchboard.new(
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
    assert_equal @ex5.tagable, @ex5.switchboard
  end

  test "destroy switchboard should nullify tagable" do
    @switchboard.destroy
    @tag.reload
    assert_nil @tag.tagable
  end

  test "destroy tag should destroy switchboard" do
    assert_difference 'Switchboard.count', -1 do
      @tag.destroy
    end
  end

  test "destroy switchboard should destroy associated circuits" do
    assert_difference 'Circuit.count', -1 do
      @switchboard.destroy
    end
  end

end
