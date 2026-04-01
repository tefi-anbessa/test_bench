FactoryBot.define do
  factory :electrical_heater, class: Electrical::Heater do
    # Tag can be passed explicitly, otherwise will be auto-created
    transient do
      tag { nil }
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

    # Create tag association in a single transaction
    before(:create) do |heater, evaluator|
      if evaluator.tag
        # Use provided tag, but ensure it's not already associated
        if evaluator.tag.tagable.present?
          raise "Tag is already associated with another record: #{evaluator.tag.tagable_type}##{evaluator.tag.tagable_id}"
        end
        heater.tag = evaluator.tag
      else
        # Create new tag with proper discipline in the same transaction
        discipline = Discipline.find_by(name: heater.class.discipline) || 
             create(:discipline, name: heater.class.discipline)
        heater.tag = create(:tag, :unique_tag, discipline: discipline)
      end
    end
  end
end
