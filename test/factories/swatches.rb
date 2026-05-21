FactoryBot.define do
  factory :swatch, class: Swatch do
    # Set a colour scheme that is legible for system test screenshots.
    name { "test_#{SecureRandom.hex(4)}" } 
    bg { "#F0C0A0" } 
    text { "#401010" } 
    form_bg { "#F0C090" } 
    form_field { "#E0E0E0" } 
    card_bg { "#f0d0E0" } 
    card_header_bg { "#c09080" } 
    card_border { "#202000" } 
    badge_bg { "#f0a000" } 
    badge_text { "#F02000" } 
    link_text { "#4080F0" } 
    link_hover { "#3070e0" } 
    
    trait :app_theme do
      name { 'app_theme' }
    end
  end
end
