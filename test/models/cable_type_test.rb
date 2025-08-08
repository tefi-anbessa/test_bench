require "test_helper"

class CableTypeTest < ActiveSupport::TestCase
  def setup
    @cable_type = cable_types(:one)
    @cable = cables(:ec1)
  end

  test "fixtures should be valid" do
    cable_types.each do |f|
      assert f.valid?, f.errors.full_messages.inspect
    end
  end

  test "setup should be valid" do
    assert @cable_type.valid?, @cable_type.errors.full_messages.inspect
    assert_equal @cable.cable_type, @cable_type
  end

  test "create new cable type" do
    assert_difference 'CableType.count', 1 do
    CableType.create!(conductor_material: "copper",
                      conductor_makeup: "2C+E",
                      csa: 4,
                      insulation: "PVC",
                      bedding: "PVC",
                      armour: "GSWA",
                      sheath: "XLPE/nylon",
                      temperature_rating: 1)
    end
  end

  test "Conductor makeup must be present" do
    @cable_type.conductor_makeup = ""
    assert_not @cable_type.valid?
  end

  test "destroy cable" do
    assert_difference '@cable_type.cables.count', -1 do
      @cable.destroy
    end
  end

  test "destroy cable type should destroy associated cables" do
    count = @cable_type.cables.count
    assert_difference 'Cable.count', -count do
      @cable_type.destroy
    end
  end

end
