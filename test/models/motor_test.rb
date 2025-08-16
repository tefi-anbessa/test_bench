require "test_helper"

class MotorTest < ActiveSupport::TestCase
  def setup
    @project = create(:project)
    @discipline = create(:discipline, code: 'E', name: 'Electrical')
    @tag = create(:tag, 
                 prefix: 'KM',
                 serial: 1,
                 description: 'TEST MOTOR',
                 project: @project,
                 discipline: @discipline
               )
    @motor = create(:motor, 
                   motor_type: 'Induction',
                   frame_size: '132L',
                   poles: 4,
                   ingress_protection: 'IP55',
                   speed_rated: 1500.0,
                   tag: @tag
                 )
  end

  test "factory should be valid" do
    assert @motor.valid?
    assert @tag.valid?
    assert @motor.load.valid?
  end

  test "should create motor with valid attributes" do
    motor = build(:motor)
    assert motor.valid?
  end

  # Note: The Motor model currently doesn't have any validations.
  # If you add validations in the future, you can uncomment and update this test.
  # test "should require motor_type when validations are added" do
  #   motor = build(:motor, motor_type: nil)
  #   assert_not motor.valid?
  #   assert_includes motor.errors[:motor_type], "can't be blank"
  # end

  test "should create motor as tagable linked to existing tag" do
    tag = create(:tag, 
                prefix: 'KM',
                serial: 99,
                description: 'FAN MOTOR',
                project: @project,
                discipline: @discipline
              )
    
    assert_difference 'Motor.count', 1 do
      motor = create(:motor, 
                    motor_type: 'Induction',
                    frame_size: '80L',
                    poles: 2,
                    ingress_protection: 'IP67',
                    speed_rated: 3000.0,
                    tag: tag
                  )
      
      tag.reload
      assert_equal tag.tagable, motor
      assert_equal tag.motor, motor
    end
  end

  test "destroy motor should nullify tagable" do
    motor_id = @motor.id
    @motor.destroy
    
    @tag.reload
    assert_nil @tag.tagable
    assert_nil @tag.tagable_type
    assert_nil @tag.tagable_id
  end

  test "destroy motor should destroy load" do
    load = @motor.load
    assert_difference 'Load.count', -1 do
      @motor.destroy
    end
    assert_raises(ActiveRecord::RecordNotFound) { load.reload }
  end

  test "destroy tag should destroy motor" do
    motor_id = @motor.id
    assert_difference 'Motor.count', -1 do
      @tag.destroy
    end
    assert_raises(ActiveRecord::RecordNotFound) { Motor.find(motor_id) }
  end
  
  test "should have load through loadable concern" do
    assert_respond_to @motor, :load
    assert_kind_of Load, @motor.load
  end
  
  test "should have tag through tagable concern" do
    assert_respond_to @motor, :tag
    assert_equal @tag, @motor.tag
  end
end
