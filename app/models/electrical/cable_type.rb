# frozen_string_literal: true
module Electrical
  class CableType < Base
    # Scopes
    default_scope { order(:id) }

    # Associations
    belongs_to :discipline, required: true
    delegate :project, to: :discipline
    has_many :electrical_cables, class_name: 'Electrical::Cable', 
         foreign_key: 'electrical_cable_type_id', dependent: :destroy

    # Define enums
    enum :construction, Constants.cable.constructions.to_h
    enum :conductor_material, Constants.electrical.conductor_materials.to_h
    insulation_materials = Constants.electrical.insulation_materials.to_h
    enum :insulation, insulation_materials, prefix: true
    enum :bedding, insulation_materials, prefix: true
    enum :armour, Constants.electrical.armour_materials.to_h, prefix: true
    enum :sheath, insulation_materials, prefix: true
    enum :voltage_rating, Constants.electrical.voltage_ratings.to_h
    enum :temperature_rating, Constants.electrical.temperature_rating.each_with_index.to_h
    validates :conductor_material, :groups, :construction, :csa, presence: true
    before_save :generate_code
    
    def code
      self[:code].presence || generate_code
    end

    def label
      id
    end

    def long_label
      code
    end

    def generate_code
      # Generate base code using the existing logic
      parts = []
      parts << conductor_material
      parts << "#{csa}mm²"
      parts << "#{groups}" + construction_code +
        (neutral_csa.present? ? "+N" : "") +
        (earth_csa.present? ? "+E" : "")
      parts << insulation if insulation.present?
      parts << bedding if bedding.present?
      parts << armour if armour.present?
      parts << sheath if sheath.present?
      parts << voltage_rating if voltage_rating.present?
      parts << temperature_rating if temperature_rating.present?

      base_code = parts.join('~')
      sequence_number = find_next_sequence_number(base_code)
      new_code = "#{base_code}~#{sequence_number.to_s.rjust(2, '0')}"
      # Only update the code if it's a new record or if relevant attributes have changed
      if new_record? || (changes.keys & relevant_attributes_for_code).any?
        self.code = new_code
      end
    end

    private
      
      def find_next_sequence_number(base_code)
        # Find all existing codes that start with our base code
        existing_codes = CableType
          .where(discipline_id: discipline_id)
          .where("code LIKE ?", "#{base_code}~%")
          .pluck(:code)
        
        # Extract sequence numbers
        sequence_numbers = existing_codes.map do |code|
          # Match the sequence number after the last ':'
          match = code.match(/~(\d+)\z/)
          match ? match[1].to_i : 0
        end
      
        # Find the next available sequence number
        sequence_numbers.any? ? sequence_numbers.max + 1 : 1
      end
      
      def construction_code
        case construction
        when 'core' then 'C'
        when 'pair' then 'pr'
        when 'triple' then 'tr'
        else 'C'
        end
      end

      def relevant_attributes_for_code
        %w[conductor_material csa groups construction neutral earth neutral_csa earth_csa insulation armour sheath
          temperature_rating voltage_rating]
      end

      def self.ransackable_attributes(auth_object = nil)
        ["label", "conductor_material", "csa", "groups", "construction", "neutral", "earth",
          "neutral_csa", "earth_csa", "insulation", "bedding", "armour",
          "sheath", "bedding_od", "overall_od", "temperature_rating", "voltage_rating", "code",
          "created_at", "updated_at"]
      end


      def self.ransackable_associations(auth_object = nil)
        ["electrical_cables"]
      end

  end
end