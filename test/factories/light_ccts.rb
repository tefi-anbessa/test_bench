FactoryBot.define do
  factory :light_cct do
    # Basic attributes
    light_fitting_type { 'standard' }
    quantity { rand(1..20) }
    
    # Associations
    # The Tagable concern will handle the tag association
    # The Loadable concern will handle the load association
    
    # Callback to create associated load if needed
    after(:build) do |light_cct, evaluator|
      # Create a default load if one isn't provided
      if light_cct.load.nil?
        light_cct.load = build(:load, 
                             loadable: light_cct,
                             basis: :power_pf,
                             supply: 230.0,
                             config: :one,
                             power: 100.0, # Default to 100W per fitting
                             power_factor: 0.9,
                             duty: 0.1)
      end
    end
    
    # Basic traits for light fitting types
    trait :standard do
      light_fitting_type { 'standard' }
      quantity { 4 } # Common quantity
    end
    
    trait :emergency do
      light_fitting_type { 'emergency' }
      quantity { 1 } # Typically one per room
    end
    
    # Create with a tag
    trait :with_tag do
      after(:build) do |light_cct, evaluator|
        light_cct.tag ||= build(:tag, 
                              tagable: light_cct,
                              prefix: 'EL',
                              description: "#{light_cct.light_fitting_type.humanize} Lights")
      end
    end
  end
end
