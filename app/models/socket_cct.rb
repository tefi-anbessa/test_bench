class SocketCct < ApplicationRecord
  include Tagable
  include Demandable
  
  # Validations
  validates :socket_type, presence: true
  validates :quantity, numericality: { only_integer: true, greater_than: 0 }

  def label
    tag&.label || I18n::t("show.orphan", model: Tag.model_name.human)
  end

  private

    def self.ransackable_attributes(auth_object = nil)
      ["socket_type", "quantity", "created_at", "updated_at"]
    end

    def self.ransackable_associations(auth_object = nil)
      [ :demand, :tag ]
    end
end
