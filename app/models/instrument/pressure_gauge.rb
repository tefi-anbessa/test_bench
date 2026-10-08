# frozen_string_literal: true
module Instrument
  class PressureGauge < Base
  # === Mixins ===
    include Tagable

  # === Constants ===
    # enum declarations
    enum :measurement_type, Constants.instrument.pressure_gauge.measurement_type.to_h, prefix: true
    enum :pressure_unit, Constants.instrument.pressure_gauge.pressure_unit.to_h, prefix: true
    enum :fluid_phase, Constants.instrument.pressure_gauge.fluid_phase.to_h, prefix: true
    enum :process_fluid, Constants.instrument.pressure_gauge.process_fluid.to_h, prefix: true
    enum :accuracy_class, Constants.instrument.pressure_gauge.accuracy_class.to_h, prefix: true
    enum :dial_size, Constants.instrument.pressure_gauge.dial_size.to_h, prefix: true
    enum :connection_type, Constants.instrument.pressure_gauge.connection_type.to_h, prefix: true
    enum :connection_size, Constants.instrument.pressure_gauge.connection_size.to_h, prefix: true
    enum :case_material, Constants.instrument.pressure_gauge.case_material.to_h, prefix: true
    enum :wetted_material, Constants.instrument.pressure_gauge.wetted_material.to_h, prefix: true
    enum :movement_type, Constants.instrument.pressure_gauge.movement_type.to_h, prefix: true
    enum :fill_fluid, Constants.instrument.pressure_gauge.fill_fluid.to_h, prefix: true

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
      [:measurement_type, :pressure_unit, :fluid_phase, :process_fluid, :accuracy_class, :dial_size, :connection_type, :connection_size, :case_material, :wetted_material, :movement_type, :fill_fluid, :ingress_protection, :accessories, :notes, :created_at, :updated_at]
    end

    def self.ransackable_associations(auth_object = nil)
      [:tag, :tag_discipline, :tag_discipline_project]
    end
  end
end