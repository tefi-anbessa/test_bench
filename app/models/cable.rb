class Cable < ApplicationRecord
  include ::Tagable
#  has_one :tag, as: :tagable, touch: true
  belongs_to :cable_type
  belongs_to :feeder, class_name: "Load", foreign_key: "from_id"
  belongs_to :incomer, class_name: "Load", foreign_key: "to_id"
  has_one :circuit
end
