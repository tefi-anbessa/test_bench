# frozen_string_literal: true

module Electrical
  class Cable < Base
    include ::Tagable

    # Default scope to sort by tag's loop_id, prefix, and suffix
    # default_scope { includes(:tag).order('tags.loop_id', 'tags.prefix', 'tags.suffix') }
  
    belongs_to :electrical_cable_type, class_name: 'Electrical::CableType'

    belongs_to :from, polymorphic: true, optional: true
    belongs_to :to, polymorphic: true, optional: true

    # Validations
    validates :electrical_cable_type, presence: true

    # In Cable model
    validate :validate_from_uniqueness
    validate :validate_to_uniqueness

    private

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
      ["electrical_cable_type_id", "route_length", "vertical_allowance", "termination_allowance",
        "start_mark", "end_mark", "notes", "created_at", "updated_at"]
    end

    def self.ransackable_associations(auth_object = nil)
      [:tag, :tag_discipline, :tag_discipline_project, :electrical_cable_type, :from, :to]
    end
  end
end