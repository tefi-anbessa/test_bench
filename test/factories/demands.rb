FactoryBot.define do
  factory :demand, class: 'Demand' do
    # Default demandable (light_cct) - will be built but not saved
    demandable { build(:light_cct) }
    
    # Basic demand attributes
    basis { 'power_pf' }
    supply { 240.0 }
    config { 'three_3c' }  # Using valid enum value
    power { 1000.0 }
    power_factor { 0.9 }
    duty { 1.0 }
    
    # Define traits for different demandable types
    trait :with_light_cct do
      transient do
        project { create(:project) }
        discipline { create(:discipline, :e) }  # 'E' for Electrical
      end
      
      after(:build) do |demand, evaluator|
        tag = create(:tag, 
          project: evaluator.project,
          discipline: evaluator.discipline,
          prefix: 'LGT',
          serial: rand(1..999)
        )
        
        demand.demandable = create(:light_cct, tag: tag)
      end
    end
    
    trait :with_motor do
      transient do
        project { create(:project) }
        discipline { create(:discipline, :m) }  # 'M' for Mechanical
      end
      
      after(:build) do |demand, evaluator|
        tag = create(:tag, 
          project: evaluator.project,
          discipline: evaluator.discipline,
          prefix: 'MTR',
          serial: rand(1..999)
        )
        
        demand.demandable = create(:motor, 
          project: evaluator.project,
          discipline: evaluator.discipline,
          tag: tag
        )
      end
    end
    
    trait :with_socket_cct do
      transient do
        project { create(:project) }
        discipline { create(:discipline, :e) }
      end
      
      after(:build) do |demand, evaluator|
        tag = create(:tag, 
          project: evaluator.project,
          discipline: evaluator.discipline,
          prefix: 'SOCK',
          serial: rand(1..999)
        )
        
        demand.demandable = create(:socket_cct, tag: tag)
      end
    end
    
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
