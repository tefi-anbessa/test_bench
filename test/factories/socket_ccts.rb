FactoryBot.define do
  factory :socket_cct do
    transient do
      # Tag can be passed explicitly or will be auto-created
      tag { nil }

      # Project and discipline can be passed or will use defaults
      project { nil }      # Will create default if not provided
      discipline { nil }   # Will create default if not provided
    end

    # Basic attributes
    socket_type { 'standard' }
    quantity { 1 }

    # Validation and tag creation
    after(:build) do |socket_cct, evaluator|
      if evaluator.tag
        # Tag was explicitly provided
        raise "Tag is already associated with another record" if evaluator.tag.tagable.present?
        socket_cct.tag = evaluator.tag
      else
        # Auto-create tag using provided or default project and discipline
        project = evaluator.project || create(:project)
        discipline = evaluator.discipline || create(:discipline, :e)

        socket_cct.tag = create(:tag,
          prefix: 'ES',
          project: project,
          discipline: discipline
        )
      end
    end
  end
end
