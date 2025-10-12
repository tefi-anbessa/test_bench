class Motor < ApplicationRecord
  include Tagable
  include Demandable

  def label
    tag&.label || I18n::t("show.orphan", model: Tag.model_name.human)
  end
  
  private

    def self.ransackable_attributes(auth_object = nil)
      ["motor_type", "frame_size", "ingress_protection", "poles",
        "speed_rated", "created_at", "updated_at"]
    end

    def self.ransackable_associations(auth_object = nil)
      [ :demand, :tag ]
    end
end
