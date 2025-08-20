# frozen_string_literal: true

FactoryBot.define do
  factory :circuit do
    # Required associations
    switchboard
    
    # Required attributes
    sequence(:serial) { |n| ((n - 1) % 36) + 1 }  # Ensure serial is between 1-36 and starts from 1
    
    # Optional attributes with defaults
    phase { 'L1' }  # Using string value from enum
    device { 'MCB' }  # Using string value from enum
    poles { 1 }
    curve { 'B' }   # Using string value from enum
    rating { 16.0 }  # Amps
    elcb { 'None' }    # Using string value from enum
    contactor { false }
    notes { nil }
    
    # Traits for different types of circuits
    trait :single_phase do
      phase { 0 }  # L1
      poles { 1 }
    end
    
    trait :three_phase do
      phase { 'ALL' }  # For three-phase circuits
      poles { 3 }
    end
    
    trait :with_contactor do
      contactor { true }
    end
    
    trait :with_elcb do
      elcb { '30mA' }  # 30mA
    end
    
    trait :with_notes do
      notes { 'Test circuit notes' }
    end
    
    # Factory to create a circuit with a demand
    trait :with_demand do
      after(:create) do |circuit|
        create(:demand, circuit: circuit)
      end
    end
    
    # Factory to create a circuit with a cable
    trait :with_cable do
      after(:create) do |circuit|
        create(:cable, circuit: circuit)
      end
    end
  end
end
