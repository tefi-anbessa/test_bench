# frozen_string_literal: true

FactoryBot.define do
  factory :switchboard do
    transient do
      # Tag can be passed explicitly or will be auto-created
      tag { nil }

      # Project and discipline can be passed or will use defaults
      project { nil }      # Will create default if not provided
      discipline { nil }   # Will create default if not provided
    end

    # Basic attributes

    # Validation and tag creation
    after(:build) do |switchboard, evaluator|
      if evaluator.tag
        # Tag was explicitly provided
        raise "Tag is already associated with another record" if evaluator.tag.tagable.present?
        switchboard.tag = evaluator.tag
      else
        # Auto-create tag using provided or default project and discipline
        project = evaluator.project || create(:project)
        discipline = evaluator.discipline || create(:discipline, :e)

        switchboard.tag = create(:tag,
          prefix: 'EX',
          project: project,
          discipline: discipline
        )
      end
    end

    trait :with_circuits do
      transient do
        circuits_count { 3 }  # Default to 3 circuits, can be overridden
      end

      after(:create) do |switchboard, evaluator|
        # Create circuits with this switchboard
        evaluator.circuits_count.times do |i|
          create(:circuit, switchboard: switchboard, serial: i + 1)
        end
      end
    end
  end
end
