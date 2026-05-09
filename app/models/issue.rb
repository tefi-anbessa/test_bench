# frozen_string_literal: true

class Issue < ApplicationRecord
  
# Default scope.
  default_scope { order(code: :asc) }

# Belongs to associatons
  belongs_to :document
  delegate :project, :discipline, to: :document
  belongs_to :source_format, optional: true
  
# enum declarations
  
# Presence validation for required fields.
  validates :code, presence: true, 
    length: { maximum: 10 }, 
    uniqueness: { scope: :document_id }
  validates :reason, presence: true, 
    length: { maximum: 50 }

  def label
      "#{code}"
  end
  
  private

    def self.ransackable_attributes(auth_object = nil)
      [:code, :reason, :created_at, :updated_at]
    end

    def self.ransackable_associations(auth_object = nil)
      [:document, :source_format, :project]
    end
end
