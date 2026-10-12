# frozen_string_literal: true

module Instrument
  # The signal/communication-specific remainder of a cable type, once
  # construction, materials, voltage/temperature rating etc. moved to the
  # shared CableType.
  class CableTypeDetail < Base
    # === Mixins ===
    include ::CableTypeDetailable

    # === Constants ===

    # === Gem macros ===
    has_paper_trail

    # === Attributes ===

    # === Associations ===

    # === Scopes ===

    # === Validations ===

    # === Callbacks ===

    # === Class methods ===

    # === Public methods ===

    # === Private methods ===
    private

      def self.ransackable_attributes(auth_object = nil)
        ["individual_screen", "overall_screen", "twist_pitch", "created_at", "updated_at"]
      end

      def self.ransackable_associations(auth_object = nil)
        ["cable_type"]
      end
  end
end
