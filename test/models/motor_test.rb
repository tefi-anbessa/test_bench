require "test_helper"

class MotorTest < ActiveSupport::TestCase
  def setup
    @project = create(:project)
    @discipline_e = create(:discipline, :elec)
    @tag = create(:tag, prefix: 'KM', serial: 99, service: 'FAN MOTOR', project: @project, stage: 9,
                    discipline: @discipline_e)
    @motor = create(:motor, tag: @tag,
                   motor_type: :induction,
                   frame_size: '132',
                   poles: 4,
                   ingress_protection: '55',
                   speed_rated: 1500.0
                 )
    @demand = create(:demand, demandable: @motor, basis: 'power_pf', basis_notes: 'Test basis notes 7',
      supply: 220.0, config: 'three_3c', power: 1000.0, duty: 0.5)
  end

  test "factory should be valid" do
    assert @motor.valid?
    assert @tag.valid?
    assert @motor.demand.present?
    assert @motor.demand.valid?
  end

  test "factory default should create motor with valid attributes" do
    motor = build(:motor)
    assert motor.valid?
  end

  test "motor type must be present" do
    @motor.motor_type = nil
    refute @motor.valid?
    assert_includes @motor.errors[:motor_type], I18n.t("errors.messages.blank")
  end

  test "frame size must be present" do
    @motor.frame_size = nil
    refute @motor.valid?
    assert_includes @motor.errors[:frame_size], I18n.t("errors.messages.blank")
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
                serial: 100,
                service: 'FAN MOTOR',
                project: @project,
                discipline: @discipline_e
              )
    
    assert_difference 'Motor.count', 1 do
      motor = create(:motor, 
                    motor_type: :induction,
                    frame_size: '80',
                    poles: 2,
                    ingress_protection: '67',
                    speed_rated: 3000.0,
                    tag: tag
                  )
      
      tag.reload
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

  test "destroy motor should destroy demand" do
    demand = @motor.demand
    assert_difference 'Demand.count', -1 do
      @motor.destroy
    end
    assert_raises(ActiveRecord::RecordNotFound) { demand.reload }
  end

  test "destroy tag should destroy motor" do
    motor_id = @motor.id
    assert_difference 'Motor.count', -1 do
      @tag.destroy
    end
    assert_raises(ActiveRecord::RecordNotFound) { Motor.find(motor_id) }
  end
  
  test "should have demand through demandable concern" do
    assert_respond_to @motor, :demand
    assert @motor.demand.present?, 'Motor should have a demand'
    assert_kind_of Demand, @motor.demand
  end
  
  test "should have tag through tagable concern" do
    assert_respond_to @motor, :tag
    assert_equal @tag, @motor.tag
  end
end
