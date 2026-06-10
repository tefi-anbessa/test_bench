module Electrical
  class Circuit < Base
    # === Mixins ===

    # === Constants ===
    enum :phase, Constants.electrical.phase_designation.to_h
    enum :device, Constants.electrical.protection.device.to_h
    enum :curve, Constants.electrical.protection.curve.to_h
    enum :elcb, Constants.electrical.protection.elcb.to_h

    # === Gem macros ===
    # Record all changes to this model's data
    has_paper_trail

    # === Attributes ===

    # === Associations ===
    belongs_to :switchboard, class_name: 'Electrical::Switchboard', foreign_key: :electrical_switchboard_id
    has_one :tag, through: :switchboard
    has_one :discipline, through: :switchboard
    has_one :project, through: :switchboard

    has_one :feeder, as: :from, class_name: 'Electrical::Cable', dependent: :nullify
    has_one :demand, through: :feeder, source: :to, source_type: "Electrical::Demand"

    # === Scopes ===

    # === Validations ===
    # Validations
    validates :serial, numericality: { in: 1..36 }
    validates :serial, uniqueness: { scope: :switchboard }
    validates :poles, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 6 }, allow_nil: true

    # === Callbacks ===

    # === Class methods ===

    # === Class methods - Queries ===
    # Provide SQL for ordering documents in the navigator
    def self.navigator_order_sql
      <<~SQL.squish
        projects.code ASC,
        disciplines.sort_order ASC,
        tags.full_tag ASC,
        electrical_circuits.serial ASC
      SQL
    end

    # === Public methods ===
    def label
      "##{serial.to_s.rjust(2, '0')}"
    end

    def long_label
      switchboard.label + " " + label
    end

    def next_serial
      Electrical::Circuit.where(electrical_switchboard_id: electrical_switchboard_id)
        .maximum(:serial)
        .to_i + 1
    end

    # === Private methods ===
    def self.ransackable_attributes(auth_object = nil)
      ["label", "long_label", "phase", "device", "poles", "curve", "rating", "elcb", "contactor",
        "notes", "created_at", "updated_at"]
    end

    def self.ransackable_associations(auth_object = nil)
      [ :switchboard, :electrical_demand, :feeder ]
    end

    # Ransacker for long_label method  
    ransacker :long_label do |parent|
      parent.table.project(
        parent.table[:electrical_switchboard_id]
      )
    end
  end
end