class Circuit < ApplicationRecord
  belongs_to :switchboard
  belongs_to :load, optional: true
  belongs_to :cable, optional: true
  validates :serial, inclusion: { in: 1..36 }
  enum :phase, Constants.electrical.phase_designation.to_h
  enum :device, Constants.electrical.protection.device.to_h
  validates :poles, inclusion: { in: 1..6 }
  enum :curve, Constants.electrical.protection.curve.to_h
  enum :elcb, Constants.electrical.protection.elcb.to_h

end
