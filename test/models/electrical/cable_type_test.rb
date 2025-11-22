require "test_helper"

class Electrical::CableTypeTest < ActiveSupport::TestCase
  def setup
    @project = create(:project)
    @cable_type = create(:electrical_cable_type, project: @project)
  end

  test "setup should be valid" do
    assert @project.valid?
    assert @cable_type.valid?
  end

  test "factory default should create valid cable type" do
    cable_type = create(:electrical_cable_type)
    assert cable_type.valid?
  end
  
  test "factory should create new cable type with all required attributes" do
    assert_difference 'Electrical::CableType.count', 1 do
      @ct = create(:electrical_cable_type, 
          conductor_material: "Cu",
          csa: 2.5,
          cores: 3,
          neutral_csa: 2.5,
          earth_csa: 1.5,
          insulation: "XLPE",
          bedding: "PVC",
          armour: "GSWA",
          sheath: "PVC",
          voltage_rating: "450/750V",
          temperature_rating: "75˚C",
          bedding_od: 10,
          overall_od: 12,
          project: @project)
    end
    assert @ct.valid?
    assert_equal "Cu", @ct.conductor_material
    assert_equal 2.5, @ct.csa
    assert_equal 3, @ct.cores
    assert_equal 2.5, @ct.neutral_csa
    assert_equal 1.5, @ct.earth_csa
    assert_equal "XLPE", @ct.insulation
    assert_equal "PVC", @ct.bedding
    assert_equal "GSWA", @ct.armour
    assert_equal "PVC", @ct.sheath
    assert_equal "450/750V", @ct.voltage_rating
    assert_equal "75˚C", @ct.temperature_rating
    assert_equal 10, @ct.bedding_od
    assert_equal 12, @ct.overall_od
    assert_equal @project, @ct.project
  end

  test "should require conductor_material" do
    cable_type = build(:electrical_cable_type, conductor_material: nil)
    refute cable_type.valid?
    assert_includes cable_type.errors[:conductor_material], I18n.t('errors.messages.blank')
  end

  test "should require cores" do
    cable_type = build(:electrical_cable_type, cores: nil)
    refute cable_type.valid?
    assert_includes cable_type.errors[:cores], I18n.t('errors.messages.blank')
  end

  test "should require csa" do
    cable_type = build(:electrical_cable_type, csa: nil, project: @project)
    refute cable_type.valid?
    assert_includes cable_type.errors[:csa], I18n.t('errors.messages.blank')
  end
  
  test "should require project" do
    cable_type = build(:electrical_cable_type, project: nil)
    refute cable_type.valid?
    assert_includes cable_type.errors[:project], I18n.t('errors.messages.required')
  end

  test "should allow same specifications in different projects" do
    # Create a cable type with project
    cable_type1 = create(:electrical_cable_type, 
                        conductor_material: "Al",
                        cores: 4,
                        csa: 10.0,
                        project: @project)
    assert_match(/~01\z/, cable_type1.code, "First type should get code suffix 01")
    # Create another project
    other_project = create(:project, code: 'CD')
    
    # Same specs in different project should be valid and first code
    cable_type2 = create(:electrical_cable_type,
                       conductor_material: "Al",
                       cores: 4,
                       csa: 10.0,
                       project: other_project)
    
    assert cable_type2.valid?
    assert_match(/~01\z/, cable_type2.code, "First code in other project should also be 01")
    
    # Duplicate in same project should have code with suffix 02
    cable_type3 = create(:electrical_cable_type,
                     conductor_material: "Al",
                     cores: 4,
                     csa: 10.0,
                     project: @project)
    
    assert cable_type3.valid?
    assert_match(/~02\z/, cable_type3.code, "Duplicate type should get code suffix 02")
  end

  test "should be destroyed when associated project is destroyed" do
    cable_type = create(:electrical_cable_type, project: @project)
    # Destroys setup cable type and cable type created in this test.
    assert_difference 'Electrical::CableType.count', -2 do 
      @project.destroy
    end
    
    refute Electrical::CableType.exists?(cable_type.id)
  end
  
  test "should generate code from attributes" do
    ct = create(:electrical_cable_type, 
                  conductor_material: "Cu",
                  csa: 2.5,
                  cores: 3,
                  neutral_csa: 2.5,
                  earth_csa: 1.5,
                  insulation: "XLPE",
                  bedding: "PVC",
                  armour: "GSWA",
                  project: @project)
    
    expected_pattern = %r{Cu~2.5mm²~3C\+N\+E\~XLPE~PVC~GSWA~PVC~450/750V~75˚C~01}
    assert_match expected_pattern, ct.code
  end
end
