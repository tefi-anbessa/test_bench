FactoryBot.define do
  factory :discipline do
    # Use the first discipline from the constant as default
    code { Discipline::DISCIPLINES.first[:code] }
    name { Discipline::DISCIPLINES.first[:name] }
    
    trait :with_tags do
      transient do
        tags_count { 3 }
        project { create(:project) }
      end
      
      after(:create) do |discipline, evaluator|
        create_list(:tag, evaluator.tags_count, 
                   discipline: discipline, 
                   project: evaluator.project)
      end
    end
    
    # Create a trait for each standard discipline
    Discipline::DISCIPLINES.each do |disc|
      trait disc[:code].downcase.to_sym do
        code { disc[:code] }
        name { disc[:name] }
      end
    end
    
    # Alias for common disciplines that might be referenced in tests
    trait :cables do
      code { 'C' }
      name { 'Civil Engineering' }
    end
    
    trait :electrical do
      code { 'E' }
      name { 'Electrical Engineering' }
    end
    
    trait :mechanical do
      code { 'M' }
      name { 'Mechanical Engineering' }
    end
  end
end
