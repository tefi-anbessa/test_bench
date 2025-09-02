FactoryBot.define do
  factory :motor do
    # Require tag to be provided
    tag

    # Trait to create a new tag with default motor settings
    trait :with_tag do
      transient do
        prefix { 'M' }
        project { create(:project) }
        discipline { Discipline.find_or_create_by(code: 'E') { |d| d.name = 'Electrical Engineering' } }
        description { nil }
      end

      after(:build) do |motor, evaluator|
        motor.tag = build(
          :tag,
          :unique_tag,
          tagable: motor,
          prefix: evaluator.prefix,
          project: evaluator.project,
          discipline: evaluator.discipline,
          description: evaluator.description
        )
      end
    end
    
    # Traits for different motor types
    trait :induction do
      motor_type { 'Induction' }
    end
    
    trait :synchronous do
      motor_type { 'Synchronous' }
    end
    
    trait :dc do
      motor_type { 'DC' }
    end
    
    # Traits for common frame sizes
    trait :small_motor do
      frame_size { "#{rand(50..100)}L" }
    end
    
    trait :medium_motor do
      frame_size { "#{rand(101..250)}L" }
    end
    
    trait :large_motor do
      frame_size { "#{rand(251..400)}L" }
    end
    
    # Traits for common ingress protection ratings
    trait :indoor_use do
      ingress_protection { 'IP23' }
    end
    
    trait :outdoor_use do
      ingress_protection { 'IP55' }
    end
    
    trait :harsh_environment do
      ingress_protection { 'IP67' }
    end
    
    # Callback to create associated demand if needed
    after(:build) do |motor, evaluator|
      # Create a default demand if one isn't provided
      if motor.demand.nil?
        motor.build_demand(
          demandable: motor,
          basis: :power_pf,
          supply: 400.0,
          config: :three_4c,
          power: 75000.0,
          power_factor: 0.85,
          duty: 1.0
        )
      end
    end
  end
end
