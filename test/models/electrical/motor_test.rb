require "test_helper"

class MotorTest < ActiveSupport::TestCase
  def setup
    @project = create(:project)
    @discipline_e = create(:discipline, :elec, project: @project)
    @tag = create(:tag, prefix: 'KM', serial: 99, service: 'FAN MOTOR', project: @project, stage: 9,
                    discipline: @discipline_e)
    @motor = create(:electrical_motor, tag: @tag,
                   motor_type: :induction,
                   frame_size: '132',
                   poles: 4,
                   ingress_protection: '55',
                   speed_rated: 1500.0
                 )
    @demand = create(:electrical_demand, demandable: @motor, basis: 'power_pf', basis_notes: 'Test basis notes 7',
      supply: 220.0, config: 'three_3c', power: 1000.0, duty: 0.5)
  end

  test "setup should be valid" do
    assert @project.valid?
    assert @discipline_e.valid?
    assert @discipline_e.project == @project
    assert @tag.valid?
    assert @tag.discipline == @discipline_e
    assert @tag.project == @project
    assert @motor.valid?
    assert @motor.tag == @tag
    assert @tag.tagable == @motor
    assert @motor.electrical_demand == @demand
    assert @demand.valid?
    assert @demand.demandable == @motor
    assert @demand.tag == @tag
  end

  test "factory default should create motor with valid attributes" do
    motor = build(:electrical_motor)
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

  test "should create motor as tagable linked to existing tag" do
    tag = create(:tag, 
                prefix: 'KM',
                serial: 100,
                service: 'FAN MOTOR',
                discipline: @discipline_e
              )
    
    assert_difference 'Electrical::Motor.count', 1 do
      motor = create(:electrical_motor, 
                    motor_type: :induction,
                    frame_size: '80',
                    poles: 2,
                    ingress_protection: '67',
                    speed_rated: 3000.0,
                    tag: tag
                  )
      
      tag.reload
      assert_equal tag.electrical_motor, motor
    end
  end

  test "destroy motor should nullify tagable" do
    @motor.destroy
    
    @tag.reload
    assert_nil @tag.tagable
    assert_nil @tag.tagable_type
    assert_nil @tag.tagable_id
  end

  test "destroy motor should destroy demand" do
    demand = @motor.electrical_demand
    assert_difference 'Electrical::Demand.count', -1 do
      @motor.destroy
    end
    assert_raises(ActiveRecord::RecordNotFound) { demand.reload }
  end

  test "destroy tag should destroy motor" do
    motor_id = @motor.id
    assert_difference 'Electrical::Motor.count', -1 do
      @tag.destroy
    end
    assert_raises(ActiveRecord::RecordNotFound) { Electrical::Motor.find(motor_id) }
  end
  
  test "should have electrical_demand through demandable concern" do
    assert_respond_to @motor, :electrical_demand
    assert @motor.electrical_demand.present?, 'Motor should have an electrical demand'
    assert_kind_of Electrical::Demand, @motor.electrical_demand
  end
  
  test "should have tag through tagable concern" do
    assert_respond_to @motor, :tag
    assert_equal @tag, @motor.tag
  end
end
