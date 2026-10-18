# frozen_string_literal: true
class Document < ApplicationRecord
  # === Mixins ===

  # === Constants ===
  # Index can be reached scoped to either parent - discipline is this
  # record's own true, direct parent (indirect, via doc_type); project is
  # a broader, index-only convenience. Order matters - see
  # CableType::NESTED_SCOPES.
  NESTED_SCOPES = %i[discipline project].freeze

  # === Gem macros ===
  # Record all changes to this model's data
  has_paper_trail

  # === Attributes ===
  # Lock doc_type_id, serial (therefore document number) after creation
  attr_readonly :doc_type_id, :serial
  # Transient, not a DB column - lets a throwaway/unsaved Document used only
  # for a policy check (e.g. "can this user create a document in this
  # discipline", from a discipline's own show page, before any doc_type is
  # chosen) resolve #discipline without one. See #doc_type_matches_discipline
  # below for why this can't just be trusted blindly once a real doc_type is
  # also present - mirrors Cable#creation_discipline for the same shape of
  # problem (discipline normally derived, not resolvable yet pre-selection).
  attr_accessor :creation_discipline

  # === Associations ===
  belongs_to :doc_type
  has_one :discipline, through: :doc_type
  has_one :project, through: :discipline
  has_many :issues, dependent: :destroy

  # === Scopes ===
  # default_scope { order(:doc_number) }

  # === Validations ===
  validates :title, presence: true, length: { maximum: 50 }
  validate :doc_type_matches_discipline

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
  def discipline
    creation_discipline || super
  end

  # #project is through: :discipline, which is itself through: :doc_type -
  # Rails resolves a through-chain via its own association reflections, not
  # by calling #discipline above, so the creation_discipline override has
  # to be repeated here too for policy checks on a doc_type-less draft to
  # resolve a project at all.
  def project
    creation_discipline&.project || super
  end

  def label
    doc_number
  end

  def long_label
    # Document number already includes discipline.code
    doc_number
  end

  private

    # === Private methods ===
    def doc_type_matches_discipline
      return if doc_type.blank? || creation_discipline.blank?
      return if doc_type.discipline == creation_discipline
      errors.add(:doc_type, I18n.t("activerecord.errors.models.document.attributes.doc_type.discipline_mismatch"))
    end

    def set_document_number
      Document.transaction do
        # Lock existing records for this doc_type (discipline is implied by it)
        Document.where(doc_type_id: doc_type_id).lock

        # Now safely set serial and doc_number
        max_serial = Document.where(doc_type_id: doc_type_id).maximum(:serial) || 0
        self.serial = max_serial.to_i + 1
        
        separator = Constants.document.separator
        self.doc_number = "#{discipline.project.label}#{separator}#{discipline.code}#{separator}#{doc_type.code}#{separator}#{serial.to_s.rjust(Constants.document.serial_digits, '0')}"
        
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
