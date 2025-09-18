FactoryBot.define do
  factory :discipline do
    code { 'E' }  # Default to Electrical Engineering
    name { 'Electrical Engineering' }

    # KISS: Reuse existing record by code to avoid uniqueness violations in tests
    initialize_with do
      Discipline.find_or_create_by(code: code) do |d|
        d.name = name
      end
    end

    # Create traits for each standard discipline
    Discipline::DISCIPLINES.each do |disc|
      trait disc[:code].downcase.to_sym do
        code { disc[:code] }
        name { disc[:name] }
      end
    end
  end

  # Trait to create all standard disciplines
  trait :with_all_standard do
    after(:create) do |_discipline, _evaluator|
      # Create all standard disciplines if they don't exist
      Discipline::DISCIPLINES.each do |disc|
        Discipline.find_or_create_by(code: disc[:code]) do |d|
          d.name = disc[:name]
        end
      end
    end
  end
end
