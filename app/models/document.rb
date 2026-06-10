# frozen_string_literal: true
class Document < ApplicationRecord
  # === Mixins ===

  # === Constants ===

  # === Gem macros ===
  # Record all changes to this model's data
  has_paper_trail

  # === Attributes ===
  # Lock discipline_id, doc_type_id, serial (therefore document number) after creation
  attr_readonly :discipline_id, :doc_type_id, :serial

  # === Associations ===
  belongs_to :doc_type
  belongs_to :discipline
  has_one :project, through: :discipline
  has_many :issues, dependent: :destroy

  # === Scopes ===
  # default_scope { order(:doc_number) }

  # === Validations ===
  validates :title, presence: true, length: { maximum: 50 }

  # === Callbacks ===
  around_create :set_document_number

  # === Class methods ===
  def self.required_role
    :document_controller
  end

  def self.swatch
    Swatch.find_by(name: "app_theme")
  end

  # === Class methods - Queries ===
  # Provide SQL for ordering documents in the navigator
  def self.navigator_order_sql
    <<~SQL.squish
      projects.code ASC,
      disciplines.sort_order ASC,
      doc_types.code ASC,
      documents.serial ASC
    SQL
  end

  # === Public methods ===
  def label
    doc_number
  end

  def long_label
    # Document number already includes discipline.code
    doc_number
  end

  private

    # === Private methods ===
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
        self.doc_number = "#{discipline.project.label}#{separator}#{discipline.code}#{separator}#{doc_type.code}#{separator}#{serial.to_s.rjust(Constants.documents.serial_digits, '0')}"
        
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
