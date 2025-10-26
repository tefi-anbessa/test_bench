FactoryBot.define do
  factory :light_cct do
    transient do
      # Tag can be passed explicitly or will be auto-created
      tag { nil }

      # Project and discipline can be passed or will use defaults
      project { nil }      # Will create default if not provided
      discipline { nil }   # Will create default if not provided
    end

    # Basic attributes
    light_fitting_type { :general }
    quantity { 1 }

    # Validation and tag creation
    after(:build) do |light_cct, evaluator|
      if evaluator.tag
        # Tag was explicitly provided
        raise "Tag is already associated with another record" if evaluator.tag.tagable.present?
        light_cct.tag = evaluator.tag
      else
        # Auto-create tag using provided or default project and discipline
        project = evaluator.project || create(:project)
        discipline = evaluator.discipline || create(:discipline, :e)

        light_cct.tag = create(:tag,
          prefix: 'EL',
          project: project,
          discipline: discipline
        )
      end
    end
  end
end
