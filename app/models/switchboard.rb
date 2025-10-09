class Switchboard < ApplicationRecord
  include Tagable
  include Demandable
  include TagableNavigation
  has_many :circuits, dependent: :destroy
  enum :voltage_rating, Constants.electrical.voltage_ratings.to_h

  def label
    tag.label
  end
  
  private

    def self.ransackable_attributes(auth_object = nil)
      ["location", "ingress_protection", "busbar_rating", "voltage_rating",
        "busbar_fault_rating", "busbar_fault_duration", "cable_entry",
        "incomer_protection", "metering", "neutral_bar_connections",
        "earth_bar_connections", "created_at", "updated_at"]
    end

    def self.ransackable_associations(auth_object = nil)
      [ :circuits, :tag, :demand ]
    end

end
