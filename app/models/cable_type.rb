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
    parts = [I18n.t("activerecord.models.cable") + ' ']
    parts << "#{csa}mm²" if csa.present?
    parts << conductor_material if conductor_material.present?
    parts << conductor_makeup if conductor_makeup.present?
    parts << insulation if insulation.present?
    parts << armour if armour.present?
    parts << sheath if sheath.present?
    parts << temperature_rating if temperature_rating.present?
    
    description = parts.join(' ').strip
    
    # Only update the description if it's a new record or if relevant attributes have changed
    relevant_attributes = %w[conductor_material conductor_makeup csa insulation 
                            armour sheath temperature_rating neutral_csa earth_csa]
    if new_record? || (changes.keys & relevant_attributes).any?
      write_attribute(:description, description)
    end
    
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
