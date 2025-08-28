require "test_helper"

class CableTypeTest < ActiveSupport::TestCase
  def setup
    @project = create(:project)
    @cable_type = create(:cable_type, project: @project)
  end

  test "factory should be valid" do
    assert @cable_type.valid?
  end

  test "should create new cable type with required attributes" do
    assert_difference 'CableType.count', 1 do
      create(:cable_type, 
             conductor_material: "copper",
             conductor_makeup: "2C+E",
             csa: 4,
             project: @project)
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
    cable_type = build(:cable_type, csa: nil, project: @project)
    assert_not cable_type.valid?
    assert_includes cable_type.errors[:csa], "can't be blank"
  end
  
  test "should require project" do
    cable_type = build(:cable_type, project: nil)
    assert_not cable_type.valid?
    assert_includes cable_type.errors[:project], "must exist"
  end

  test "should allow same specifications in different projects" do
    # Create a cable type with project
    cable_type1 = create(:cable_type, 
                        conductor_material: "aluminum",
                        conductor_makeup: "4C+E",
                        csa: 10.0,
                        project: @project)
    
    # Create another project
    other_project = create(:project, code: 'CD')
    
    # Same specs in different project should be valid
    cable_type2 = build(:cable_type,
                       conductor_material: "aluminum",
                       conductor_makeup: "4C+E",
                       csa: 10.0,
                       project: other_project)
    
    assert cable_type2.valid?
    
    # Duplicate in same project should be invalid
    duplicate = build(:cable_type,
                     conductor_material: "aluminum",
                     conductor_makeup: "4C+E",
                     csa: 10.0,
                     project: @project)
    
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:base], 
                  "A cable type with these specifications already exists"
  end

  test "should be destroyed when associated project is destroyed" do
    project = create(:project)
    cable_type = create(:cable_type, project: project)
    
    assert_difference 'CableType.count', -1 do
      project.destroy
    end
    
    assert_not CableType.exists?(cable_type.id)
  end
  
  test "traits should work correctly" do
    flat_twin = create(:cable_type, :pvc_flat_twin_earth, project: @project)
    assert_equal @project, flat_twin.project
    assert_equal "2C+E", flat_twin.conductor_makeup
    assert_equal 1.5, flat_twin.csa
    assert_equal "PVC", flat_twin.insulation
    assert_nil flat_twin.armour
    assert_match /1.5mm² copper 2C\+E PVC Cable/, flat_twin.description
    
    swa = create(:cable_type, :swa, project: @project)
    assert_equal @project, swa.project
    assert_equal "GSWA", swa.armour
    assert_match /Steel Wire Armoured Cable/, swa.description
  end
  
  test "should generate description from attributes" do
    cable = create(:cable_type, 
                  conductor_material: "Copper",
                  conductor_makeup: "4C+E",
                  csa: 2.5,
                  insulation: "PVC",
                  armour: "GSWA",
                  project: @project)
    
    assert_match /2.5mm² copper 4C\+E Steel Wire Armoured Cable/, cable.description
  end
end
