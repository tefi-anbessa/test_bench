class Motor < ApplicationRecord
  include Tagable
  include Loadable

  private

    def self.ransackable_attributes(auth_object = nil)
      ["motor_type", "frame_size", "ingress_protection", "poles",
        "speed_rated", "created_at", "updated_at"]
    end

    def self.ransackable_associations(auth_object = nil)
      [ :load, :tag ]
    end
end
