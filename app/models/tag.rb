class Tag < ApplicationRecord
  resourcify
  delegated_type :tagable, types: Constants.tagable, optional: true, dependent: :destroy
  accepts_nested_attributes_for :tagable
  belongs_to :project
  belongs_to :discipline

  attribute :full_tag, :string
  after_find :set_full_tag
  before_validation :set_loop_id, on: [:create, :update]

  # Default scope to sort by loop_id, then by full_tag
  default_scope { order(:loop_id, :prefix, :suffix) }

  validates :prefix, format: { with: /\A[a-zA-Z]+\z/, message: "only allows letters" }
  validates :prefix, length: { in: 1..6 }
  attr_accessor :new_prefix, :string
  validates :new_prefix, length: { in: 1..6, allow_nil: true }
  before_validation :set_prefix

  validates :serial, presence: true, inclusion: { in: 0..9999 }
  validates :suffix, length: { maximum: 5 }
  validates :service, length: { maximum: 40 }
  validates :stage, inclusion: { in: 0..10 }
  validate :validate_tagable_assignment, on: :update
  validate :validate_tagable_existence

  # Allow setting tagable_type without tagable_id to indicate intended type
  # Only validate presence of tagable_id if we're setting a non-nil value
  validates :tagable_id, presence: { message: 'must be present when setting a tagable' }, 
                         if: -> { tagable_type.present? && tagable_id_changed? && tagable_id.present? }
  validates :tagable_type, inclusion: { in: Constants.tagable.map(&:to_s) }, 
                           allow_nil: true,
                           allow_blank: true
  
  # Ensure a tagable is only associated with one tag
  validate :tagable_not_already_taken, if: -> { tagable_id.present? && tagable_type.present? }
  
  # Ensure tag is unique within the same project and discipline
  validate :validate_tag_uniqueness
  
  # Custom validation to handle suffix uniqueness with NULL values in the database
  def validate_tag_uniqueness
    return unless project_id && discipline_id && prefix && serial
    
    # Convert empty string to nil for comparison
    suffix_value = suffix.presence
    
    # Check for existing tags with the same combination
    existing = Tag.where(
      project_id: project_id,
      discipline_id: discipline_id,
      prefix: prefix,
      serial: serial
    ).where("COALESCE(suffix, '') = ?", suffix_value.to_s)
    
    # Exclude current record from the check if it's persisted
    existing = existing.where.not(id: id) if persisted?
    
    if existing.exists?
      errors.add(:prefix, I18n.t('activerecord.errors.models.tag.full_tag'))
    end
  end

  # Track original values to detect changes
  def initialize(*)
    super
    @original_tagable_type = tagable_type
    @original_tagable_id = tagable_id
  end

  # Get the next tag in the project, ordered by discipline, loop_id, prefix, and suffix
  def next(attribute = :loop_id)
    return super(attribute) unless attribute == :loop_id
    
    adjacent_tag('next_id') || self
  end

  # Get the previous tag in the project, ordered by discipline, loop_id, prefix, and suffix
  def prev(attribute = :loop_id)
    return super(attribute) unless attribute == :loop_id
    
    adjacent_tag('prev_id') || self
  end

  private
  
  # Find adjacent tag (next or previous) based on the given join condition
  def adjacent_tag(join_column)
    sql = <<-SQL
      WITH ordered_tags AS (
        SELECT id,
               discipline_id,
               loop_id,
               prefix,
               COALESCE(suffix, '') as suffix_sort,
               LAG(id) OVER (ORDER BY discipline_id, loop_id, prefix, COALESCE(suffix, '')) as prev_id,
               LEAD(id) OVER (ORDER BY discipline_id, loop_id, prefix, COALESCE(suffix, '')) as next_id
        FROM tags
        WHERE project_id = :project_id
      )
      SELECT t.*
      FROM tags t
      JOIN ordered_tags ot ON t.id = ot.#{join_column}
      WHERE ot.id = :current_id
    SQL
    
    self.class.find_by_sql([sql, { project_id: project_id, current_id: id }]).first
  end
  
  # Prevent re-assigning a tagable to a different tag
  def tagable_not_already_taken
    return unless tagable_id.present? && tagable_type.present?
    
    existing_tag = Tag.where(
      tagable_id: tagable_id,
      tagable_type: tagable_type
    ).where.not(id: id).exists?
    
    if existing_tag
      errors.add(:tagable, 'is already associated with another tag')
    end
  end

  # Prevent changing tagable association if it's already set and valid
  def validate_tagable_assignment
    return unless tagable_type_changed? || tagable_id_changed?
    return if tagable_id_was.blank? || tagable_type_was.blank?
    
    # Allow changes if the current association is invalid
    return if tagable_type_was.constantize.where(id: tagable_id_was).none?
    
    errors.add(:base, 'Cannot change tagable association once set') 
  end

  # Ensure tagable exists if both type and id are present
  def validate_tagable_existence
    return if tagable_id.blank? || tagable_type.blank?
    
    begin
      tagable_class = tagable_type.constantize
      return if tagable_class.exists?(tagable_id)
      
      errors.add(:tagable, 'must exist')
    rescue NameError
      errors.add(:tagable_type, 'is not a valid type')
    end
  end

  def self.ransackable_attributes(auth_object = nil)
    ["prefix", "serial", "suffix", "service", "full_tag", "stage",
      "notes", "discipline_id", "created_at", "updated_at", "loop_id"]
  end


  def self.ransackable_associations(auth_object = nil)
    ["discipline", "project", "tagable"]
  end

  # Returns tags grouped by their loop identifier
  # @return [Hash] Tags grouped by loop_id
  def self.grouped_by_loop
    all.group_by(&:loop_id)
  end

  # Returns the parsed tag schema for a given discipline
  # @param discipline_code [String] The discipline code (e.g., 'J' for Instruments, 'E' for Electrical)
  # @return [Hash] The parsed tag schema for the discipline
  def self.tag_schema(discipline_code = 'J')
    @tag_schemas ||= {}
    @tag_schemas[discipline_code] ||= parse_discipline_schema(discipline_code)
  end

  # Parses a tag prefix according to the discipline's schema
  # @param prefix [String] The tag prefix to parse (e.g., 'TE' for Temperature Element)
  # @param discipline_code [String] The discipline code (defaults to 'J' for Instruments)
  # @return [Array<Hash>] An array of hashes with information about each character in the prefix
  def self.parse_tag(prefix, discipline_code = 'J')
    schema = tag_schema(discipline_code)
    return [] unless schema && prefix.present?

    result = []
    current = schema
    
    prefix.chars.each_with_index do |char, index|
      if current[:next_chars] && (next_node = current[:next_chars][char])
        result << {
          position: index + 1,
          character: char,
          name: next_node[:name],
          type: next_node[:type],
          description: next_node[:description] || next_node[:name]
        }
        current = next_node
      else
        # If we can't find the next character in the schema, add what we can
        result << {
          position: index + 1,
          character: char,
          name: 'Unknown',
          type: :unknown,
          description: 'Unknown character in this position'
        }
      end
    end
    
    result
  end

  # Returns the available options for the next character in a tag prefix
  # @param current_prefix [String] The current prefix (e.g., 'T' for Temperature)
  # @param discipline_code [String] The discipline code (defaults to 'J' for Instruments)
  # @return [Array<Hash>] An array of available options for the next character
  def self.available_options(current_prefix = '', discipline_code = 'J')
    schema = tag_schema(discipline_code)
    return [] unless schema

    current = schema
    
    # Navigate to the current position in the schema
    current_prefix.chars.each do |char|
      break unless current[:next_chars] && (next_node = current[:next_chars][char])
      current = next_node
    end
    
    return [] unless current[:next_chars]
    
    current[:next_chars].map do |char, node|
      {
        character: char,
        name: node[:name],
        type: node[:type],
        description: node[:description] || node[:name]
      }
    end
  end

  # Parses the schema for a specific discipline
  def self.parse_discipline_schema(discipline_code)
    discipline = Constants.tag.discipline[discipline_code]
    return {} unless discipline&.prefix

    schema = {
      name: discipline.name,
      type: :discipline,
      next_chars: {}
    }

    # Handle different discipline schema formats
    if discipline.prefix.respond_to?(:measured_variables)
      # ISA S5.1 format (Instruments)
      parse_isa_schema(discipline, schema)
    else
      # Simple prefix mapping (e.g., Architecture, Electrical)
      parse_simple_schema(discipline, schema)
    end

    schema
  end

  # Parses ISA S5.1 schema format
  def self.parse_isa_schema(discipline, schema)
    prefix = discipline.prefix
    
    # First letter (Measured Variables)
    if prefix.measured_variables
      prefix.measured_variables.each do |letter, name|
        schema[:next_chars][letter] = {
          name: name,
          type: :measured_variable,
          description: "Measured variable: #{name}",
          next_chars: {}
        }
      end
    end

    # Add second letter options (modifiers, readout functions, output functions)
    add_isa_second_letter_options(schema, prefix)
    
    # Add third letter options (when second letter is a modifier)
    add_isa_third_letter_options(schema, prefix)
    
    # Add modifier functions (can appear after any second letter)
    add_isa_modifier_functions(schema, prefix)
  end
  
  # Adds second letter options (modifiers, readout functions, output functions)
  def self.add_isa_second_letter_options(schema, prefix)
    schema[:next_chars].each_value do |first_letter|
      # Add modifiers (e.g., D for Differential, F for Ratio)
      if prefix.modifiers
        prefix.modifiers.each do |letter, name|
          first_letter[:next_chars][letter] = {
            name: name,
            type: :modifier,
            description: "Modifier: #{name}",
            next_chars: {}
          }
        end
      end
      
      # Add readout functions (e.g., I for Indication, R for Record)
      if prefix.readout_functions
        prefix.readout_functions.each do |letter, name|
          first_letter[:next_chars][letter] ||= {
            name: name,
            type: :readout_function,
            description: "Readout: #{name}",
            next_chars: {}
          }
        end
      end
      
      # Add output functions (e.g., C for Control, V for Valve)
      if prefix.output_functions
        prefix.output_functions.each do |letter, name|
          first_letter[:next_chars][letter] ||= {
            name: name,
            type: :output_function,
            description: "Output: #{name}",
            next_chars: {}
          }
        end
      end
    end
  end
  
  # Adds third letter options (when second letter is a modifier)
  def self.add_isa_third_letter_options(schema, prefix)
    schema[:next_chars].each_value do |first_letter|
      first_letter[:next_chars].each do |second_letter, second_data|
        next unless second_data[:type] == :modifier
        
        # Add readout functions as third letter options
        if prefix.readout_functions
          prefix.readout_functions.each do |letter, name|
            next if %w[B N X].include?(letter) # Skip user's choice and unclassified
            second_data[:next_chars][letter] = {
              name: name,
              type: :readout_function,
              description: "Readout: #{name}",
              next_chars: {}
            }
          end
        end
        
        # Add output functions as third letter options
        if prefix.output_functions
          prefix.output_functions.each do |letter, name|
            next if %w[B N X].include?(letter) # Skip user's choice and unclassified
            second_data[:next_chars][letter] ||= {
              name: name,
              type: :output_function,
              description: "Output: #{name}",
              next_chars: {}
            }
          end
        end
      end
    end
  end
  
  # Adds modifier functions (can appear after any second letter)
  def self.add_isa_modifier_functions(schema, prefix)
    return unless prefix.modifier_functions
    
    schema[:next_chars].each_value do |first_letter|
      first_letter[:next_chars].each_value do |second_letter|
        prefix.modifier_functions.each do |letter, name|
          next if %w[B N X].include?(letter) # Skip user's choice and unclassified
          
          # Handle multi-character modifiers (e.g., HH, LL)
          if letter.length > 1
            # For multi-char modifiers, add them as a sequence
            current = second_letter
            letter.chars.each_with_index do |char, index|
              current[:next_chars][char] ||= {
                name: index == 0 ? name : "",
                type: :modifier_function,
                description: "Modifier: #{name}",
                next_chars: {}
              }
              current = current[:next_chars][char]
            end
          else
            # Single character modifiers
            second_letter[:next_chars][letter] ||= {
              name: name,
              type: :modifier_function,
              description: "Modifier: #{name}",
              next_chars: {}
            }
          end
        end
      end
    end
  end

  # Parses simple prefix mapping format
  def self.parse_simple_schema(discipline, schema)
    discipline.prefix.each do |key, value|
      if key.is_a?(String) && key.length == 1
        schema[:next_chars][key] = {
          name: value,
          type: :prefix,
          next_chars: {}
        }
      end
    end
  end

    def set_loop_id
      self.loop_id = "#{prefix[0].upcase}#{serial.to_s.rjust(4, '0')}" if prefix.present? && serial.present?
    end

    def set_full_tag
      # Set the full_tag on the instance using self.full_tag
      discipline = Discipline.find(self.discipline_id).code
      self.full_tag = "#{discipline}:#{prefix}-#{serial.to_s.rjust(4, '0')}"

      # Add suffix if it's present
      self.full_tag += ".#{suffix}" if suffix.present?
    end

    def set_prefix
      if self.new_prefix.present? && self.prefix.empty?
        self.prefix = self.new_prefix
      end
    end
end
