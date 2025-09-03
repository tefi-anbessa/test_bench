FactoryBot.define do
  factory :light_cct do
    # Basic attributes
    light_fitting_type { 'standard' }
    quantity { 1 }
    
    # Association with tag (required)
    association :tag, factory: :tag, strategy: :build
    
    # Trait to create a light_cct with a properly associated tag
    trait :with_tag do
      after(:build) do |light_cct, evaluator|
        if light_cct.tag.nil?
          project = create(:project)
          discipline = create_or_find_by(code: 'E')
          light_cct.tag = create(:tag, :unique_tag,
            project: project,
            discipline: discipline,
            prefix: 'EL',
            description: "Test Light Cct",
            tagable: light_cct
          )
        end
      end
    end
    
    # Validation to ensure tag is present
    after(:build) do |light_cct, evaluator|
      if light_cct.tag.nil?
        raise ArgumentError, "LightCct factory requires a tag. Use `create(:light_cct, tag: your_tag)` or `create(:light_cct, :with_tag)`"
      end
    end
  end
end
