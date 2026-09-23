module Electrical
  class Motor < Base

    # === Mixins ===
    include Tagable
    include Electrical::Demandable

    # === Constants ===
    enum :motor_type, Constants.electrical.motor.motor_type.to_h
    enum :frame_size, Constants.electrical.motor.frame_size.to_h

    # === Gem macros ===

    # === Attributes ===

    # === Associations ===

    # === Scopes ===

    # === Validations ===
    validates :motor_type, presence: true
    validates :frame_size, presence: true

    # === Callbacks ===

    # === Class methods ===

    # === Public methods ===

    # === Private methods ===
    private

      def self.ransackable_attributes(auth_object = nil)
        ["motor_type", "frame_size", "ingress_protection", "poles",
          "speed_rated", "notes", "created_at", "updated_at"]
      end

      def self.ransackable_associations(auth_object = nil)
        [ :electrical_demand, :tag, :tag_discipline, :tag_discipline_project ]
      end
  end
end