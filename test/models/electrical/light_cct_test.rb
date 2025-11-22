require "test_helper"

class LightCctTest < ActiveSupport::TestCase
  def setup
    @project = create(:project)
    @discipline = create(:discipline, :elec, project: @project)
    @tag = create(:tag, 
                 prefix: 'EL',
                 serial: 1,
                 service: 'TEST LIGHTS',
                 discipline: @discipline
               )
    @light_cct = create(:electrical_light_cct, 
                       light_fitting_type: :general,
                       quantity: 4,
                       tag: @tag
                      )
    @demand = create(:electrical_demand, demandable: @light_cct, basis: 'power_pf', 
                    basis_notes: 'Test basis notes 7',
                    supply: 220.0, config: 'three_3c', power: 1000.0, duty: 0.5)
  end

  test "setup should be valid" do
    assert @project.valid?
    assert @discipline.valid?
    assert_equal @project, @discipline.project
    assert @tag.valid?
    assert_equal @project, @tag.project
    assert_equal @discipline, @tag.discipline
    assert @light_cct.valid?
    assert_equal @tag, @light_cct.tag
    assert @demand.valid?
    assert_equal @light_cct, @demand.demandable
    assert_equal @tag, @demand.tag
  end

  test "factory default should create light circuit with valid attributes" do
    light = build(:electrical_light_cct)
    assert light.valid?
  end

  test "light_fitting_type must be present" do
    @light_cct.light_fitting_type = nil
    assert_not @light_cct.valid?
    assert_includes @light_cct.errors[:light_fitting_type], I18n.t("errors.messages.blank")
  end

  test "quantity must be present" do
    @light_cct.quantity = nil
    assert_not @light_cct.valid?
    assert_includes @light_cct.errors[:quantity], I18n.t("errors.messages.not_a_number")
  end

  test "should require quantity to be greater than 0" do
    @light_cct.quantity = 0
    assert_not @light_cct.valid?
    assert_includes @light_cct.errors[:quantity], I18n.t("errors.messages.greater_than", count: 0)
  end

  test "should create light circuit as tagable linked to existing tag" do
    tag = create(:tag, 
                prefix: 'EL',
                serial: 99,
                service: 'RECEPTION LIGHTS',
                discipline: @discipline
              )
    
    assert_difference 'Electrical::LightCct.count', 1 do
      light = create(:electrical_light_cct, 
                    light_fitting_type: :outdoor,
                    quantity: 2,
                    tag: tag
                   )
      
      tag.reload
      assert_equal tag.tagable, light
      assert_equal tag.electrical_light_cct, light
    end
  end

  # Demand creation is tested separately in Demand model tests

  test "destroy light circuit should nullify tagable" do
    @light_cct.destroy
    
    @tag.reload
    assert_nil @tag.tagable
    assert_nil @tag.tagable_type
    assert_nil @tag.tagable_id
  end

  # Demand destruction is tested separately in Demand model tests

  test "destroy tag should destroy light circuit" do
    light_id = @light_cct.id
    assert_difference 'Electrical::LightCct.count', -1 do
      @tag.destroy
    end
    assert_raises(ActiveRecord::RecordNotFound) { Electrical::LightCct.find(light_id) }
  end
end
