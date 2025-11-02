class Cable < ApplicationRecord
  include ::Tagable
  include TagableNavigation
  
  # Default scope to sort by tag's loop_id, prefix, and suffix
  default_scope { includes(:tag).order('tags.loop_id', 'tags.prefix', 'tags.suffix') }
  
  belongs_to :cable_type
  belongs_to :circuit, optional: true

  belongs_to :from, polymorphic: true, optional: true
  belongs_to :to, polymorphic: true, optional: true

  def label
    tag&.label || I18n::t("show.orphan", model: Tag.model_name.human)
  end

  def self.required_role
    :electrical_designer
  end

  # Validations
  validates :cable_type, presence: true
  
# In Cable model
validates :from_id, uniqueness: { scope: [:from_type] }, 
  if: -> { from_type.present? && from_id.present? }
validates :to_id, uniqueness: { scope: [:to_type] }, 
  if: -> { to_type.present? && to_id.present? }

  def self.ransackable_attributes(auth_object = nil)
    ["route_length", "vertical_allowance", "termination_allowance",
      "start_mark", "end_mark", "created_at", "updated_at"]
  end

  def self.ransackable_associations(auth_object = nil)
    [:tag, :cable_type, :circuit, :from, :to]
  end
end
