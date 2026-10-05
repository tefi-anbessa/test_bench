FactoryBot.define do
  factory :instrument_pressure_gauge, class: Instrument::PressureGauge do
    # Tag can be passed explicitly, if not tag will be created.
    # If discipline is passed, tag will be created on that discipline.
    # Otherwise, tag will be created on a new project with a matching discipline.
    transient do
      tag { nil }
      discipline { nil }
    end
    # Associations

    # Attributes
    measurement_type { "positive_pressure" }
    pressure_unit { "bar" }
    range_min { 0.0 }
    range_max { 10.0 }
    fluid_phase { "gas" }
    process_fluid { "air" }
    accuracy_class { "grade_1_6" }
    dial_size { "mm100" }
    connection_type { "npt" }
    connection_size { "in_1_2" }
    case_material { "stainless_steel" }
    wetted_material { "ss316" }
    movement_type { "bourdon_tube" }
    liquid_filled { true }
    fill_fluid { "glycerine" }
    ip_rating { "65" }
    safety_pattern { nil }
    accessories { "Snubber: Required" }
    notes { nil }

    # Create tag association in a single transaction
    after(:build) do |pressure_gauge, evaluator|
      unless pressure_gauge.tag
        if evaluator.tag
          # Use provided tag, but ensure it's not already associated
          if evaluator.tag.tagable.present?
            raise "Tag is already associated with another record: #{evaluator.tag.tagable_type}##{evaluator.tag.tagable_id}"
          end
          pressure_gauge.tag = evaluator.tag
        elsif evaluator.discipline
          pressure_gauge.tag = create(:tag, :unique_tag, discipline: evaluator.discipline)
        else
          # Create project with auto-created disciplines
          project = create(:project)
          discipline = project.disciplines.find_by(name: pressure_gauge.class.module_parent_name) ||
               create(:discipline, name: pressure_gauge.class.module_parent_name, project: project)
          pressure_gauge.tag = create(:tag, :unique_tag, discipline: discipline)
        end
      end
    end
  end
end
