class CableType < ApplicationRecord
  resourcify
  belongs_to :project, required: true
  has_many :cables, dependent: :destroy
  enum :temperature_rating, Constants.electrical.temperature_rating.each_with_index.to_h
  
  before_save :generate_description
  
  def description
    self[:description].presence || generate_description
  end
  
  private
  
  def generate_description
    parts = []
    parts << "#{csa}mm²" if csa.present?
    parts << conductor_material.downcase if conductor_material.present?
    parts << conductor_makeup if conductor_makeup.present?
    
    cable_type = if insulation.present? && insulation.downcase.include?('pvc') && armour.blank?
                  'PVC Cable'
                elsif armour.present? && armour.downcase.include?('swa')
                  'Steel Wire Armoured Cable'
                else
                  'Cable'
                end
    
    description = [parts.join(' '), cable_type].reject(&:blank?).join(' ')
    write_attribute(:description, description) if new_record? || changes.keys.any? { |k| %w[conductor_material conductor_makeup csa insulation armour].include?(k) }
    description
  end
  
  # Validations
  validates :conductor_material, :conductor_makeup, :csa, presence: true
            
  # Ensure we don't have duplicate cable types with the same specifications within a project
  # Using a custom validation to handle nil values properly
  validate :unique_cable_specifications
  
  private
  
  def unique_cable_specifications
    # Skip if we already have errors on any of the required fields
    return if errors[:conductor_material].any? || errors[:conductor_makeup].any? || errors[:csa].any?
    
    # Start with required fields and scope to project
    existing = self.class.where(
      project_id: project_id,
      conductor_material: conductor_material,
      conductor_makeup: conductor_makeup,
      csa: csa
    )
    
    # Add conditions for optional fields, handling NULL properly for SQLite
    [
      :insulation, :bedding, :armour, :sheath, :temperature_rating,
      :neutral_csa, :earth_csa, :bedding_od, :overall_od
    ].each do |field|
      value = send(field)
      if value.nil?
        existing = existing.where("#{field} IS NULL")
      else
        existing = existing.where(field => value)
      end
    end
    
    # Exclude current record if updating
    existing = existing.where.not(id: id) if persisted?
    
    if existing.exists?
      errors.add(:base, "A cable type with these specifications already exists") 
    end
  end

  private


    def self.ransackable_attributes(auth_object = nil)
      ["conductor_material", "conductor_makeup", "csa", "description",
        "neutral_csa", "earth_csa", "insulation", "bedding", "armour",
        "bedding", "sheath", "bedding_od", "overall_od", "temperature_rating",
        "created_at", "updated_at"]
    end


    def self.ransackable_associations(auth_object = nil)
      ["cables"]
    end

end
