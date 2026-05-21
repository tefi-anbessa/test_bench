FactoryBot.define do
  factory :electrical_heater, class: Electrical::Heater do
    # Tag can be passed explicitly, if not tag will be created.
    # If discipline is passed, tag will be created on that discipline.
    # Otherwise, tag will be created on a new project with "Electrical" discipline.
    transient do
      tag { nil }
      discipline { nil }
    end

    # Attributes
    heater_type { "cast_in" }
    application { "annealing_heat_treating" }
    ingress_protection { 11 } 
    sheath_temperature_max { 500.0 } 
    power_density_min { 0.1 } 
    power_density_max { 99.9 } 
    sheath_material { "aluminium" } 
    insulation_material { "ceramic" }
    notes { Faker::Lorem.paragraph(sentence_count: 2) }

    # Create tag association in a single transaction
    after(:build) do |heater, evaluator|
      unless heater.tag
        if evaluator.tag
          # Use provided tag, but ensure it's not already associated
          if evaluator.tag.tagable.present?
            raise "Tag is already associated with another record: #{evaluator.tag.tagable_type}##{evaluator.tag.tagable_id}"
          end
          heater.tag = evaluator.tag
        elsif evaluator.discipline
          heater.tag = create(:tag, :unique_tag, discipline: evaluator.discipline)
        else
          # Create project with auto-created disciplines
          project = create(:project)
          discipline = project.disciplines.find_by(name: heater.class.module_parent_name) ||
               create(:discipline, name: heater.class.module_parent_name, project: project)
          heater.tag = create(:tag, :unique_tag, discipline: discipline)
        end
      end
    end
  end
end
