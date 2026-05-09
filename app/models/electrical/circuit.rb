module Electrical
  class Circuit < Base
    belongs_to :switchboard, class_name: 'Electrical::Switchboard', foreign_key: :electrical_switchboard_id
    delegate :tag, :discipline, :project, to: :switchboard

    has_one :feeder, as: :from, class_name: 'Electrical::Cable', dependent: :nullify

    validates :serial, numericality: { in: 1..36 }
    validates :serial, uniqueness: { scope: :switchboard }
    enum :phase, Constants.electrical.phase_designation.to_h
    enum :device, Constants.electrical.protection.device.to_h
    validates :poles, inclusion: { in: 1..6 }, allow_nil: true
    enum :curve, Constants.electrical.protection.curve.to_h
    enum :elcb, Constants.electrical.protection.elcb.to_h

    def label
      "##{serial.to_s.rjust(2, '0')}"
    end

    def long_label
      switchboard.label + " " + label
    end
    
    def demand
      # Find the demand that this circuit supplies power to
      feeder&.to if feeder&.to_type == "Electrical::Demand"
    end

    def self.ransackable_attributes(auth_object = nil)
      ["serial", "phase", "device", "poles", "curve", "rating", "elcb", "contactor",
        "notes", "created_at", "updated_at"]
    end

    def self.ransackable_associations(auth_object = nil)
      [ :switchboard, :electrical_demand, :feeder ]
    end
  end
end