class LightCct < ApplicationRecord
  include Tagable
  include Loadable

  private

    def self.ransackable_attributes(auth_object = nil)
      ["light_fitting_type", "number", "created_at", "updated_at"]
    end

    def self.ransackable_associations(auth_object = nil)
      [ :load, :tag ]
    end
end
