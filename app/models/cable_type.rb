class CableType < ApplicationRecord
  resourcify
  belongs_to :project, required: true
  has_many :cables, dependent: :destroy
  enum :conductor_material, Constants.electrical.conductor_materials.to_h
  insulation_materials = Constants.electrical.insulation_materials.to_h
  enum :insulation, insulation_materials, prefix: true
  enum :bedding, insulation_materials, prefix: true
  enum :armour, Constants.electrical.armour_materials.to_h, prefix: true
  enum :sheath, insulation_materials, prefix: true
  enum :voltage_rating, Constants.electrical.voltage_ratings.to_h
  enum :temperature_rating, Constants.electrical.temperature_rating.each_with_index.to_h
  validates :conductor_material, :cores, :csa, presence: true
  before_save :generate_code
  
  def code
    self[:code].presence || generate_code
  end

  def label
    code
  end

  def next(ransack_params)
    adjacent_record(ransack_params, :next)
  end

  def prev(ransack_params)
    adjacent_record(ransack_params, :prev)
  end

  private

    def sort_columns(ransack_params = {})
      Array(ransack_params[:s] || 'id asc')
    end

    def primary_sort_column(ransack_params = {})
      sort_columns(ransack_params).first.to_s.split(' ').first
    end

    def primary_sort_direction(ransack_params = {})
      dir = sort_columns(ransack_params).first.to_s.split(' ').second
      %w[asc desc].include?(dir) ? dir : 'asc'
    end

    def adjacent_record(ransack_params, direction)
      # Convert string sort to array if needed
      sort_columns = if ransack_params[:s].is_a?(String)
                       [ransack_params[:s]]
                     else
                       Array(ransack_params[:s])
                     end
    
      # Get primary sort column and direction
      primary_sort = sort_columns.first || 'id asc'
      column, dir = primary_sort.split(' ')
      is_next = direction == :next
      op = is_next ? '>' : '<'
      rev_op = is_next ? '<' : '>'
      rev_dir = dir == 'asc' ? 'desc' : 'asc'
    
      # Build the base scope with all ransack parameters
      base_scope = self.class.ransack(ransack_params).result
    
      # For the actual query
      base_scope = base_scope.where(
        "#{column} #{is_next ? op : rev_op} ?", 
        self[column]
      ).or(
        base_scope.where(
          "#{column} = ? AND id #{op} ?", 
          self[column], 
          id
        )
      )
    
      # Apply the sort order
      base_scope = base_scope.reorder(sort_columns.join(', '))
    
      # For previous, we need to reverse the primary sort direction
      unless is_next
        reversed_sorts = sort_columns.map do |sort|
          col, d = sort.split(' ')
          d = (col == column) ? (d == 'asc' ? 'desc' : 'asc') : d
          "#{col} #{d}"
        end
        base_scope = base_scope.reorder(reversed_sorts.join(', '))
      end
    
      base_scope.first
    end

    def generate_code
      # Generate base code using the existing logic
      parts = []
      parts << conductor_material
      parts << "#{csa}mm²"
      parts << "#{cores}C" + 
        (neutral_csa.present? ? "+N(#{neutral_csa})" : "") + 
        (earth_csa.present? ? "+E(#{earth_csa})" : "")
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

    
    def find_next_sequence_number(base_code)
      # Find all existing codes that start with our base code
      existing_codes = CableType
        .where(project_id: project_id)
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
    
    def relevant_attributes_for_code
      %w[conductor_material csa cores neutral earth neutral_csa earth_csa insulation armour sheath 
         temperature_rating voltage_rating]
    end

    def self.ransackable_attributes(auth_object = nil)
      ["conductor_material", "csa", "cores", "neutral", "earth", 
        "neutral_csa", "earth_csa", "insulation", "bedding", "armour",
        "sheath", "bedding_od", "overall_od", "temperature_rating", "voltage_rating", "code",
        "created_at", "updated_at"]
    end


    def self.ransackable_associations(auth_object = nil)
      ["cables"]
    end

end
