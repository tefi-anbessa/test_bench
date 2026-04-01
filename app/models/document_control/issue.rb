# frozen_string_literal: true
module DocumentControl
  class Issue < Base

# Belongs to associatons
    belongs_to :document
    delegate :project, to: :document
    delegate :discipline, to: :document
    belongs_to :source_format, 
      class_name: "DocumentControl::SourceFormat", 
      foreign_key: "document_control_source_format_id",
      optional: true
    
# enum declarations
    
# Presence validation for required fields.
    validates :code, presence: true, 
      length: { maximum: 10 }, 
      uniqueness: { scope: :document_id }
    validates :reason, presence: true, 
      length: { maximum: 50 }
    
# Default scope.
    default_scope { order(code: :asc) }
    
    private

      def self.ransackable_attributes(auth_object = nil)
        [:code, :reason, :created_at, :updated_at]
      end

      def self.ransackable_associations(auth_object = nil)
        [:document, :document_control_source_format, :project]
      end
  end
end
