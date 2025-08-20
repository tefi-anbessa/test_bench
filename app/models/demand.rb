class Demand < ApplicationRecord
  # Associations
  belongs_to :circuit, optional: true
  
  # This is the delegated type that handles different kinds of demands (motors, light circuits, etc.)
  delegated_type :demandable, 
    types: Constants.electrical.loadable
  
  # Enums
  enum :basis, Constants.electrical.load_basis.to_h
  enum :config, Constants.electrical.load_configuration.to_h
  
  # Validations
  validates :config, presence: true
  validates :basis, presence: true
  
  attr_accessor :other_supply
  before_validation :set_supply
  
  validates :supply, numericality: { greater_than: 0.0 }, allow_nil: true
  before_save :load_calculator
  
  validates :power_factor, 
    numericality: { in: -1.0..1.0 }, 
    allow_nil: true,
    exclusion: { in: [0.0], message: "Power factor of zero will cause calculation errors" }
    
  validates :duty, numericality: { in: 0.0..1.0 }, allow_nil: true
  
  attribute :power_factor, default: 1.0
  attribute :duty, default: 1.0

  def self.ransackable_attributes(auth_object = nil)
    ["circuit", "basis", "basis_notes", "supply", "config", "power", "vector",
     "power_factor", "current", "duty", "created_at", "updated_at"]
  end

  def self.ransackable_associations(auth_object = nil)
    [:circuit, :demandable]
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
end
