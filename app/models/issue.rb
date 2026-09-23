# frozen_string_literal: true

class Issue < ApplicationRecord

  # === Mixins ===

  # === Constants ===

  # === Gem macros ===

  # === Attributes ===

  # === Associations ===
  belongs_to :document
  has_one :discipline, through: :document
  has_one :project, through: :discipline

  belongs_to :source_format, optional: true

  # === Scopes ===

  # === Validations ===
  validates :code, presence: true, 
    length: { maximum: 10 }, 
    uniqueness: { scope: :document_id }
  validates :reason, presence: true, 
    length: { maximum: 50 }

  # === Callbacks ===

  # === Class methods ===

  # === Class methods - Queries ===
  # Provide SQL for ordering documents in the navigator
  def self.navigator_order_sql
    <<~SQL.squish
      documents.doc_number ASC,
      issues.code ASC
    SQL
  end

  def self.navigator_order
    [
      { table: "documents", column: "doc_number", direction: :asc, nulls: :first },
      { table: :base, column: "code", direction: :asc }
    ]
  end

  # === Public methods ===
  def label
    code
  end

  def long_label
    [document.doc_number, code].join(" ")
  end

  private

    # === Private methods ===
    def self.ransackable_attributes(auth_object = nil)
      [:code, :reason, :created_at, :updated_at]
    end

    def self.ransackable_associations(auth_object = nil)
      [:document, :source_format, :project]
    end
end
