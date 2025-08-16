FactoryBot.define do
  factory :socket_cct do
    # Basic attributes
    socket_type { 'standard' }
    quantity { rand(1..20) }
    
    # Associations
    # The Tagable concern will handle the tag association
    # The Loadable concern will handle the load association
    
    # Callback to create associated load if needed
    after(:build) do |socket_cct, evaluator|
      # Create a default load if one isn't provided
      if socket_cct.load.nil?
        socket_cct.load = build(:load, 
                              loadable: socket_cct,
                              basis: :power_pf,
                              supply: 230.0,
                              config: :one,
                              power: 2000.0,
                              power_factor: 0.9,
                              duty: 0.1)
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
