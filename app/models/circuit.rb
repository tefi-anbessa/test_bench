class Circuit < ApplicationRecord
  belongs_to :switchboard

  has_one :feeder, as: :from, class_name: 'Cable', dependent: :nullify

  validates :serial, inclusion: { in: 1..36 }
  validates :serial, uniqueness: { scope: :switchboard_id,
    message: "already exists" }
  enum :phase, Constants.electrical.phase_designation.to_h
  enum :device, Constants.electrical.protection.device.to_h
  validates :poles, inclusion: { in: 1..6 }, allow_nil: true
  enum :curve, Constants.electrical.protection.curve.to_h
  enum :elcb, Constants.electrical.protection.elcb.to_h

  # Provide tag method using parent switchboard's tag association
  def tag
    switchboard&.tag
  end

  def label
    "##{serial.to_s.rjust(2, '0')}"
  end
  
  def demand
    # Find the demand that this circuit supplies power to
    feeder&.to if feeder&.to_type == "Demand"
  end

  def self.ransackable_attributes(auth_object = nil)
    ["serial", "device", "poles", "curve", "rating", "elcb", "contactor",
      "notes", "created_at", "updated_at"]
  end

  def self.ransackable_associations(auth_object = nil)
    [ :switchboard, :load, :cable ]
  end
end
