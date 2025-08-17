# This is a legacy model that's been replaced by Demand
# It's kept for backward compatibility
class Load < Demand
  self.table_name = 'demands'  # Use the same table as Demand
  
  # Add deprecation warning
  def self.inherited(subclass)
    super
    warn "[DEPRECATION] The Load model is deprecated. Please use Demand instead."
  end
  # Map legacy column names to new ones
  self.inheritance_column = nil
  
  # Override the demandable getter/setter to maintain backward compatibility
  def demandable=(value)
    super(value)
  end
  
  def demandable
    super
  end
  
  # Alias for backward compatibility
  def loadable=(value)
    self.demandable = value
  end
  
  def loadable
    demandable
  end
  
  # Override to handle the old loadable_type
  def self.sti_name
    'Load'
  end
  
  # For polymorphic associations
  def self.polymorphic_name
    'Load'
  end
  
  # Override the polymorphic_name for instances
  def polymorphic_name
    'Load'
  end
  
  # For form builders and other places that might call model_name
  def self.model_name
    @_model_name ||= ActiveModel::Name.new(self, nil, 'Load')
  end
  validates :basis, presence: true
  attr_accessor :other_supply
  before_validation :set_supply
  validates :supply, numericality: { greater_than: 0.0 }, allow_nil: true
  before_save :load_calculator
  validates :power_factor, numericality: { in: -1.0..1.0 }, allow_nil: true
  validates :power_factor, numericality: { other_than: 0.0,
    message: "Power factor of zero will cause calculation errors" }, allow_nil: true
  validates :duty, numericality: { in: 0.0..1.0 }, allow_nil: true
  attribute :power_factor, default: 1.0
  attribute :duty, default: 1.0

  def self.ransackable_attributes(auth_object = nil)
    ["circuit", "basis", "basis_notes", "supply", "config", "power", "vector",
      "power_factor", "current", "duty", "created_at", "updated_at"]
  end

  def self.ransackable_associations(auth_object = nil)
    [ :circuit, :tag, :cable ]
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

      case self.basis
      when "summation"
      when "power_pf"
        unless self.power.blank? || self.power_factor.blank? || self.power_factor == 0.0
          self.current = self.power / (self.supply * self.power_factor * conductors)
          self.vector = self.power / self.power_factor
        end
      when "vector_pf"
        unless self.vector.blank? || self.power_factor.blank? || self.supply == 0.0
          self.current = self.vector / (self.supply * conductors)
          self.power = self.vector * self.power_factor
        end
      when "current_pf"
        unless self.current.blank? || self.power_factor.blank? || self.power_factor == 0.0
          self.power = self.current * self.supply * self.power_factor * conductors
          self.vector = self.power / self.power_factor
        end
      when "current_power"
        unless self.current.blank? || self.power.blank? || self.supply == 0.0 || self.current == 0.0
          self.vector = self.current * self.supply * conductors
          self.power_factor = self.power / self.vector
        end
      end
    end


    def set_supply
      if self.other_supply.present? && self.supply.blank?
        self.supply = self.other_supply
      end
    end
end
