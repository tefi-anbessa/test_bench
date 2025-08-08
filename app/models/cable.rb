class Cable < ApplicationRecord
  include ::Tagable
  belongs_to :cable_type
  belongs_to :circuit, optional: true

  def self.ransackable_attributes(auth_object = nil)
    ["route_length", "vertical_allowance", "termination_allowance",
      "start_mark", "end_mark", "created_at", "updated_at"]
  end

  def self.ransackable_associations(auth_object = nil)
    [ :tag, :cable_type, :circuit]
  end

end
