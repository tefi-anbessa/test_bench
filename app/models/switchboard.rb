class Switchboard < ApplicationRecord
  include Loadable
  has_many :circuits, dependent: :destroy

  private

    def self.ransackable_attributes(auth_object = nil)
      ["location", "service", "ingress_protection", "busbar_rating",
        "busbar_fault_rating", "busbar_fault_duration", "cable_entry",
        "incomer_protection", "metering", "neutral_bar_connections",
        "earth_bar_connections, ""created_at", "updated_at"]
    end

end
