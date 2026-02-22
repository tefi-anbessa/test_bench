FactoryBot.define do
  factory :swatch, class: Swatch do
    # Attributes
    name { "test" } 
    bg { "#101010" } # Provide default value for required field
    text { "#802020" } # Provide default value for required field
    form_bg { "#100000" } # Provide default value for required field
    form_field { "#001000" } # Provide default value for required field
    card_bg { "#101000" } # Provide default value for required field
    card_header_bg { "#404000" } # Provide default value for required field
    card_border { "#202000" } # Provide default value for required field
    badge_bg { "#f00000" } # Provide default value for required field
    badge_text { "#002000" } # Provide default value for required field
    link_text { "#a00000" } # Provide default value for required field
    link_hover { "#ff0000" } # Provide default value for required field
    
  end
end
