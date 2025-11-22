# frozen_string_literal: true

FactoryBot.define do
  factory :electrical_circuit, class: 'Electrical::Circuit' do
    transient do
      # Switchboard can be passed explicitly or will be auto-created
      electrical_switchboard { nil }

      # Project and discipline can be passed or will use defaults
      project { nil }      # Will create default if not provided
      discipline { nil }   # Will create default if not provided
    end

    # Require switchboard to be passed in explicitly (or will be auto-created)
    # electrical_switchboard - must be provided

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

    # This callback runs after build but before validation/creation
    after(:build) do |electrical_circuit, evaluator|
      if evaluator.electrical_switchboard
        # Switchboard was explicitly provided
        electrical_circuit.electrical_switchboard = evaluator.electrical_switchboard
      else
        # Auto-create switchboard using provided or default project
        project = evaluator.project || create(:project)
        switchboard_tag = create(:tag, prefix: 'EX', project: project, discipline: create(:discipline, :elec))
        electrical_circuit.electrical_switchboard = create(:electrical_switchboard, tag: switchboard_tag)
      end
    end

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

    # Factory to create a circuit with a cable
    trait :with_cable do
      after(:create) do |electrical_circuit, evaluator|
        # Use circuit's switchboard project for the cable
        cable_project = electrical_circuit.electrical_switchboard.tag&.project || create(:project)
        cable_discipline = electrical_circuit.electrical_switchboard.tag&.discipline || create(:discipline, :elec)
        create(:electrical_cable, from: electrical_circuit, project: cable_project, discipline: cable_discipline)
      end
    end
  end
end
