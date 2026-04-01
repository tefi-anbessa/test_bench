# frozen_string_literal: true
module DocumentControl
  class DocType < Base

  # Associatons
    belongs_to :discipline
    has_many :documents

    # Define project association for polymorphic tagging
    delegate :project, to: :discipline
    
    # Presence validation for required fields.
    validates :code, presence: true, length: { maximum: 6 }
    validates :label, presence: true, length: { maximum: 50 }
    
  # Uniqueness validation for unique fields.
    validates :code, uniqueness: { scope: :discipline_id }
    
    private

      def self.ransackable_attributes(auth_object = nil)
        [:code, :label, :description, :created_at, :updated_at]
      end

      def self.ransackable_associations(auth_object = nil)
        [:discipline, :documents]
      end
  end
end
