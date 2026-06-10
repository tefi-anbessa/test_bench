# frozen_string_literal: true
module Electrical
  class Demand < Base
    # === Mixins ===

    # === Constants ===
    # Enums
    enum :basis, Constants.electrical.load_basis.to_h
    enum :config, Constants.electrical.load_configuration.to_h

    # === Gem macros ===

    # === Attributes ===
    attr_accessor :other_supply
    attribute :power_factor, default: 1.0
    attribute :duty, default: 1.0

    # === Associations ===
    # Demandable types are the models that can have electrical load information attached.
    delegated_type :demandable, types: Constants.electrical.loadable, required: true

    has_one :incomer, as: :to, class_name: 'Electrical::Cable', dependent: :nullify
    has_one :feeder, as: :from, class_name: 'Electrical::Cable', dependent: :nullify
    # Find the circuit that supplies power to this demand
    has_one :circuit, through: :incomer, source: :from, source_type: "Electrical::Circuit"

    # === Scopes ===
    scope :with_tags, -> {
      joins(<<~SQL)
        INNER JOIN tags
          ON tags.tagable_type = electrical_demands.demandable_type
        AND tags.tagable_id = electrical_demands.demandable_id
      SQL
    }

    # === Validations ===
    # Validations
    validates :config, presence: true
    validates :basis, presence: true
    validate :demandable_must_have_tag, if: :demandable?
    
    validates :supply, numericality: { greater_than: 0.0 }, allow_nil: true
    before_save :load_calculator
    
    validates :power_factor, 
      numericality: { in: -1.0..1.0 }, 
      allow_nil: true,
      exclusion: { in: [0.0], message: I18n.t("activerecord.errors.attributes.electrical/demand.power_factor.zero_pf") }
      
    validates :duty, numericality: { in: 0.0..1.0 }, allow_nil: true

    # === Callbacks ===
    before_validation :set_supply

    # === Class methods ===
    def self.required_role
      :electrical_designer
    end

    # === Class methods - Queries ===
    # Provide SQL for ordering documents in the navigator
    def self.navigator_order_sql
      <<~SQL.squish
        projects.code ASC,
        disciplines.sort_order ASC,
        tags.full_tag ASC
      SQL
    end

    # === Public methods ===
    def tag
      @tag ||= Tag.find_by(
        tagable_type: demandable_type,
        tagable_id: demandable_id
      )
    end
    delegate :service, :stage, :location, :label, :long_label, :full_tag, to: :tag

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

    # === Private methods ===
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
      
      errors.add(:base, message: I18n.t("activerecord.errors.attributes.electrical/demand.demandable.tag_association",
                                        model: demandable_type.constantize.model_name.human))
    end

    def self.ransackable_attributes(auth_object = nil)
      ["circuit", "basis", "basis_notes", "supply", "config", "power", "vector",
      "power_factor", "current", "duty", "created_at", "updated_at",
      "tag_full_tag", "demandable_type"]
    end

    def self.ransackable_associations(auth_object = nil)
      [:demandable, :tag, :discipline, :project, :incomer, :feeder, :circuit]
    end
  end
end