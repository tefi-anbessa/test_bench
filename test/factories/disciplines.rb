# This factory creates all standard discipline instances that will be available in tests
FactoryBot.define do
  factory :discipline do
    # This will create all standard disciplines when included in a test
    initialize_with do
      Discipline.find_or_create_by(code: attributes[:code]) do |d|
        d.name = attributes[:name]
      end
    end
    
    # Default to first discipline if no code/name specified
    code { Discipline::DISCIPLINES.first[:code] }
    name { Discipline::DISCIPLINES.first[:name] }

    # Create traits for each standard discipline
    Discipline::DISCIPLINES.each do |disc|
      trait disc[:code].downcase.to_sym do
        code { disc[:code] }
        name { disc[:name] }
      end
    end
  end
  
  # Create all standard disciplines in an after(:build) hook
  after(:build) do |discipline|
    Discipline::DISCIPLINES.each do |disc|
      Discipline.find_or_create_by(code: disc[:code]) do |d|
        d.name = disc[:name]
      end
    end
  end
end
