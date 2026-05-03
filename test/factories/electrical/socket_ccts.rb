FactoryBot.define do
  factory :electrical_socket_cct, class: 'Electrical::SocketCct' do
    # Tag can be passed explicitly, if not tag will be created.
    # If discipline is passed, tag will be created on that discipline.
    # Otherwise, tag will be created on a new project with "Electrical" discipline.
    transient do
      tag { nil }
      discipline { nil }
    end
    # Attributes
    socket_type { "10A" }
    quantity { 1 }

    # Create tag association in a single transaction
    after(:build) do |socket_cct, evaluator|
      unless socket_cct.tag
        if evaluator.tag
          # Use provided tag, but ensure it's not already associated
          if evaluator.tag.tagable.present?
            raise "Tag is already associated with another record: #{evaluator.tag.tagable_type}##{evaluator.tag.tagable_id}"
          end
          socket_cct.tag = evaluator.tag
        elsif evaluator.discipline
          socket_cct.tag = create(:tag, :unique_tag, discipline: evaluator.discipline)
        else
          # Create project with auto-created disciplines
          project = create(:project)
          discipline = project.disciplines.find_by(name: socket_cct.class.module_parent_name) ||
               create(:discipline, name: socket_cct.class.module_parent_name, project: project)
          socket_cct.tag = create(:tag, :unique_tag, discipline: discipline)
        end
      end
    end
  end
end
