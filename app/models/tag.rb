class Tag < ApplicationRecord
  delegated_type :tagable, types: Constants.tagable, optional: true, dependent: :destroy
  belongs_to :discipline
  delegate :project, to: :discipline

  has_paper_trail(
    meta: {
      project_id: ->(tag) { tag.project&.id }
    }
  )

  # Default scope to sort by loop_id, then by full_tag
  default_scope { order(:loop_id, :prefix, :suffix) }

  validates :prefix, presence: true
  validates :prefix, format: { with: /\A[a-zA-Z]+\z/, message: :only_letters }
  validates :prefix, length: { in: 1..6 }

  validates :serial, presence: true
  validates :serial, numericality: { only_integer: true, greater_than_or_equal_to: 0, less_than_or_equal_to: 9999 }
  validates :suffix, length: { maximum: 5 }
  validates :service, length: { maximum: 40 }
  validates :stage, numericality: { only_integer: true, greater_than_or_equal_to: 0, less_than_or_equal_to: 10 }

  # Prevent changing tagable association if it's already set and valid
  validate :validate_tagable_reassignment, on: :update
  validate :validate_tagable_assignment, on: [:create, :update], 
                if: -> { tagable_type.present? && tagable_id.present? }

  # Allow setting tagable_type without tagable_id to indicate intended type
  # Only validate presence of tagable_id if we're setting a non-nil value
  # validates :tagable_id, presence: { message: 'must be present when setting a tagable' }, 
  #                       if: -> { tagable_type.present? && tagable_id_changed? && tagable_id.present? }
  validates :tagable_type, inclusion: { in: Constants.tagable }, 
                           allow_nil: true,
                           allow_blank: true
  
  # Ensure a tagable is only associated with one tag
  validate :tagable_not_already_associated, if: -> { tagable_id.present? && tagable_type.present? }
  
  # Ensure tag is unique within the same discipline
  # This is required because of doubts over using a database uniqueness contraint with 
  # suffix, which may be null.
  validate :validate_tag_uniqueness

  def label
    full_tag
  end

  def long_label
    "#{discipline.label}: #{full_tag}"
  end

  # Track original values to detect changes
  def initialize(*)
    super
    @original_tagable_type = tagable_type
    @original_tagable_id = tagable_id
  end

  # Get the next tag in the discipline, ordered by loop_id, prefix, and suffix
  def next(attribute = :loop_id)
    return super(attribute) unless attribute == :loop_id
    
    adjacent_tag('next_id') || self
  end

  # Get the previous tag in the discipline, ordered by loop_id, prefix, and suffix
  def prev(attribute = :loop_id)
    return super(attribute) unless attribute == :loop_id
    
    adjacent_tag('prev_id') || self
  end

  # Instance method to parse prefix components for form display
  def prefix_parts
    return nil unless prefix.present? && prefix.length >= 2 && discipline&.prefix_schema.present?
    parts = {}
    chars = prefix.chars
    if discipline.custom_schema?
      parser = discipline.prefix_schema['type'].to_sym
      schema = discipline.prefix_schema.with_indifferent_access
    else
      parser = Constants.prefix_schemata[discipline.prefix_schema['name'].to_sym][:type].to_sym
      schema = Constants.prefix_schemata[discipline.prefix_schema['name'].to_sym].with_indifferent_access
    end

    case parser
    when :isa51
      char = chars.shift()
      # Check measured variables if they exist
      if schema[:measured_variables]&.keys&.map(&:to_s)&.include?(char)
        parts[:measured_variable] = char
      else
        # No valid measured variable character, not a valid isa prefix...
        return nil
      end

      char = chars.shift()
      # Check modifiers if they exist (optional section)
      if schema[:modifiers]&.keys&.map(&:to_s)&.include?(char)
        parts[:modifier] = char
      else
        parts[:modifier] = nil
        chars.unshift(char)
      end

      char = chars.shift()
      # Check functions - either readout or output functions
      if schema[:readout_functions]&.keys&.map(&:to_s)&.include?(char)
        parts[:readout_function] = char
        parts[:output_function] = nil
      elsif schema[:output_functions]&.keys&.map(&:to_s)&.include?(char)
        parts[:readout_function] = nil
        parts[:output_function] = char
      else
        # No function character, not a valid isa prefix...
        return nil
      end

      # Check modifier functions if they exist (optional section)
      mf = chars.join # remaining characters
      if schema[:modifier_functions]&.keys&.map(&:to_s)&.include?(mf)
        parts[:modifier_function] = mf
      else
        parts[:modifier_function] = nil
      end
      return parts

    when :dim1
      if schema[:prefixes]&.keys&.map(&:to_s)&.include?(chars)
        parts[:prefix] = chars
      else
        # Not a valid prefix in the standard list.
        return nil
      end 
      return parts

    when :dim2
      parts[:part1] = schema[:part1].keys.map(&:to_s).find { |p| prefix.start_with?(p) }
      return nil unless parts[:part1] # not a valid dim2 prefix
      parts[:part2] = prefix[parts[:part1].length..-1]
      unless parts[:part2].present? && schema[:part2]&.key?(parts[:part2].to_sym)
        parts[:part2] = nil # return valid part 1 and nil part 2
      end
      return parts
    end
  end
  
  private
  
    # Find adjacent tag (next or previous) based on the given join condition
    def adjacent_tag(join_column)
      return nil unless discipline_id
      
      sql = <<-SQL
        WITH ordered_tags AS (
          SELECT id,
                loop_id,
                prefix,
                COALESCE(suffix, '') as suffix_sort,
                LAG(id) OVER (ORDER BY loop_id, prefix, COALESCE(suffix, '')) as prev_id,
                LEAD(id) OVER (ORDER BY loop_id, prefix, COALESCE(suffix, '')) as next_id
          FROM tags
          WHERE discipline_id = :discipline_id
        )
        SELECT t.*
        FROM tags t
        JOIN ordered_tags ot ON t.id = ot.#{join_column}
        WHERE ot.id = :current_id
      SQL
      
      self.class.find_by_sql([sql, { discipline_id: discipline_id, current_id: id }]).first
    end
  
    # Custom validation to handle suffix uniqueness with NULL values in the database
    def validate_tag_uniqueness
      return unless discipline_id && prefix && serial
      
      # Convert empty string to nil for comparison
      suffix_value = suffix.presence
      
      # Check for existing tags with the same combination within the same discipline
      existing = self.class.where(
        discipline_id: discipline_id,
        prefix: prefix,
        serial: serial
      ).where("COALESCE(suffix, '') = ?", suffix_value.to_s)
      
      # Exclude self from the check if this is an update
      existing = existing.where.not(id: id) if persisted?
      
      errors.add(:base, I18n.t("errors.messages.taken")) if existing.any?
    end
    
    # Prevent re-assigning a tagable to a different tag
    def tagable_not_already_associated
      return unless tagable_id.present? && tagable_type.present?
      
      existing_tag = Tag.where(
        tagable_id: tagable_id,
        tagable_type: tagable_type
      ).where.not(id: id).exists?
      
      if existing_tag
        errors.add(:tagable, I18n::t("activerecord.errors.custom_messages.already_associated", 
          child: tagable_type.constantize.model_name.human,
          parent: self.class.model_name.human))
      end
    end

    # Prevent changing tagable association if it's already set and valid
    def validate_tagable_reassignment
      return unless tagable_type_changed? || tagable_id_changed?
      return if tagable_id_was.blank? || tagable_type_was.blank?
      
      # Allow changes if the current association is invalid
      return unless self.class.tagable_types.include?(tagable_type_was)
      return if tagable_type_was.constantize.where(id: tagable_id_was).none?
      
      errors.add(:base, I18n::t("activerecord.errors.attributes.tag.tagable_type.change_tagable")) 
    end

    # Prevent setting tagable association to an invalid resource
    def validate_tagable_assignment
      if (tagable_type.constantize rescue nil)&.where(id: tagable_id)&.none?
        errors.add(:tagable, :invalid)
      end
    end

    # Returns tags grouped by their loop identifier
    # @return [Hash] Tags grouped by loop_id
    def self.grouped_by_loop
      all.group_by(&:loop_id)
    end

    def self.ransackable_attributes(auth_object = nil)
      ["discipline_id", "prefix", "serial", "suffix", "full_tag", "loop_id", "service", "location", "stage",
        "notes", "created_at", "updated_at"]
    end

    def self.ransackable_associations(auth_object = nil)
      ["discipline", "project"] + Tag.tagable_types.map { |type| type.underscore.pluralize }
    end
end
