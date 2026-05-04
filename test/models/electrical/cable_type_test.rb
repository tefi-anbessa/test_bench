# frozen_string_literal: true

require "test_helper"
require "helpers/discipline_model_tests"
class Electrical::CableTypeTest < ActiveSupport::TestCase
  include DisciplineModelTests

  def setup
    setup_common_test_data
    @resource = create(:electrical_cable_type, discipline: @discipline)
    @cable_type = @resource
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
          construction: "core",
          groups: 3,
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
          discipline: @discipline)
    end
    assert @ct.valid?
    assert_equal "Cu", @ct.conductor_material
    assert_equal 2.5, @ct.csa
    assert_equal "core", @ct.construction
    assert_equal 3, @ct.groups
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
    assert_equal @discipline, @ct.discipline
  end

  test "should require conductor_material" do
    cable_type = build(:electrical_cable_type, conductor_material: nil)
    refute cable_type.valid?
    assert_includes cable_type.errors[:conductor_material], I18n.t('errors.messages.blank')
  end

  test "should require groups" do
    cable_type = build(:electrical_cable_type, groups: nil)
    refute cable_type.valid?
    assert_includes cable_type.errors[:groups], I18n.t('errors.messages.blank')
  end

  test "should require csa" do
    cable_type = build(:electrical_cable_type, csa: nil, discipline: @discipline)
    refute cable_type.valid?
    assert_includes cable_type.errors[:csa], I18n.t('errors.messages.blank')
  end
  
  test "should require discipline" do
    cable_type = build(:electrical_cable_type, discipline: nil)
    refute cable_type.valid?
    assert_includes cable_type.errors[:discipline], I18n.t('errors.messages.required')
  end

  test "should allow same specifications in different disciplines" do
    # Create a cable type with discipline
    cable_type1 = create(:electrical_cable_type,
                        conductor_material: "Al",
                        construction: "core",
                        groups: 4,
                        csa: 10.0,
                        discipline: @discipline)
    assert_match(/~01\z/, cable_type1.code, "First type should get code suffix 01")
    # Create another project with discipline
    other_project = create(:project, code: 'CD')
    other_discipline = other_project.disciplines.find_by(name: "Electrical")

    # Same specs in different discipline should be valid and first code
    cable_type2 = create(:electrical_cable_type,
                       conductor_material: "Al",
                       construction: "core",
                       groups: 4,
                       csa: 10.0,
                       discipline: other_discipline)

    assert cable_type2.valid?
    assert_match(/~01\z/, cable_type2.code, "First code in other discipline should also be 01")

    # Duplicate in same discipline should have code with suffix 02
    cable_type3 = create(:electrical_cable_type,
                     conductor_material: "Al",
                     construction: "core",
                     groups: 4,
                     csa: 10.0,
                     discipline: @discipline)

    assert cable_type3.valid?
    assert_match(/~02\z/, cable_type3.code, "Duplicate type should get code suffix 02")
  end

  test "should be destroyed when associated discipline is destroyed" do
    cable_type = create(:electrical_cable_type, discipline: @discipline)
    # Destroys setup cable type and cable type created in this test.
    assert_difference 'Electrical::CableType.count', -2 do
      @discipline.destroy
    end

    refute Electrical::CableType.exists?(cable_type.id)
  end
  
  test "should generate code from attributes" do
    ct = create(:electrical_cable_type,
                  conductor_material: "Cu",
                  csa: 2.5,
                  construction: "core",
                  groups: 3,
                  neutral_csa: 2.5,
                  earth_csa: 1.5,
                  insulation: "XLPE",
                  bedding: "PVC",
                  armour: "GSWA",
                  discipline: @discipline)

    expected_pattern = %r{Cu~2.5mm²~3C\+N\+E\~XLPE~PVC~GSWA~PVC~450/750V~75˚C~01}
    assert_match expected_pattern, ct.code
  end
    
    # Test enum definitions
    test "should have enum attributes" do
      assert_respond_to @resource, :conductor_material
      assert_respond_to @resource, :Cu?
      assert_respond_to @resource, :insulation
      assert_respond_to @resource, :insulation_XLPE?
      assert_respond_to @resource, :bedding
      assert_respond_to @resource, :bedding_PVC?
      assert_respond_to @resource, :armour
      assert_respond_to @resource, :armour_GSWA?
      assert_respond_to @resource, :sheath
      assert_respond_to @resource, :sheath_PVC?
      assert_respond_to @resource, :voltage_rating
      assert_respond_to @resource, :'450/750V?'
      assert_respond_to @resource, :temperature_rating
      assert_respond_to @resource, :"75˚C?"
    end
end
