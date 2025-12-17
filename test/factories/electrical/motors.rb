FactoryBot.define do
  factory :electrical_motor, class: 'Electrical::Motor' do
    # Tag can be passed explicitly or will be auto-created
    transient do
      tag { nil }
    end
    # Basic attributes
    motor_type { :induction }
    frame_size { '100' }
    ingress_protection { '55' }
    poles { 4 }
    speed_rated { 1500 }
    
    after(:build) do |model, evaluator|
      if evaluator.tag
        raise "Tag is already associated with another record" if evaluator.tag.tagable.present?
        model.tag = evaluator.tag
      else
        discipline = Discipline.find_or_create_by(code: model.class.discipline_code)
        model.tag = create(:tag, :unique_tag, discipline: discipline)
      end
    end
  end
end
