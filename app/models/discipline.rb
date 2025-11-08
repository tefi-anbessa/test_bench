class Discipline < ApplicationRecord
  has_many :tags, dependent: :destroy
  belongs_to :project

  validates :code,        presence: true, length: { maximum: 12},
                          uniqueness:  { scope: :project_id },
                          format: { 
                            with: /\A[a-zA-Z_][a-zA-Z0-9_]*\z/,
                            message: :invalid_symbol
                          }
  validates :label, presence: true, length: { maximum: 12 },
                          uniqueness: { scope: :project_id }
  validates :name, presence: true, length: { maximum: 50 }
  default_scope { order(project_id: :asc, sort_order: :asc) }
  # This method will automatically convert code to a symbol when read
  def code
    return nil if self[:code].nil? || self[:code].empty?
    self[:code].to_sym
  end

  # This ensures the code is stored as a string in the database
  def code=(value)
    self[:code] = value.to_s
  end

  def custom_schema?
    prefix_schema.present? && 
      (prefix_schema['type'] != 'standard' || 
      !Constants.prefix_schemata.key?(prefix_schema['name']&.to_sym))
  end

  def custom_schema_name
    return prefix_schema['name'] if prefix_schema.present? && prefix_schema['name'].present?
    "#{project&.label}_#{code}".parameterize.underscore
  end

  def self.ransackable_attributes(auth_object = nil)
    ["code", "label", "name", "prefix_schema", "module_name", "sort_order", "notes"]
  end
end
