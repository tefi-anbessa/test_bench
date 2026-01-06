FactoryBot.define do
  factory :electrical_light_cct, class: 'Electrical::LightCct' do
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
        # Create new tag with default discipline in same transaction
        discipline = Discipline.find_or_create_by(code: light_cct.class.discipline_code)
        light_cct.tag = create(:tag, :unique_tag, discipline: discipline)
      end
    end
  end
end
