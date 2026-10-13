# frozen_string_literal: true

require "test_helper"
class CableTypeTest < ActiveSupport::TestCase
  def setup
    @project = create(:project, title: "CableType Model Test")
    @discipline = @project.disciplines.find_by(code: "E")
    @instrument_discipline = @project.disciplines.find_by(code: "J")
    @resource = create(:electrical_cable_type, discipline: @discipline)
    @cable_type = @resource
  end

  test "factory default should create valid cable type" do
    cable_type = build(:electrical_cable_type)
    assert cable_type.valid?
  end

  test "instrument factory default should create valid cable type" do
    cable_type = build(:instrument_cable_type)
    assert cable_type.valid?
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

  test "should require primary_role" do
    cable_type = build(:electrical_cable_type, primary_role: nil)
    refute cable_type.valid?
    assert_includes cable_type.errors[:primary_role], I18n.t('errors.messages.blank')
  end

  test "should require discipline" do
    cable_type = build(:electrical_cable_type, discipline: nil)
    refute cable_type.valid?
    assert_includes cable_type.errors[:discipline], I18n.t('errors.messages.required')
  end

  test "should require a detail" do
    cable_type = build(:electrical_cable_type)
    cable_type.detail = nil
    refute cable_type.valid?
    assert_includes cable_type.errors[:detail], I18n.t('errors.messages.blank')
  end

  test "should reject a detail that does not match the discipline's own module" do
    cable_type = build(:electrical_cable_type, discipline: @discipline)
    cable_type.detail = Instrument::CableTypeDetail.new(individual_screen: true)
    refute cable_type.valid?
    assert_includes cable_type.errors[:detail],
      I18n.t("activerecord.errors.models.cable_type.attributes.detail.discipline_mismatch")
  end

  test "should resolve delegated detail correctly" do
    assert @cable_type.electrical_cable_type_detail?
    assert_kind_of Electrical::CableTypeDetail, @cable_type.detail
    assert_equal @cable_type.detail, @cable_type.electrical_cable_type_detail
  end

  test "destroying a cable type also destroys its delegated detail" do
    detail_id = @cable_type.detail.id
    @cable_type.destroy
    refute Electrical::CableTypeDetail.exists?(detail_id)
  end

  test "should generate a code from primary_role and a per-discipline sequence" do
    ct1 = create(:electrical_cable_type, discipline: @discipline)
    assert_match(/\APD-\d{3}\z/, ct1.code)
    ct2 = create(:electrical_cable_type, discipline: @discipline)
    assert_match(/\APD-\d{3}\z/, ct2.code)
    refute_equal ct1.code, ct2.code
  end

  test "code sequence starts over in a different discipline" do
    # A fresh discipline with no prior cable types of this primary_role
    # should start its own sequence at 001, same as @discipline's own
    # first one did in #setup - regardless of how far @discipline's own
    # sequence has since moved on.
    other_project = create(:project, code: 'CD')
    other_discipline = other_project.disciplines.find_by(code: "E")
    ct = create(:electrical_cable_type, discipline: other_discipline)

    assert_equal @cable_type.code, ct.code
  end

  test "code sequence differs by primary_role prefix" do
    power_ct = create(:electrical_cable_type, discipline: @discipline, primary_role: :power_distribution)
    signal_ct = create(:instrument_cable_type, discipline: @instrument_discipline, primary_role: :analog_signal)
    assert_match(/\APD-/, power_ct.code)
    assert_match(/\ASIG-/, signal_ct.code)
  end

  test "should be destroyed when associated discipline is destroyed" do
    create(:electrical_cable_type, discipline: @discipline)
    # Destroys setup cable type (from #setup) and the one created in this test.
    assert_difference 'CableType.count', -2 do
      @discipline.destroy
    end
    refute CableType.exists?(@cable_type.id)
  end

  test "should have enum attributes" do
    assert_respond_to @resource, :conductor_material
    assert_respond_to @resource, :Cu?
    assert_respond_to @resource, :insulation
    assert_respond_to @resource, :insulation_XLPE?
    assert_respond_to @resource, :bedding
    assert_respond_to @resource, :bedding_PVC?
    assert_respond_to @resource, :armour
    assert_respond_to @resource, :armour_SWA?
    assert_respond_to @resource, :sheath
    assert_respond_to @resource, :sheath_PVC?
    assert_respond_to @resource, :voltage_rating
    assert_respond_to @resource, :'450/750V?'
    assert_respond_to @resource, :temperature_rating
    assert_respond_to @resource, :"75˚C?"
    assert_respond_to @resource, :primary_role
    assert_respond_to @resource, :primary_role_power_distribution?
    assert_respond_to @resource, :fire_protection
  end
end
