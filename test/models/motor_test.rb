require "test_helper"

class MotorTest < ActiveSupport::TestCase

  def setup
    @tag = tags(:pm)
    @motor = motors(:pm)
    @load = loads(:pm)
  end

  test "fixtures should be valid" do
    motors.each do |t|
      assert t.valid?, t.errors.full_messages.inspect
    end
  end

  test "setup should be valid" do
    assert @tag.valid?
    assert @motor.valid?
    assert @load.valid?
    assert_equal @tag.motor, @motor
    assert_equal @tag.motor.load, @load
  end

  test "create motor as tagable linked to existing tag" do
    @km = Tag.create(prefix: "KM",
                    serial: 99,
                    suffix: "",
                    description: "FAN MOTOR",
                    project: projects(:ab),
                    stage: 1,
                    notes: "motor test",
                    discipline: disciplines(:e)
                  )
    assert @km.valid?
    assert @km.persisted?
    assert_difference 'Motor.count', 1 do
      @km.update(tagable: Motor.new(motor_type: "induction",
                  frame_size: "80",
                  poles: 2,
                  ingress_protection: "67",
                  speed_rated: 1500.0)
                )
      end
    assert_equal @km.tagable, @km.motor
  end

  test "destroy motor should nullify tagable" do
    @motor.destroy
    assert_not_nil @tag.reload
    assert_nil @tag.tagable
  end

  test "destroy motor should destroy load" do
    assert_difference 'Load.count', -1 do
      @motor.destroy
    end
  end

  test "destroy tag should destroy motor" do
    assert_difference 'Motor.count', -1 do
      @tag.destroy
    end
  end
end
