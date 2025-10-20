FactoryBot.define do
  factory :motor do
    transient do
      # Tag can be passed explicitly or will be auto-created
      tag { nil }

      # Project and discipline can be passed or will use defaults
      project { nil }      # Will create default if not provided
      discipline { nil }   # Will create default if not provided
    end

    # Basic attributes
    motor_type { 'Induction' }
    frame_size { '100L' }
    ingress_protection { 'IP55' }
    poles { 4 }
    speed_rated { 1500 }

    # Validation and tag creation
    after(:build) do |motor, evaluator|
      if evaluator.tag
        # Tag was explicitly provided
        raise "Tag is already associated with another record" if evaluator.tag.tagable.present?
        motor.tag = evaluator.tag
      else
        # Auto-create tag using provided or default project and discipline
        project = evaluator.project || create(:project)
        discipline = evaluator.discipline || create(:discipline, :e)

        motor.tag = create(:tag,
          prefix: 'M',
          project: project,
          discipline: discipline
        )
      end
    end
  end
end
