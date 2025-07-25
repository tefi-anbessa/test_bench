require "test_helper"

class CableTypeTest < ActiveSupport::TestCase
  def setup
    @cable_type = CableType.new(conductor_material: "copper",
                                          conductor_makeup: "2C+E",
                                          csa: 4,
                                          insulation: "PVC",
                                          bedding: "PVC",
                                          armour: "GSWA",
                                          sheath: "XLPE/nylon",
                                          temperature_rating: 1)
  end

  test "fixtures should be valid" do
    cable_types.each do |f|
      assert f.valid?, f.errors.full_messages.inspect
    end
  end

  test "setup should be valid" do
    assert @cable_type.valid?, @cable_type.errors.full_messages.inspect
  end

  test "Conductor makeup must be present" do
    @cable_type.conductor_makeup = ""
    assert_not @cable_type.valid?
  end
=begin
=end
end
