# frozen_string_literal: true
module Instrument
  class PressureTransmitter < Base
  # === Mixins ===
    include Tagable

  # === Constants ===
    # enum declarations
    enum :measurement_type, Constants.instrument.pressure_transmitter.measurement_type.to_h, prefix: true
    enum :pressure_unit, Constants.instrument.pressure_transmitter.pressure_unit.to_h, prefix: true
    enum :signal, Constants.instrument.pressure_transmitter.signal.to_h, prefix: true
    enum :communication, Constants.instrument.pressure_transmitter.communication.to_h, prefix: true
    enum :fluid_phase, Constants.instrument.pressure_transmitter.fluid_phase.to_h, prefix: true
    enum :process_fluid, Constants.instrument.pressure_transmitter.process_fluid.to_h, prefix: true
    enum :accuracy_class, Constants.instrument.pressure_transmitter.accuracy_class.to_h, prefix: true
    enum :connection_type, Constants.instrument.pressure_transmitter.connection_type.to_h, prefix: true
    enum :connection_size, Constants.instrument.pressure_transmitter.connection_size.to_h, prefix: true
    enum :case_material, Constants.instrument.pressure_transmitter.case_material.to_h, prefix: true
    enum :wetted_material, Constants.instrument.pressure_transmitter.wetted_material.to_h, prefix: true
    enum :movement_type, Constants.instrument.pressure_transmitter.movement_type.to_h, prefix: true

  # === Gem macros ===

  # === Attributes ===

  # === Associations ===

  # === Scopes ===

  # === Validations ===
    # Presence validation for required fields.
    validates :measurement_type, presence: true
    validates :range_min, presence: true
    validates :range_max, presence: true

    # Uniqueness validation for unique fields.

  # === Callbacks ===

  # === Class methods ===

  # === Class methods - Queries ===

  # === Public methods ===

  # === Private methods ===
    private

    def self.ransackable_attributes(auth_object = nil)
      [:measurement_type, :pressure_unit, :signal, :communication, :fluid_phase, :process_fluid, :accuracy_class, :connection_type, :connection_size, :case_material, :wetted_material, :movement_type, :ingress_protection, :accessories, :notes, :created_at, :updated_at]
    end

    def self.ransackable_associations(auth_object = nil)
      [:tag, :tag_discipline, :tag_discipline_project]
    end
  end
end
