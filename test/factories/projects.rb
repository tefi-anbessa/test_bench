FactoryBot.define do
  factory :project do
    code do
      last_code = Project.order(code: :asc).last&.code || 'AA'
      next_code = last_code.succ
      raise "No more project codes available (reached ZZ)" if next_code > 'ZZ'
      next_code
    end
    sequence(:title) { |n| "Project #{n}" }
    description { "A test project" }
    
    # Project with roles
    trait :with_owner do
      transient do
        owner { create(:user) }
      end
      
      after(:create) do |project, evaluator|
        evaluator.owner.add_role(:owner, project)
      end
    end
    
    # Tags
#    trait :with_tags do
#      transient do
#        tags_count { 3 }
#        discipline { create(:discipline) }
#      end
      
#      after(:create) do |project, evaluator|
#        create_list(:tag, evaluator.tags_count, 
#                   project: project, 
#                   discipline: evaluator.discipline)
#      end
#    end
    
#    trait :with_civil_tags do
#      transient do
#        tags_count { 3 }
#        discipline { create(:discipline, :c) }  # Using standard civil discipline
#      end
      
#      after(:create) do |project, evaluator|
#        create_list(:tag, evaluator.tags_count, 
#                   :civil,  # Using civil trait from tag factory
#                   project: project, 
#                   discipline: evaluator.discipline)
#      end
#    end
  end
end
