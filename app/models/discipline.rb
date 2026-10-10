class Discipline < ApplicationRecord
  # === Mixins ===

  # === Constants ===

  # === Gem macros ===
  # Rolify can set roles scoped to discipline
  resourcify
  # Record all changes to this model's data
  has_paper_trail

  # === Attributes ===

  # === Associations ===
  belongs_to :project
  belongs_to :swatch, optional: true
  has_many :tags, dependent: :destroy
  has_many :documents, dependent: :destroy
  has_many :electrical_cable_types, class_name: 'Electrical::CableType', dependent: :destroy
  has_many :doc_types, dependent: :destroy

  # === Scopes ===
  # default_scope { order(project_id: :asc, sort_order: :asc) }

  # === Validations ===
  before_validation :normalize_prefix_schema
  validates :name, presence: true, length: { maximum: 50 }, uniqueness: { scope: :project_id }
  validates :code, presence: true, length: { maximum: 5 }, uniqueness: { scope: :project_id }
  validates :prefix_schema, presence: true
  validate :validate_required_role
  validate :validate_prefix_schema

  # === Callbacks ===

  # === Class methods ===
  def self.required_role
    :project_admin
  end

  # === Class methods - Queries ===
  # Provide SQL for ordering disciplines in the navigator
  def self.navigator_order_sql
    <<~SQL.squish
      projects.code ASC,
      disciplines.sort_order ASC
    SQL
  end

  # === Public methods ===
  def label
    code
  end

  def long_label
    "#{project.label} - #{code}"
  end

  # The name to display for this discipline, in the viewer's current
  # locale. Only translates when the name still matches the standard
  # registry's default for this code - i.e. the project never customized
  # it. A renamed (or project-defined, non-standard) discipline shows its
  # own stored name as-is, untranslated - "custom content is not
  # translated", same rule the old discipline.<locale>.yml files already
  # stated. Translating unconditionally by code (ignoring whether the name
  # was customized) would show "Electrical" forever even after a project
  # renamed it to something else, which defeats the point of the rename.
  def display_name
    entry = registry_entry
    return name if entry.nil? || name != entry[:name]
    I18n.t("discipline.name.#{code}", default: name)
  end

  # The standard discipline registry (config/constants/discipline.yml),
  # keyed by code - the structural identifier. Used both to offer choices
  # when creating a project and to resolve per-discipline defaults (see
  # #registry_entry below). Not every project needs every entry here, and a
  # project may also have disciplines with codes that aren't in this list
  # at all - those are project-defined, module-less disciplines, same as
  # any entry below with module: nil.
  def self.standard_options
    return {} unless Constants.respond_to?(:disciplines)
    Constants.disciplines.to_h
  end

  # Create only the selected disciplines for a new project, from the
  # standard registry. Replaces the old create_all_for_project, which gave
  # every project every standard discipline whether it needed it or not.
  def self.create_selected_for_project(project, codes:)
    return [] unless project.disciplines.count == 0
    codes.filter_map do |code|
      attrs = standard_options[code.to_sym]
      next unless attrs
      create!(
        project: project,
        name: attrs[:name],
        code: code.to_s,
        prefix_schema: attrs[:prefix_schema],
        sort_order: attrs[:sort_order],
        required_role: attrs[:required_role]
      )
    end
  end

  # This discipline's entry in the standard registry, if it has one - a
  # project-defined discipline whose code isn't in config/constants/
  # discipline.yml simply has none, and falls back to whatever its own
  # columns say (see #default_required_role et al below).
  def registry_entry
    self.class.standard_options[code&.to_sym]
  end

  # The bare Ruby module name backing this discipline's content (e.g.
  # "Electrical"), or nil if none exists yet - see discipline.yml's module:
  # field. A discipline with no backing module is not broken; it just has
  # no generated equipment forms. Tags and documents work regardless.
  def module_name
    registry_entry&.[](:module)&.to_s
  end

  # The module's Base class (e.g. Electrical::Base), where defaults like
  # #swatch live - see app/models/electrical/base.rb.
  def backing_module
    return nil if module_name.nil?
    "#{module_name}::Base".safe_constantize
  end

  def module_backed?
    backing_module.present?
  end

  # Falls back to the registry's default for this code, not to the backing
  # module's own class method - the registry (data) is the single source
  # of truth for these defaults now, not a second copy living in Ruby.
  def default_required_role
    registry_entry&.[](:required_role)&.to_s
  end

  def default_catalog_required_role
    registry_entry&.[](:catalog_required_role)&.to_s
  end

  def custom_schema?
    prefix_schema.present? && !Constants.prefix_schemata.key?(prefix_schema['name']&.to_sym)
  end

  def isa51_type_schema?
    prefix_schema&.dig('name') == 'isa51' || (custom_schema? && prefix_schema&.dig('type') == 'isa51')
  end

  def default_prefix_schema_name
    return prefix_schema['name'] if prefix_schema.present? && prefix_schema['name'].present?
    "#{project&.label}_#{code}".parameterize.underscore
  end

  def schema_for_form
    return {} if prefix_schema.blank? 
    if custom_schema?
      prefix_schema
    else
      Constants.prefix_schemata[prefix_schema['name']&.to_sym]
    end
  end

  # === Private methods ===

  private
  
    def normalize_prefix_schema
      return if prefix_schema.blank?
      
      begin
        parsed = case prefix_schema
                when String
                  JSON.parse(prefix_schema)
                when Hash
                  prefix_schema
                else
                  prefix_schema.to_h
                end

        if parsed.is_a?(Hash)
          self.prefix_schema = parsed
          if (name = parsed['name'] || parsed[:name] || parsed['name:'] || parsed[:'name:'])
            self.prefix_schema = { 'name' => name.to_s.gsub(/\A:|:\z/, '') } if Constants.prefix_schemata.key?(name.to_s.gsub(/\A:|:\z/, '').to_sym)
          end
        end
      rescue => e
        Rails.logger.error("Failed to parse prefix_schema: #{e.message}")
        nil
      end
    end
  
    def validate_prefix_schema
      return if prefix_schema.blank?
      
      # Ensure it's a hash
      unless prefix_schema.is_a?(Hash)
        errors.add(:prefix_schema, :invalid)
        return
      end
      
      # If it's a named schema from constants, we're done
      if (name = prefix_schema['name'] || prefix_schema[:name])
        return if Constants.prefix_schemata.key?(name.to_sym)
      end
      
      # Otherwise validate custom schema
      schema_name = prefix_schema['name']
      schema_type = prefix_schema['type']
      
      if schema_name.blank?
        errors.add(:prefix_schema, :blank, 
            message: I18n.t('activerecord.errors.jsonb_fields.blank', 
              field: I18n.t('activerecord.attributes.discipline.prefix_schema_keys.name')))
      end
      
      if schema_type.blank?
        errors.add(:prefix_schema, :blank, 
              message: I18n.t('activerecord.errors.jsonb_fields.blank',
                field: I18n.t('activerecord.attributes.discipline.prefix_schema_keys.type')))
      end
      
      if schema_type.present? && Constants.respond_to?(:prefix_parser_keys)
        unless Constants.prefix_parser_keys.include?(schema_type)
          errors.add(:prefix_schema, :inclusion, 
            message: I18n.t('activerecord.errors.jsonb_fields.included', 
              field: I18n.t('activerecord.attributes.discipline.prefix_schema_keys.type')))
        end
      end
    end

    def validate_required_role
      return if required_role.blank?
      unless Role.valid_role?(required_role, "Discipline")
        errors.add(:required_role, :inclusion)
      end
    end

    def self.ransackable_attributes(auth_object = nil)
      ["code", "name", "prefix_schema", "sort_order", "notes", "required_role"]
    end

    def self.ransackable_associations(auth_object = nil)
      ["tags", "documents", "doc_types", "swatches"]
    end
end
