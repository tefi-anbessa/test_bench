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
            project: @project,
             conductor_material: "Cu",
             cores: 2,
             csa: 4)
    end
  end

  test "should require conductor_material" do
    cable_type = build(:cable_type, conductor_material: nil)
    refute cable_type.valid?
    assert_includes cable_type.errors[:conductor_material], "can't be blank"
  end

  test "should require cores" do
    cable_type = build(:cable_type, cores: nil)
    refute cable_type.valid?
    assert_includes cable_type.errors[:cores], "can't be blank"
  end

  test "should require csa" do
    cable_type = build(:cable_type, csa: nil, project: @project)
    refute cable_type.valid?
    assert_includes cable_type.errors[:csa], "can't be blank"
  end
  
  test "should require project" do
    cable_type = build(:cable_type, project: nil)
    refute cable_type.valid?
    assert_includes cable_type.errors[:project], "must exist"
  end

  test "should allow same specifications in different projects" do
    # Create a cable type with project
    cable_type1 = create(:cable_type, 
                        conductor_material: "Al",
                        cores: 4,
                        csa: 10.0,
                        project: @project)
    assert_match(/~01\z/, cable_type1.code, "First type should get code suffix 01")
    # Create another project
    other_project = create(:project, code: 'CD')
    
    # Same specs in different project should be valid and first code
    cable_type2 = create(:cable_type,
                       conductor_material: "Al",
                       cores: 4,
                       csa: 10.0,
                       project: other_project)
    
    assert cable_type2.valid?
    assert_match(/~01\z/, cable_type2.code, "First code in other project should also be 01")
    
    # Duplicate in same project should have code with suffix 02
    cable_type3 = create(:cable_type,
                     conductor_material: "Al",
                     cores: 4,
                     csa: 10.0,
                     project: @project)
    
    assert cable_type3.valid?
    assert_match(/~02\z/, cable_type3.code, "Duplicate type should get code suffix 02")
  end

  test "should be destroyed when associated project is destroyed" do
    cable_type = create(:cable_type, project: @project)
    
    assert_difference 'CableType.count', -2 do # Destroys setup cable and cable created in this test.
      @project.destroy
    end
    
    refute CableType.exists?(cable_type.id)
  end
  
  test "should generate code from attributes" do
    ct = create(:cable_type, 
                  conductor_material: "Cu",
                  csa: 2.5,
                  cores: 3,
                  neutral_csa: 2.5,
                  earth_csa: 1.5,
                  insulation: "XLPE",
                  bedding: "PVC",
                  armour: "GSWA",
                  project: @project)
    
    expected_pattern = %r{Cu~2.5mm²~3C\+N\(2.5\)\+E\(1.5\)~XLPE~PVC~GSWA~PVC~450/750V~75˚C~01}
    assert_match expected_pattern, ct.code
  end
end
