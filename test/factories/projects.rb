FactoryBot.define do
  factory :project do
    sequence(:code) do |n|
      # Generate unique 2-letter codes starting from AA
      first_char = ("A".ord + ((n / 26) % 26)).chr
      second_char = ("A".ord + (n % 26)).chr
      "#{first_char}#{second_char}"
    end
    sequence(:title) { |n| "Project #{n}" }
    description { "A test project" }
    
    trait :with_owner do
      transient do
        owner { create(:user) }
      end
      
      after(:create) do |project, evaluator|
        evaluator.owner.add_role(:owner, project)
      end
    end
    
    trait :with_members do
      transient do
        members_count { 2 }
        role { :member }
      end
      
      after(:create) do |project, evaluator|
        create_list(:user, evaluator.members_count).each do |user|
          user.add_role(evaluator.role, project)
        end
      end
    end
    
    trait :with_tags do
      transient do
        tags_count { 3 }
        discipline { create(:discipline) }
      end
      
      after(:create) do |project, evaluator|
        create_list(:tag, evaluator.tags_count, 
                   project: project, 
                   discipline: evaluator.discipline)
      end
    end
    
    trait :with_cable_tags do
      transient do
        tags_count { 3 }
        discipline { create(:discipline, code: 'C', name: 'Cables') }
      end
      
      after(:create) do |project, evaluator|
        create_list(:tag, evaluator.tags_count, 
                   :with_notes,
                   project: project, 
                   discipline: evaluator.discipline,
                   prefix: 'C',
                   description: 'Cable Tag')
      end
    end
  end
end
