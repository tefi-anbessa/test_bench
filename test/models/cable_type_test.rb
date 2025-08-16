require "test_helper"

class CableTypeTest < ActiveSupport::TestCase
  def setup
    @cable_type = create(:cable_type)
  end

  test "factory should be valid" do
    assert @cable_type.valid?
  end

  test "should create new cable type with required attributes" do
    assert_difference 'CableType.count', 1 do
      create(:cable_type, 
             conductor_material: "copper",
             conductor_makeup: "2C+E",
             csa: 4)
    end
  end

  test "should create new cable type with all attributes" do
    assert_difference 'CableType.count', 1 do
      create(:cable_type, 
             conductor_material: "copper",
             conductor_makeup: "3C+E",
             csa: 6.0,
             insulation: "XLPE",
             bedding: "PVC",
             armour: "GSWA",
             sheath: "PVC",
             temperature_rating: 1,
             neutral_csa: 6.0,
             earth_csa: 4.0,
             bedding_od: 12.5,
             overall_od: 14.5)
    end
  end

  test "should require conductor_material" do
    cable_type = build(:cable_type, conductor_material: nil)
    assert_not cable_type.valid?
    assert_includes cable_type.errors[:conductor_material], "can't be blank"
  end

  test "should require conductor_makeup" do
    cable_type = build(:cable_type, conductor_makeup: nil)
    assert_not cable_type.valid?
    assert_includes cable_type.errors[:conductor_makeup], "can't be blank"
  end

  test "should require csa" do
    cable_type = build(:cable_type, csa: nil)
    assert_not cable_type.valid?
    assert_includes cable_type.errors[:csa], "can't be blank"
  end

  test "should enforce unique combination of specifications" do
    create(:cable_type, 
           conductor_material: "aluminum",
           conductor_makeup: "4C+E",
           csa: 10.0)
           
    duplicate = build(:cable_type,
                     conductor_material: "aluminum",
                     conductor_makeup: "4C+E",
                     csa: 10.0)
                     
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:base], "A cable type with these specifications already exists"
  end

  test "traits should work correctly" do
    flat_twin = create(:cable_type, :pvc_flat_twin_earth)
    assert_equal "2C+E", flat_twin.conductor_makeup
    assert_equal 1.5, flat_twin.csa
    assert_equal "PVC", flat_twin.insulation
    assert_nil flat_twin.armour
    assert_match /1.5mm² copper 2C\+E PVC Cable/, flat_twin.description

    swa = create(:cable_type, :swa)
    assert_equal "3C+E", swa.conductor_makeup
    assert_equal 6.0, swa.csa
    assert_equal "GSWA", swa.armour
    assert_match /6.0mm² copper 3C\+E Steel Wire Armoured Cable/, swa.description
  end
  
  test "description should be generated correctly" do
    cable_type = create(:cable_type,
      conductor_material: "Copper",
      conductor_makeup: "4C+E",
      csa: 2.5,
      insulation: "XLPE",
      armour: "GSWA"
    )
    
    assert_match /2.5mm² copper 4C\+E Steel Wire Armoured Cable/, cable_type.description
    
    # Test that description is updated when attributes change
    cable_type.update(csa: 4.0)
    assert_match /4.0mm² copper 4C\+E Steel Wire Armoured Cable/, cable_type.reload.description
  end
end
