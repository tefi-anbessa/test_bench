FactoryBot.define do
  factory :electrical_light_cct, class: 'Electrical::LightCct' do
    # Tag can be passed explicitly, if not tag will be created.
    # If discipline is passed, tag will be created on that discipline.
    # Otherwise, tag will be created on a new project with "Electrical" discipline.
    transient do
      tag { nil }
      discipline { nil }
    end
    # Attributes
    light_fitting_type { :general }
    quantity { 1 }

    # Create tag association in a single transaction
    before(:create) do |light_cct, evaluator|
      if evaluator.tag
        # Use provided tag, but ensure it's not already associated
        if evaluator.tag.tagable.present?
          raise "Tag is already associated with another record: #{evaluator.tag.tagable_type}##{evaluator.tag.tagable_id}"
        end
        light_cct.tag = evaluator.tag
      else
        # Create new tag with proper discipline in same transaction
        if evaluator.discipline
          # Create tag on the provided discipline
          light_cct.tag = create(:tag, :unique_tag, discipline: evaluator.discipline)
        else
          # Create project with auto-created disciplines
          project = create(:project)
          discipline = project.disciplines.find_by(name: light_cct.class.module_parent_name) ||
               create(:discipline, name: light_cct.class.module_parent_name, project: project)
          light_cct.tag = create(:tag, :unique_tag, discipline: discipline)
        end
      end
    end
  end
end
