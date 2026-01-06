module Electrical
  class Heater < Base
    include Tagable
    include TagableNavigation
    
# enum declarations
    enum :heater_type, Constants.electrical.heater.heater_type.to_h
    enum :application, Constants.electrical.heater.application.to_h
    enum :sheath_material, Constants.electrical.heater.sheath_material.to_h, prefix: true
    enum :insulation_material, Constants.electrical.heater.insulation_material.to_h, prefix: true
    
# Presence validation for required fields.
    validates :heater_type, presence: true
    validates :application, presence: true
    
    private

    def self.ransackable_attributes(auth_object = nil)
      [:heater_type, :application, :ingress_protection, :sheath_temperature_max, :power_density_min, 
        :power_density_max, :sheath_material, :insulation_material, :created_at, :updated_at]
    end

    def self.ransackable_associations(auth_object = nil)
      [ :tag, :tag_discipline, :tag_discipline_project ]
    end
  end
end