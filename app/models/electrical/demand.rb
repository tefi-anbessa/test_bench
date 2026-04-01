# frozen_string_literal: true
module Electrical
  class Demand < Base
  # Demandable types are the models that can have electrical load information attached.
    delegated_type :demandable, types: Constants.electrical.loadable, required: true

    # Associations
    has_one :incomer, as: :to, class_name: 'Electrical::Cable', dependent: :nullify
    has_one :feeder, as: :from, class_name: 'Electrical::Cable', dependent: :nullify

    # Enums
    enum :basis, Constants.electrical.load_basis.to_h
    enum :config, Constants.electrical.load_configuration.to_h
    
    # Validations
    validates :config, presence: true
    validates :basis, presence: true
    validate :demandable_must_have_tag, if: :demandable?
    
    validates :supply, numericality: { greater_than: 0.0 }, allow_nil: true
    before_save :load_calculator
    
    validates :power_factor, 
      numericality: { in: -1.0..1.0 }, 
      allow_nil: true,
      exclusion: { in: [0.0], message: I18n.t("activerecord.errors.attributes.electrical.demand.power_factor.zero_pf") }
      
    validates :duty, numericality: { in: 0.0..1.0 }, allow_nil: true
    
    attribute :power_factor, default: 1.0
    attribute :duty, default: 1.0

    def tag
      demandable&.tag
    end
    
    def label
      demandable&.label || I18n.t("show.orphan", 
                                  model: demandable_type.presence&.constantize&.model_name&.human || 
                                  I18n.t("show.default_model")
                                )
    end

    def self.required_role
      :electrical_designer
    end

    def circuit
      # Find the circuit that supplies power to this demand
      incomer&.from if incomer&.from_type == "Electrical::Circuit"
    end

    def conductor_count
      case self.config
      when "dc", "one"
        1
      when "two_120", "two_180"
        2
      when "three_3c", "three_4c"
        3
      else
        1
      end
    end

    private

    def load_calculator
      case self.config
      when "dc", "one"
        conductors = 1
      when "two_120", "two_180"
        conductors = 2
      when "three_3c", "three_4c"
        conductors = 3
      else
        conductors = 1
      end

      self.vector = if self.basis == 'current' && self.current.present?
        self.current * self.supply * conductors * (self.power_factor || 1.0)
      elsif self.basis == 'power_pf' && self.power.present? && self.supply.present?
        self.power / (self.supply * (self.power_factor || 1.0) * conductors)
      elsif self.basis == 'power_va' && self.power.present? && self.supply.present?
        self.power / (self.supply * conductors)
      else
        0.0
      end
    end

    def set_supply
      self.supply = other_supply if other_supply.present?
    end

    def demandable?
      demandable.present?
    end

    def demandable_must_have_tag
      return unless demandable?
      return if demandable.respond_to?(:tag) && demandable.tag.present?
      
      errors.add(:base, message: I18n.t("activerecord.errors.messages.attributes.demand.demandable.tag_association",
                                        model: demandable_type.constantize.model_name.human))
    end

    def self.ransackable_attributes(auth_object = nil)
      ["circuit", "basis", "basis_notes", "supply", "config", "power", "vector",
      "power_factor", "current", "duty", "created_at", "updated_at",
      "tag_full_tag", "demandable_type"]
    end

    def self.ransackable_associations(auth_object = nil)
      [:electrical_circuit, :demandable]
    end
  end
end