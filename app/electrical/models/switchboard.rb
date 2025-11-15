class Switchboard < ApplicationRecord
  include Tagable
  include Demandable
  include TagableNavigation
  has_many :circuits, dependent: :destroy
  enum :voltage_rating, Constants.electrical.voltage_ratings.to_h

  validates :voltage_rating, presence: true
  validates :busbar_rating, presence: true

  def label
    tag&.label || I18n::t("show.orphan", model: Tag.model_name.human)
  end

  def long_label
    tag&.long_label || I18n::t("show.orphan", model: Tag.model_name.human)
  end

  def self.required_role
    :electrical_designer
  end
  
  private

    def self.ransackable_attributes(auth_object = nil)
      ["ingress_protection", "busbar_rating", "voltage_rating",
        "busbar_fault_rating", "busbar_fault_duration", "cable_entry",
        "incomer_protection", "metering", "neutral_bar_connections",
        "earth_bar_connections", "created_at", "updated_at"]
    end

    def self.ransackable_associations(auth_object = nil)
      [ :circuits, :tag, :demand ]
    end

end
