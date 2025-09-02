FactoryBot.define do
  factory :light_cct do
    # Required tag association
    tag
    
    # Basic attributes
    light_fitting_type { 'standard' }
    quantity { rand(1..20) }
    
    # Trait to create a new tag with default light circuit settings
    trait :with_tag do
      transient do
        prefix { 'L' }
        project { create(:project) }
        discipline { Discipline.find_or_create_by(code: 'E') { |d| d.name = 'Electrical Engineering' } }
        description { nil }
      end

      after(:build) do |light_cct, evaluator|
        light_cct.tag = build(
          :tag,
          :unique_tag,
          tagable: light_cct,
          prefix: evaluator.prefix,
          project: evaluator.project,
          discipline: evaluator.discipline,
          description: evaluator.description
        )
      end
    end
    
    # Callback to create associated demand if needed
    after(:build) do |light_cct, evaluator|
      # Create a default demand if one isn't provided
      if light_cct.demand.nil?
        light_cct.build_demand(
          demandable: light_cct,
          basis: :power_pf,
          supply: 230.0,
          config: :one,
          power: 100.0, # Default to 100W per fitting
          power_factor: 0.9,
          duty: 1.0
        )
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
      after(:build) do |light_cct, evaluator|
        light_cct.build_demand(
          demandable: light_cct,
          basis: :power_pf,
          supply: 230.0,
          config: :one,
          power: 50.0, # Lower power for emergency lights
          power_factor: 0.9,
          duty: 0.1 # Typically lower duty cycle for emergency lights
        )
      end
    end
    
    trait :high_bay do
      light_fitting_type { 'high_bay' }
      after(:build) do |light_cct, evaluator|
        light_cct.build_demand(
          demandable: light_cct,
          basis: :power_pf,
          supply: 400.0,
          config: :three,
          power: 400.0, # Higher power for high bay lights
          power_factor: 0.9,
          duty: 1.0
        )
      end
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
