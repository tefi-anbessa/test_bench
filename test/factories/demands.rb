FactoryBot.define do
  factory :demand, parent: :load, class: 'Demand' do
    # Inherit all attributes from the :load factory but create a Demand instance
    
    # Set up the demandable association (replaces loadable from the parent)
    demandable { association :light_cct }
    
    # Clear the loadable association from the parent
    loadable { nil }
    
    # Define traits for different demandable types
    trait :with_light_cct do
      demandable { association :light_cct }
    end
    
    trait :with_motor do
      demandable { association :motor }
    end
    
    trait :with_socket_cct do
      demandable { association :socket_cct }
    end
    
    # Define basis-specific traits from the parent
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
