FactoryBot.define do
  factory :demand, class: 'Demand' do
    # Demandable must be provided
    demandable factory: :light_cct  # Default to light_cct for backward compatibility
    
    # Basic demand attributes
    basis { 'power_pf' }
    supply { 240.0 }
    config { 'three_3c' }  # Using valid enum value
    power { 1000.0 }
    power_factor { 0.9 }
    duty { 1.0 }
    
    # Define basis-specific traits
    trait :power_pf_basis do
      basis { 'power_pf' }
      power { rand(100..5000).to_f }
      power_factor { rand(0.7..0.95).round(2) }
    end
    
    trait :vector_pf_basis do
      basis { 'vector_pf' }
      vector { rand(1000..10000).to_f }
      power_factor { rand(0.7..0.95).round(2) }
    end
    
    trait :current_pf_basis do
      basis { 'current_pf' }
      current { rand(1..50).to_f }
      power_factor { rand(0.7..0.95).round(2) }
    end
    
    trait :current_power_basis do
      basis { 'current_power' }
      current { rand(1..50).to_f }
      power { rand(100..5000).to_f }
    end
    
    trait :summation_basis do
      basis { 'summation' }
    end
  end
end
