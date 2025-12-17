class Discipline < ApplicationRecord
  has_many :tags, dependent: :destroy
  belongs_to :project

  before_validation :normalize_prefix_schema
  validates :code,        presence: true, length: { maximum: 12},
                          uniqueness:  { scope: :project_id },
                          format: { 
                            with: /\A[a-zA-Z_][a-zA-Z0-9_]*\z/,
                            message: :invalid_symbol
                          }
  validates :name, presence: true, length: { maximum: 50 }
  validates :prefix_schema, presence: true
  validate :validate_prefix_schema

  default_scope { order(project_id: :asc, sort_order: :asc) }

  def custom_schema?
    prefix_schema.present? && !Constants.prefix_schemata.key?(prefix_schema['name']&.to_sym)
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

    def self.ransackable_attributes(auth_object = nil)
      ["code", "label", "name", "prefix_schema", "module_name", "sort_order", "notes"]
    end

    def self.ransackable_associations(auth_object = nil)
      ["tags", "documents"]
    end
end
