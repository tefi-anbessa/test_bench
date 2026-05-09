# frozen_string_literal: true
class Document < ApplicationRecord
  # Callbacks
  around_create :set_document_number

  # Associatons
  belongs_to :discipline
  delegate :project, to: :discipline
  belongs_to :doc_type
  has_many :issues, dependent: :destroy

  # Default scope to sort by document number
  default_scope { order(:doc_number) }

  # Presence validation for required fields.
  validates :title, presence: true, length: { maximum: 50 }
  
  # Lock discipline_id, doc_type_id, serial (therefore document number) after creation
  attr_readonly :discipline_id, :doc_type_id, :serial


  def self.required_role
    :document_controller
  end

  # Default discipline to reference back to this module, used in testing. 
  # Not used in the application, as projects can set their own disciplines.
  def self.discipline
    "Document Control"
  end

  def label
    doc_number
  end

  def self.swatch
    Swatch.find_by(name: "app_theme")
  end

  private
    def set_document_number
      Document.transaction do
        # Lock existing records for this discipline/doc_type combination
        Document.where(discipline_id: discipline_id, doc_type_id: doc_type_id)
                .lock
        
        # Now safely set serial and doc_number
        max_serial = Document.where(discipline_id: discipline_id, doc_type_id: doc_type_id)
                            .maximum(:serial) || 0
        self.serial = max_serial.to_i + 1
        
        separator = Constants.documents.separator
        self.doc_number = "#{discipline.project.label}#{separator}#{discipline.label}#{separator}#{doc_type.code}#{separator}#{serial.to_s.rjust(Constants.documents.serial_digits, '0')}"
        
        # Continue with the create (yield runs the actual save)
        yield
      end
    end

    def self.ransackable_attributes(auth_object = nil)
      [:serial, :doc_number, :title, :notes, :created_at, :updated_at]
    end

    def self.ransackable_associations(auth_object = nil)
      [:discipline, :doc_type, :issues]
    end
end
