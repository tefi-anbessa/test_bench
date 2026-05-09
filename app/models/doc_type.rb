# frozen_string_literal: true

class DocType < ApplicationRecord

# Associatons
  belongs_to :discipline
  delegate :project, to: :discipline
  has_many :documents, dependent: :destroy
  
  # Presence validation for required fields.
  validates :code, presence: true, length: { maximum: 6 }
  validates :name, presence: true, length: { maximum: 50 }

  def label
    code
  end

  def long_label
    "#{discipline.label}: #{code}"
  end

  def self.swatch
    Swatch.find_by(name: "app_theme")
  end
  
  def self.required_role
    :document_controller
  end
  
# Uniqueness validation for unique fields.
  validates :code, uniqueness: { scope: :discipline_id }
  
  private

    def self.ransackable_attributes(auth_object = nil)
      [:code, :name, :description, :created_at, :updated_at]
    end

    def self.ransackable_associations(auth_object = nil)
      [:discipline, :documents]
    end
end
