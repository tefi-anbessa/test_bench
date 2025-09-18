FactoryBot.define do
  factory :motor do
    # Basic attributes
    motor_type { 'Induction' }
    frame_size { '100L' }
    ingress_protection { 'IP55' }
    poles { 4 }
    speed_rated { 1500 }
    
    # Association with tag (required)
    association :tag, factory: :tag, strategy: :build
    
    # Trait to create a motor with a properly associated tag
    trait :with_tag do
      after(:build) do |motor, evaluator|
        if motor.tag.nil?
          project = create(:project)
          discipline = create(:discipline, :e)
          motor.tag = create(:tag, :unique_tag,
            project: project,
            discipline: discipline,
            prefix: 'M',
            service: "#{motor.motor_type} Motor #{motor.frame_size} - #{motor.poles}P",
            tagable: motor
          )
        end
      end
    end
    
    # Validation to ensure tag is present
    after(:build) do |motor, evaluator|
      if motor.tag.nil?
        raise ArgumentError, "Motor factory requires a tag. Use `create(:motor, tag: your_tag)` or `create(:motor, :with_tag)`"
      end
    end
  end
end
