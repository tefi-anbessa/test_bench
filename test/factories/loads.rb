FactoryBot.define do
  factory :load do
    # Required attributes with valid enum values
    sequence(:supply) { |n| [220.0, 240.0, 400.0, 415.0, 690.0, 1000.0].sample }
    config { Load.configs.keys.sample }
    basis { Load.bases.keys.sample }
    
    # Default loadable association (can be overridden in tests)
    loadable { association :light_cct }
    
    # Default attributes
    sequence(:duty) { |n| rand(0.1..1.0).round(1) }
    sequence(:basis_notes) { |n| "Test basis notes #{n}" }
    
    # Set default values based on basis
    after(:build) do |load, evaluator|
      case load.basis
      when 'power_pf'
        load.power ||= rand(100..5000).to_f
        load.power_factor ||= rand(0.7..0.95).round(2)
      when 'vector_pf'
        load.vector ||= rand(1000..10000).to_f
        load.power_factor ||= rand(0.7..0.95).round(2)
      when 'current_pf'
        load.current ||= rand(1..50).to_f
        load.power_factor ||= rand(0.7..0.95).round(2)
      when 'current_power'
        load.current ||= rand(1..50).to_f
        load.power ||= rand(100..5000).to_f
      when 'summation'
        # No specific attributes needed for summation basis
      end
    end

    trait :with_circuit do
      association :circuit, factory: :circuit
    end

    # Basis-specific traits
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
      current { nil }
      power { nil }
      power_factor { nil }
      vector { nil }
    end

    trait :invalid do
      basis { nil }
      config { nil }
    end
  end
end
