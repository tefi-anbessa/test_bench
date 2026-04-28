class Swatch < ApplicationRecord

# Belongs to associatons
  has_many :disciplines
  has_many :projects
  
# Presence validation for required fields.
  validates :name, presence: true, uniqueness: true
  
  # RGB color validation for all color fields (hex format: #RRGGBB)
  validates :bg, :text, :form_bg, :form_field, :card_bg, :card_header_bg, 
            :card_border, :badge_bg, :badge_text, :link_text, :link_hover,
            presence: true,
            format: { with: /\A#[0-9A-Fa-f]{6}\z/ }
  
  def label
    name
  end

  private

  def self.ransackable_attributes(auth_object = nil)
    [:name, :bg, :text, :form_bg, :form_field, :card_bg, :card_header_bg, :card_border, :badge_bg, :badge_text, :link_text, :link_hover, :created_at, :updated_at]
  end

  def self.ransackable_associations(auth_object = nil)
    [ "projects", "disciplines" ]
  end
end