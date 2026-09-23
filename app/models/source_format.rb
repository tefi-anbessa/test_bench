# frozen_string_literal: true

# Source format is a simple collection of software application references, used to avoid duplication. 
# The collection is not project related, so any entry is available to all.
# It is linked to document issues, so a document may change its source format through its life cycle.
# Avoid using the reverse relationship, unless project context is carefully managed.
class SourceFormat < ApplicationRecord

  # === Mixins ===

  # === Constants ===

  # === Gem macros ===
  has_paper_trail

  # === Attributes ===

  # === Associations ===
  has_many :issues

  # === Scopes ===

  # === Validations ===
  validates :title, presence: true, length: { maximum: 50 }

  # Uniqueness validation for unique fields.
  validates :revision, uniqueness: { scope: :title }, length: { maximum: 20 }
  validates :file_extension, length: { maximum: 10 }, format: { with: /\A\./ }

  # === Callbacks ===

  # === Class methods ===
  def self.swatch
    Swatch.find_by(name: "app_theme")
  end

  def self.required_role
    :document_controller
  end

  # === Class methods - Queries ===
  # Provide SQL for ordering disciplines in the navigator
  def self.navigator_order_sql
    <<~SQL.squish
      title ASC,
      revision ASC
    SQL
  end

  # === Public methods ===
  def label
    "#{title} #{revision}"
  end

  # === Private methods ===

  private

    def self.ransackable_attributes(auth_object = nil)
      [:vendor, :title, :file_extension, :revision, :notes, :created_at, :updated_at]
    end

    def self.ransackable_associations(auth_object = nil)
      [ :issues ]
    end
end
