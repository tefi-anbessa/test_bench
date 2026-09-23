module Electrical
  class LightCct < Base

    # === Mixins ===
    include Tagable
    include Electrical::Demandable

    # === Constants ===
    enum :light_fitting_type, Constants.electrical.light_cct.light_fitting_type.to_h

    # === Gem macros ===

    # === Attributes ===

    # === Associations ===

    # === Scopes ===

    # === Validations ===
    validates :light_fitting_type, presence: true
    validates :quantity, numericality: { only_integer: true, greater_than: 0 }

    # === Callbacks ===

    # === Class methods ===

    # === Public methods ===

    # === Private methods ===
      
    # Validations

    private
      def self.ransackable_attributes(auth_object = nil)
        [:light_fitting_type, :quantity, :notes, :created_at, :updated_at]
      end

      def self.ransackable_associations(auth_object = nil)
        [ :electrical_demand, :tag, :tag_discipline, :tag_discipline_project ]
      end
  end
end