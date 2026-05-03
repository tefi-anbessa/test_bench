FactoryBot.define do
  factory :electrical_motor, class: 'Electrical::Motor' do
    # Tag can be passed explicitly, if not tag will be created.
    # If discipline is passed, tag will be created on that discipline.
    # Otherwise, tag will be created on a new project with "Electrical" discipline.
    transient do
      tag { nil }
      discipline { nil }
    end
    # Attributes
    motor_type { :induction }
    frame_size { '100' }
    ingress_protection { '55' }
    poles { 4 }
    speed_rated { 1500 }

    # Create tag association in a single transaction
    after(:build) do |motor, evaluator|
      unless motor.tag
        if evaluator.tag
          # Use provided tag, but ensure it's not already associated
          if evaluator.tag.tagable.present?
            raise "Tag is already associated with another record: #{evaluator.tag.tagable_type}##{evaluator.tag.tagable_id}"
          end
          motor.tag = evaluator.tag
        elsif evaluator.discipline
          motor.tag = create(:tag, :unique_tag, discipline: evaluator.discipline)
        else
          # Create project with auto-created disciplines
          project = create(:project)
          discipline = project.disciplines.find_by(name: motor.class.module_parent_name) ||
               create(:discipline, name: motor.class.module_parent_name, project: project)
          motor.tag = create(:tag, :unique_tag, discipline: discipline)
        end
      end
    end
  end
end
