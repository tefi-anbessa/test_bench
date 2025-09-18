FactoryBot.define do
  factory :socket_cct do
    # Basic attributes
    socket_type { 'standard' }
    quantity { 1 }
    
    # Association with tag (required)
    association :tag, factory: :tag, strategy: :build
    
    # Trait to create a socket_cct with a properly associated tag
    trait :with_tag do
      after(:build) do |socket_cct, evaluator|
        if socket_cct.tag.nil?
          project = create(:project)
          discipline = create(:discipline, :e)
          socket_cct.tag = create(:tag, 
            project: project,
            discipline: discipline,
            prefix: 'ES',
            serial: rand(1..999),
            service: "#{socket_cct.socket_type.humanize} Sockets",
            tagable: socket_cct
          )
        end
      end
    end
    
    # Validation to ensure tag is present
    after(:build) do |socket_cct, evaluator|
      if socket_cct.tag.nil?
        raise ArgumentError, "SocketCct factory requires a tag. Use `create(:socket_cct, tag: your_tag)` or `create(:socket_cct, :with_tag)`"
      end
    end
  end
end
