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

  # Create all disciplines for a new project from constants
  def self.create_all_for_project(project)
    return [] unless Constants.respond_to?(:disciplines)
    return [] unless project.disciplines.count == 0
    Constants.disciplines.to_h.map do |name, attrs|
      create!(
        project: project,
        name: name.to_s,
        code: attrs[:code],
        prefix_schema: attrs[:prefix_schema],
        sort_order: attrs[:sort_order],
        required_role: attrs[:required_role]
      )
    end
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
                  # Try JSON first, then YAML
                  begin
                    JSON.parse(prefix_schema)
                  rescue JSON::ParserError
                    YAML.safe_load(prefix_schema) rescue prefix_schema
                  end
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
