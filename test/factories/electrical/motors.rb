FactoryBot.define do
  factory :electrical_motor, class: 'Electrical::Motor' do
    # Tag can be passed explicitly, otherwise will be auto-created
    transient do
      tag { nil }
    end
    # Attributes
    motor_type { :induction }
    frame_size { '100' }
    ingress_protection { '55' }
    poles { 4 }
    speed_rated { 1500 }

    # Create tag association in a single transaction
    before(:create) do |motor, evaluator|
      if evaluator.tag
        # Use provided tag, but ensure it's not already associated
        if evaluator.tag.tagable.present?
          raise "Tag is already associated with another record: #{evaluator.tag.tagable_type}##{evaluator.tag.tagable_id}"
        end
        motor.tag = evaluator.tag
      else
        # Create new tag with proper discipline in same transaction
        discipline = Discipline.find_or_create_by(code: motor.class.discipline_code)
        motor.tag = create(:tag, :unique_tag, discipline: discipline)
      end
    end
  end
end
