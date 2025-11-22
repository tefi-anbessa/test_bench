FactoryBot.define do
  factory :electrical_socket_cct, class: 'Electrical::SocketCct' do
    transient do
      # Tag can be passed explicitly or will be auto-created
      tag { nil }

      # Project and discipline can be passed or will use defaults
      project { nil }      # Will create default if not provided
      discipline { nil }   # Will create default if not provided
    end

    # Basic attributes
    socket_type { "10A" }
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
        discipline = evaluator.discipline || create(:discipline, :elec, project: project)

        socket_cct.tag = create(:tag,
          prefix: 'ES',
          discipline: discipline
        )
      end
    end
  end
end
