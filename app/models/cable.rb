# frozen_string_literal: true

class Cable < ApplicationRecord

  # === Mixins ===
  include Tagable

  # === Constants ===

  # === Gem macros ===

  # === Attributes ===
  # Transient, not a DB column - set by Electrical::CableExtension#tagable_params
  # (or any other discipline's own extension) before the record is first
  # validated. See #cable_type_matches_discipline below for why this is
  # necessary: on create, the owning Tag's belongs_to-autosave saves this
  # record *before* the Tag row's own tagable_id is written, so #discipline
  # (has_one, through: :tag, from the Tagable concern) can't resolve yet -
  # there is no Tag row pointing back at this not-yet-persisted id. The
  # controller already knows the discipline at that point (it's fixed by
  # the nested route), so it's passed in explicitly rather than guessed.
  # Not needed on update - by then the Tag is already persisted and
  # #discipline resolves normally.
  attr_accessor :creation_discipline

  # === Associations ===
  # Plain, not polymorphic - CableType is a single shared class (its own
  # discipline-specific remainder is handled internally via delegated_type,
  # see app/models/cable_type.rb), so Cable only ever points at one class.
  belongs_to :cable_type

  belongs_to :from, polymorphic: true, optional: true
  belongs_to :to, polymorphic: true, optional: true

  # === Scopes ===

  # === Validations ===
  validate :cable_type_matches_discipline
  validate :validate_from_uniqueness
  validate :validate_to_uniqueness

  # === Callbacks ===

  # === Class methods ===
  def self.safe_connection_types
    Constants.electrical.connect_options.select{ |type| type.safe_constantize.present? }
  end

  # Whether this (now core) tagable type is available for a given
  # discipline - the hook Discipline#accepts_tagable_type? falls back to
  # for a type with no module of its own to match against. Available
  # wherever the discipline's own module defines a CableType detail class
  # (CableType itself is shared - what varies per discipline is only
  # whether it has a delegated detail subtype to attach).
  def self.discipline_available?(discipline)
    discipline.cable_type_detail_class.present?
  end

  # === Public methods ===

  # === Private methods ===
  private

    # See the #creation_discipline comment above for why this can't just
    # read #discipline unconditionally - on create, it isn't resolvable yet.
    def cable_type_matches_discipline
      return if cable_type.blank?
      effective_discipline = creation_discipline || discipline
      return if effective_discipline.blank?
      return if cable_type.discipline == effective_discipline
      errors.add(:cable_type, I18n.t("activerecord.errors.models.cable.attributes.cable_type.discipline_mismatch"))
    end

    def validate_from_uniqueness
      return unless from_type.present? && from_id.present?
      if Cable.where(from_type: from_type, from_id: from_id).where.not(id: id).exists?
        errors.add(:from_id, :taken)
      end
    end

    def validate_to_uniqueness
      return unless to_type.present? && to_id.present?
      if Cable.where(to_type: to_type, to_id: to_id).where.not(id: id).exists?
        errors.add(:to_id, :taken)
      end
    end

    def self.ransackable_attributes(auth_object = nil)
      ["route_length", "vertical_allowance", "termination_allowance",
        "start_mark", "end_mark", "notes", "created_at", "updated_at"]
    end

    def self.ransackable_associations(auth_object = nil)
      [:tag, :tag_discipline, :tag_discipline_project, :cable_type, :from, :to]
    end
end
