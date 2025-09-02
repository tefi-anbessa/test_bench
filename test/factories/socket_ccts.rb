FactoryBot.define do
  factory :socket_cct do
    # Required tag association
    tag
    
    # Basic attributes
    socket_type { 'standard' }
    quantity { rand(1..20) }
    
    # Trait to create a new tag with default socket circuit settings
    trait :with_tag do
      transient do
        prefix { 'S' }
        project { create(:project) }
        discipline { Discipline.find_or_create_by(code: 'E') { |d| d.name = 'Electrical Engineering' } }
        description { nil }
      end

      after(:build) do |socket_cct, evaluator|
        socket_cct.tag = build(
          :tag,
          :unique_tag,
          tagable: socket_cct,
          prefix: evaluator.prefix,
          project: evaluator.project,
          discipline: evaluator.discipline,
          description: evaluator.description
        )
      end
    end
    
    # Callback to create associated demand if needed
    after(:build) do |socket_cct, evaluator|
      # Create a default demand if one isn't provided
      if socket_cct.demand.nil?
        socket_cct.build_demand(
          demandable: socket_cct,
          basis: :power_pf,
          supply: 230.0,
          config: :one,
          power: 2000.0,
          power_factor: 0.9,
          duty: 0.1
        )
      end
    end
    
    # Basic traits for socket types
    trait :standard do
      socket_type { 'standard' }
      quantity { 4 } # Common quantity
    end
    
    trait :specialized do
      socket_type { 'specialized' }
      quantity { 2 } # For specialized equipment
    end
    
    trait :power_tool do
      socket_type { 'power_tool' }
      quantity { 1 } # Single heavy-duty socket
    end
    
    # Create with a tag
    trait :with_tag do
      after(:build) do |socket_cct, evaluator|
        socket_cct.tag ||= build(:tag, 
                               tagable: socket_cct,
                               prefix: 'ES',
                               description: "#{socket_cct.socket_type.humanize} Sockets")
      end
    end
  end
end
