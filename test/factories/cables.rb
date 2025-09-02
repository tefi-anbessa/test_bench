# frozen_string_literal: true

FactoryBot.define do
  # Create a tag first, then build/associate the cable with it
  # Usage:
  #   1. Create a tag first: tag = create(:tag, prefix: 'EC', serial: 1001, project: project)
  #   2. Then create cable: cable = create(:cable, tag: tag)
  #
  # Or use the :with_tag trait for a one-liner:
  #   cable = create(:cable, :with_tag, project: project)
  #
  factory :cable do
    transient do
      # Allow passing in an existing tag
      tag { nil }
      # Or specify tag attributes to create one
      prefix { 'EC' }
      sequence(:serial) { |n| n + 1000 }
      project { create(:project) }
      discipline { create(:discipline, code: 'E', name: 'Electrical') }
      description { nil }
      custom_cable_type { nil }
    end

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

    # This callback runs after build but before validation/creation
    after(:build) do |cable, evaluator|
      # Use custom cable type if provided
      if evaluator.custom_cable_type
        cable.cable_type = evaluator.custom_cable_type
      end

      # If tag was passed in, use it (this will raise if tag is already associated)
      if evaluator.tag
        raise "Tag is already associated with another record" if evaluator.tag.tagable.present?
        cable.tag = evaluator.tag
      end
    end

    # Trait to automatically create and associate a tag
    trait :with_tag do
      after(:build) do |cable, evaluator|
        next if evaluator.tag  # Skip if tag was explicitly provided
        
        # Create a new tag for this cable
        tag_attrs = {
          prefix: evaluator.prefix,
          serial: evaluator.serial,
          discipline: evaluator.discipline,
          project: evaluator.project,
          description: evaluator.description
        }.compact
        
        cable.tag = create(:tag, **tag_attrs)
      end
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
