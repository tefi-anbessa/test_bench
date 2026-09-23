# frozen_string_literal: true
class DocType < ApplicationRecord
  
  # === Mixins ===

  # === Constants ===

  # === Gem macros ===
  # Record all changes to this model's data
  has_paper_trail

  # === Attributes ===

  # === Associations ===
  belongs_to :discipline
  has_one :project, through: :discipline
  has_many :documents, dependent: :destroy

  # === Scopes ===

  # === Validations ===
  validates :code, presence: true, length: { maximum: 6 }
  validates :name, presence: true, length: { maximum: 50 } 

  validates :code, uniqueness: { scope: :discipline_id }

  # === Callbacks ===

  # === Class methods ===
  def self.swatch
    Swatch.find_by(name: "app_theme")
  end
  
  def self.required_role
    :document_controller
  end

  # === Class methods - Queries ===
  # Provide SQL for ordering doc types in the navigator
  def self.navigator_order_sql
    <<~SQL.squish
      projects.code ASC,
      disciplines.sort_order ASC,
      doc_types.code ASC
    SQL
  end

  # === Public methods ===
  def label
    code
  end

  def long_label
    "#{discipline.code}: #{code}"
  end

  private

    # === Private methods ===
    def self.ransackable_attributes(auth_object = nil)
      [:code, :name, :description, :created_at, :updated_at]
    end

    def self.ransackable_associations(auth_object = nil)
      [:discipline, :documents]
    end
end
