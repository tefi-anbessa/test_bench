module Electrical
  class LightCct < Base
    include Tagable
    include Electrical::Demandable
    enum :light_fitting_type, Constants.electrical.light_cct.light_fitting_type.to_h
      
    # Validations
    validates :light_fitting_type, presence: true
    validates :quantity, numericality: { only_integer: true, greater_than: 0 }

    private

      def self.ransackable_attributes(auth_object = nil)
        ["light_fitting_type", "quantity", "created_at", "updated_at"]
      end

      def self.ransackable_associations(auth_object = nil)
        [ :electrical_demand, :tag, :tag_discipline, :tag_discipline_project ]
      end
  end
end