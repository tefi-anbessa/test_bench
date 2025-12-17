module Electrical
  class Switchboard < Base
    include Tagable
    include Electrical::Demandable
    include TagableNavigation
    
    has_many :electrical_circuits, class_name: 'Electrical::Circuit', 
              foreign_key: 'electrical_switchboard_id', dependent: :destroy
    enum :voltage_rating, Constants.electrical.voltage_ratings.to_h

    validates :voltage_rating, presence: true
    validates :busbar_rating, presence: true
    
    private

      def self.ransackable_attributes(auth_object = nil)
        ["ingress_protection", "busbar_rating", "voltage_rating",
          "busbar_fault_rating", "busbar_fault_duration", "cable_entry",
          "incomer_protection", "metering", "neutral_bar_connections",
          "earth_bar_connections", "notes", "created_at", "updated_at"]
      end

      def self.ransackable_associations(auth_object = nil)
        [ :electrical_circuits, :tag, :tag_discipline, :tag_discipline_project, :electrical_demand ]
      end

  end
end