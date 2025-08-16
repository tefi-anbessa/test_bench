FactoryBot.define do
  factory :motor do
    # Basic attributes
    motor_type { %w[Induction Synchronous DC].sample }
    frame_size { "#{rand(50..400)}L" }
    ingress_protection { "IP#{rand(23..68)}" }
    poles { [2, 4, 6, 8].sample }
    speed_rated { (500..3600).step(10).to_a.sample }
    
    # Associations
    # The Tagable concern will handle the tag association
    # The Loadable concern will handle the load association
    
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
    
    # Callback to create associated load if needed
    after(:build) do |motor, evaluator|
      # Create a default load if one isn't provided
      if motor.load.nil?
        motor.load = build(:load, loadable: motor)
      end
    end
  end
end
