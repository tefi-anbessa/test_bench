# frozen_string_literal: true

FactoryBot.define do
  factory :switchboard do
    # Basic attributes
    
    # Association with tag (required)
    association :tag, factory: :tag, strategy: :build

    # Trait to create a switchboard with a properly associated tag
    trait :with_tag do
      after(:build) do |switchboard, evaluator|
        if switchboard.tag.nil?
          project = create(:project)
          discipline = Discipline.find_or_create_by(code: 'E')
          switchboard.tag = create(:tag, :unique_tag,
            project: project,
            discipline: discipline,
            prefix: 'SWB',
            description: "Switchboard #{switchboard.voltage}V #{switchboard.current_rating}A",
            tagable: switchboard
          )
        end
      end
    end
    
    # Validation to ensure tag is present
    after(:build) do |switchboard, evaluator|
      if switchboard.tag.nil?
        raise ArgumentError, "Switchboard factory requires a tag. Use `create(:switchboard, tag: your_tag)` or `create(:switchboard, :with_tag)`"
      end
    end
    
    trait :with_circuits do
      transient do
        circuits_count { 3 }  # Default to 3 circuits, can be overridden
      end
      
      after(:create) do |switchboard, evaluator|
        create_list(:circuit, evaluator.circuits_count, switchboard: switchboard)
      end
    end
  end
end
