FactoryBot.define do
  factory :swatch, class: Swatch do
    # Set a colour scheme that is legible for system test screenshots.
    name { "test_#{SecureRandom.hex(4)}" } 
    bg { "#F0C0A0" } # Provide default value for required field
    text { "#401010" } # Provide default value for required field
    form_bg { "#F0C090" } # Provide default value for required field
    form_field { "#E0E0E0" } # Provide default value for required field
    card_bg { "#f0d0E0" } # Provide default value for required field
    card_header_bg { "#c09080" } # Provide default value for required field
    card_border { "#202000" } # Provide default value for required field
    badge_bg { "#f0a000" } # Provide default value for required field
    badge_text { "#F02000" } # Provide default value for required field
    link_text { "#4080F0" } # Provide default value for required field
    link_hover { "#3070e0" } # Provide default value for required field
    
  end
end
