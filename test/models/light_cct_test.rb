require "test_helper"

class LightCctTest < ActiveSupport::TestCase
  def setup
    @discipline = create(:discipline, code: 'E', name: 'Electrical')
    @project = create(:project)
    @tag = create(:tag, 
                 prefix: 'EL',
                 serial: 1,
                 description: 'TEST LIGHTS',
                 project: @project,
                 discipline: @discipline
               )
    @light_cct = create(:light_cct, 
                       light_fitting_type: 'standard',
                       quantity: 4,
                       tag: @tag
                      )
  end

  test "factory should be valid" do
    assert @light_cct.valid?
    assert @tag.valid?
    assert @light_cct.demand.valid?
  end

  test "should create light circuit with valid attributes" do
    light = build(:light_cct)
    assert light.valid?
  end

  test "should require light_fitting_type" do
    light = build(:light_cct, light_fitting_type: nil)
    assert_not light.valid?
    assert_includes light.errors[:light_fitting_type], "can't be blank"
  end

  test "should require quantity to be greater than 0" do
    light = build(:light_cct, quantity: 0)
    assert_not light.valid?
    assert_includes light.errors[:quantity], "must be greater than 0"
  end

  test "should create light circuit as tagable linked to existing tag" do
    tag = create(:tag, 
                prefix: 'EL',
                serial: 99,
                description: 'RECEPTION LIGHTS',
                project: @project,
                discipline: @discipline
              )
    
    assert_difference 'LightCct.count', 1 do
      light = create(:light_cct, 
                    light_fitting_type: :edison_screw,
                    quantity: 2,
                    tag: tag
                   )
      
      tag.reload
      assert_equal tag.tagable, light
      assert_equal tag.light_cct, light
    end
  end

  test "should create demand when creating light circuit" do
    # Create a unique tag to avoid uniqueness constraint
    unique_serial = 9999
    light = create(:light_cct, 
                  light_fitting_type: 'emergency',
                  quantity: 2,
                  tag_attributes: {
                    prefix: 'EL',
                    serial: unique_serial,
                    description: 'UNIQUE TEST LIGHT',
                    project: @project,
                    discipline: @discipline,
                    stage: 1
                  }
                 )
    assert light.demand.present?
    assert_equal light, light.demand.demandable
  end

  test "destroy light circuit should nullify tagable" do
    light_id = @light_cct.id
    @light_cct.destroy
    
    @tag.reload
    assert_nil @tag.tagable
    assert_nil @tag.tagable_type
    assert_nil @tag.tagable_id
  end

  test "destroy light circuit should destroy demand" do
    demand = @light_cct.demand
    assert_difference 'Demand.count', -1 do
      @light_cct.destroy
    end
    assert_raises(ActiveRecord::RecordNotFound) { demand.reload }
  end

  test "destroy tag should destroy light circuit" do
    light_id = @light_cct.id
    assert_difference 'LightCct.count', -1 do
      @tag.destroy
    end
    assert_raises(ActiveRecord::RecordNotFound) { LightCct.find(light_id) }
  end
  
  test "should have demand through demandable concern" do
    assert_respond_to @light_cct, :demand
    assert_kind_of Demand, @light_cct.demand
  end
  
  test "should have tag through tagable concern" do
    assert_respond_to @light_cct, :tag
    assert_equal @tag, @light_cct.tag
  end
  
  test "should have light_fitting_type attribute" do
    assert_respond_to @light_cct, :light_fitting_type
    assert_equal 'standard', @light_cct.light_fitting_type
  end
end
