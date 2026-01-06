# frozen_string_literal: true

module Electrical
  class Cable < Base
  include ::Tagable
  include TagableNavigation
  
  # Default scope to sort by tag's loop_id, prefix, and suffix
  default_scope { includes(:tag).order('tags.loop_id', 'tags.prefix', 'tags.suffix') }
  
  belongs_to :electrical_cable_type, class_name: 'Electrical::CableType'

  belongs_to :from, polymorphic: true, optional: true
  belongs_to :to, polymorphic: true, optional: true

  # Validations
  validates :electrical_cable_type, presence: true
  
  # In Cable model
  validates :from_id, uniqueness: { scope: [:from_type] }, 
    if: -> { from_type.present? && from_id.present? }
  validates :to_id, uniqueness: { scope: [:to_type] }, 
    if: -> { to_type.present? && to_id.present? }

    def self.ransackable_attributes(auth_object = nil)
      ["electrical_cable_type_id", "route_length", "vertical_allowance", "termination_allowance",
        "start_mark", "end_mark", "notes", "created_at", "updated_at"]
    end

    def self.ransackable_associations(auth_object = nil)
      [:tag, :tag_discipline, :tag_discipline_project, :electrical_cable_type, :from, :to]
    end
  end
end