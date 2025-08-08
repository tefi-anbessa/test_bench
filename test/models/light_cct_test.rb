require "test_helper"

class LightCctTest < ActiveSupport::TestCase

  def setup
    @tag = tags(:el)
    @light_cct = light_ccts(:el)
    @load = loads(:el)
  end

  test "fixtures should be valid" do
    light_ccts.each do |t|
      assert t.valid?, t.errors.full_messages.inspect
    end
  end

  test "setup should be valid" do
    assert @tag.valid?
    assert @light_cct.valid?
    assert_equal @tag.tagable, @light_cct
  end

  test "create light circuit as tagable linked to existing tag" do
    @el_new = Tag.create(prefix: "EL",
                    serial: 99,
                    suffix: "",
                    description: "RECEPTION LIGHTS",
                    project: projects(:ab),
                    stage: 1,
                    notes: "lights test",
                    discipline: disciplines(:e)
                  )
    assert @el_new.valid?
    assert @el_new.persisted?
    assert_difference 'LightCct.count', 1 do
      @el_new.update(tagable: LightCct.new(
                  light_fitting_type: "edison screw",
                  quantity: 2
                  )
                )
      end
    assert_equal @el_new.tagable, @el_new.light_cct
    assert_difference 'Load.count', 1 do
      @el_new.light_cct.create_load(
                    basis: 2,
                    basis_notes: "current and pf provided",
                    supply: 240.0,
                    config: "one",
                    power: 100.0,
                    power_factor: 1.0,
                    duty: 0.1)
    end
  end

  test "destroy light circuit should nullify tagable" do
    @light_cct.destroy
    @tag.reload
    assert_nil @tag.tagable
  end

  test "destroy light circuit should destroy load" do
    assert_difference 'Load.count', -1 do
      @light_cct.destroy
    end
  end

  test "destroy tag should destroy light circuit" do
    assert_difference 'LightCct.count', -1 do
      @tag.destroy
    end
  end

end
