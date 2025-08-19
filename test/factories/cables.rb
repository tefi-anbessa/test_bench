# frozen_string_literal: true

FactoryBot.define do
  factory :cable do
    # Required attributes
    cable_type { 
      create(:cable_type, :pvc_flat_twin_earth, 
        description: "Test Cable Type #{SecureRandom.hex(4)}",
        csa: 1.0 + (SecureRandom.random_number(100) * 0.1)  # Random CSA to ensure uniqueness
      ) 
    }
    
    # Optional attributes
    route_length { nil }  # meters
    vertical_allowance { nil }  # meters
    termination_allowance { nil }  # meters per end
    start_mark { nil }
    end_mark { nil }
    
    # Create a cable by building it through a tag
    transient do
      prefix { 'EC' }  # Default prefix for cable tags
      sequence(:serial) { |n| n + 1000 }  # Start from 1001
      project { create(:project) }
      discipline { create(:discipline, code: 'E', name: 'Electrical') }
      description { nil }
      custom_cable_type { nil }
    end
    
    # This creates a tag with the cable as its tagable
    after(:build) do |cable, evaluator|
      # Use custom cable type if provided, otherwise generate a unique one
      if evaluator.custom_cable_type
        cable.cable_type = evaluator.custom_cable_type
      end
      
      discipline = evaluator.discipline
      discipline ||= Discipline.find_or_create_by(code: 'E', name: 'Electrical')
      
      tag_attributes = {
        tagable: cable,
        prefix: evaluator.prefix,
        serial: evaluator.serial,
        discipline: discipline,
        project: evaluator.project
      }
      
      tag_attributes[:description] = evaluator.description if evaluator.description
      
      cable.tag ||= build(:tag, **tag_attributes)
    end
    
    # Trait for creating a cable with a circuit
#    trait :with_circuit do
#      association :circuit, factory: :circuit
      
#      after(:build) do |cable|
#        # Set the project from the circuit's switchboard if not already set
#        if cable.circuit&.switchboard && !cable.tag&.project
#          cable.tag.project = cable.circuit.switchboard.project
#        end
#      end
#    end
  end
end
