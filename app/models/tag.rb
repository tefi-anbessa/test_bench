class Tag < ApplicationRecord
  # === Mixins ===
  
  # === Constants ===

  # === Gem macros ===
  has_paper_trail

  # === Attributes ===

  # === Associations ===
  delegated_type :tagable, types: Constants.tagable, optional: true, dependent: :destroy
  belongs_to :discipline
  has_one :project, through: :discipline

  belongs_to :parent, class_name: 'Tag', optional: true
  has_many :children, class_name: 'Tag', foreign_key: 'parent_id', inverse_of: :parent, 
    dependent: :nullify

  # === Scopes ===
  # Sort by loop_id, then by full_tag
  # scope :sort_by_loop, -> { order(:loop_id, :prefix, :suffix) }
  # Sort by prefix/serial/suffix
  # scope :sort_by_tag, -> { order(:prefix, :serial, :suffix) }
  # 

  # === Validations ===
  validates :prefix, presence: true
  validates :prefix, format: { with: /\A[a-zA-Z]+\z/, message: :only_letters }
  validates :prefix, length: { in: 1..6 }

  validates :serial, presence: true
  validates :serial, numericality: { only_integer: true, greater_than_or_equal_to: 0, less_than: 10**Constants.tags.serial_digits.to_i }
  validates :suffix, length: { maximum: 5 }
  validates :service, length: { maximum: 40 }
  validates :stage, numericality: { only_integer: true, greater_than_or_equal_to: 0, less_than_or_equal_to: 10 }

  # Prevent changing tagable association if it's already set and valid
  # Allow reset if existing is not valid.
  validate :validate_tagable_reassignment, on: :update

  # Allow setting tagable_type without tagable_id to indicate intended type
  # Only validate presence of tagable_id if we're setting a non-nil value
  # validates :tagable_id, presence: { message: 'must be present when setting a tagable' }, 
  #                       if: -> { tagable_type.present? && tagable_id_changed? && tagable_id.present? }
  validates :tagable_type, inclusion: { in: Constants.tagable }, 
                           allow_nil: true
  
  # Ensure a tagable is only associated with one tag
  validate :tagable_not_already_associated, if: -> { tagable_id.present? && tagable_type.present? }
  
  # Ensure tag is unique within the same discipline
  # This is required because of doubts over using a database uniqueness contraint with 
  # suffix, which may be null.
  validate :validate_tag_uniqueness

  # Validations for the parent child relationship
  validate :prevent_circular_reference
  validate :prevent_cross_project_reference

  # === Callbacks ===
  before_validation :clear_tagable_id_if_invalid, on: :update
  nilifies_blank :tagable_type

  # === Class methods ===
  def self.safe_tagable_types
    Tag.tagable_types.select{ |type| type.safe_constantize.present? }.map { |type| [type.safe_constantize.model_name.human, type] }
  end

  # === Class methods - Queries ===
  # Provide SQL for ordering tags in the navigator
  # Tag model is a special case, tags are ordered differently if the discipline uses ISA51 prefix schema
  def self.navigator_order_sql
    <<~SQL.squish
      projects.code ASC,
      disciplines.sort_order ASC,
      CASE
        WHEN COALESCE(
          disciplines.prefix_schema->>'type',
          disciplines.prefix_schema->>'name'
        ) = 'isa51'
        THEN tags.loop_id
        ELSE tags.full_tag
      END ASC,
      tags.full_tag ASC
    SQL
  end

  # LEGACY CODE?
  # Returns tags grouped by their loop identifier
  # @return [Hash] Tags grouped by loop_id
  def self.grouped_by_loop
    all.group_by(&:loop_id)
  end

  # === Public methods ===
  def label
    full_tag
  end

  def long_label
    "#{discipline.code}#{Constants.tags.separator}#{full_tag}"
  end

  # Only use for tests
  def next_serial
    Tag.where(discipline: discipline, prefix: prefix, suffix: suffix)
      .maximum(:serial)
      .to_i + 1
  end

  # Public method to parse prefix components for form display
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

  # Parent child methods
  def root?
    parent_id.nil?
  end

  def leaf?
    children.empty?
  end

  def depth
    return 0 if root?
    1 + parent.depth
  end

  def ancestor_ids
    return [] if root?
    current = parent
    found = Set.new
    while current && !found.include?(current.id)
      found.add(current.id)
      current = current.parent
    end
    found.to_a
  end

  def ancestors
    Tag.where(id: ancestor_ids)
  end

  def descendant_ids
    return [] if leaf? || new_record?
    queue = children.to_a
    found = Set.new

    while queue.any?
      node = queue.shift
      next if found.include?(node.id)

      found.add(node.id)
      queue.concat(node.children)
    end
    found.to_a
  end

  def prospective_parents(scope)
    # Return all tags from the provided scope that are not descendants of this tag, or this tag itself
    # Use for selector
    return scope if new_record?
    scope.where.not(id: descendant_ids + [id])
  end

  # === Private methods ===

  private

    def normalize_tagable_type
      self.tagable_type = self.tagable_type&.to_s&.classify
    end

    def clear_tagable_id_if_invalid
      # Do nothing if previous association was valid.
      type_was = tagable_type_in_database
      klass = type_was.present? ? type_was.safe_constantize : nil
      return if klass && klass.find_by(id: tagable_id_in_database).present?
      if will_save_change_to_tagable_type?
        self.tagable_id = nil
      end
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
        errors.add(:tagable, I18n.t("activerecord.errors.custom.already_associated", 
          child: tagable_type.constantize.model_name.human,
          parent: self.class.model_name.human))
      end
    end

    # Prevent changing tagable association if it's already set and valid
    def validate_tagable_reassignment
      return unless will_save_change_to_tagable_type? || will_save_change_to_tagable_id?
      type_was = tagable_type_in_database
      id_was = tagable_id_in_database
      return if id_was.nil? || type_was.nil?
      
      # Allow changes if the current association is invalid
      return unless self.class.tagable_types.include?(type_was)
      return if type_was.constantize.where(id: id_was).none?
      
      errors.add(:base, I18n::t("activerecord.errors.models.tag.attributes.tagable_type.change_tagable")) 
    end

    # Parent child association validations
    def prevent_circular_reference
      return unless parent

      if parent == self
        errors.add(:parent, :self)
      elsif id && parent.ancestor_ids.include?(id)
        errors.add(:parent, :circular)
      end
    end

    def prevent_cross_project_reference
      return unless parent
      if parent.project.id != project.id
        errors.add(:parent, I18n.t("activerecord.errors.models.tag.attributes.parent.project"))
      end
    end

    def self.ransackable_attributes(auth_object = nil)
      ["discipline_id", "prefix", "serial", "suffix", "full_tag", "loop_id", "service", "location", "stage",
        "notes", "parent_id", "created_at", "updated_at"]
    end

    def self.ransackable_associations(auth_object = nil)
      ["discipline", "project", "parent", "children"] + Tag.tagable_types.map { |type| type.underscore.pluralize }
    end
end
