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
    
    # Project roles as per the new hierarchy
    trait :with_owner do
      transient do
        owner { create(:user) }
      end
      
      after(:create) do |project, evaluator|
        evaluator.owner.add_role(:owner, project)
      end
    end
    
    trait :with_creator do
      transient do
        creator { create(:user) }
      end
      
      after(:create) do |project, evaluator|
        evaluator.creator.add_role(:creator, project)
      end
    end
    
    trait :with_editor do
      transient do
        editor { create(:user) }
      end
      
      after(:create) do |project, evaluator|
        evaluator.editor.add_role(:editor, project)
      end
    end
    
    trait :with_checker do
      transient do
        checker { create(:user) }
      end
      
      after(:create) do |project, evaluator|
        evaluator.checker.add_role(:checker, project)
      end
    end
    
    trait :with_approver do
      transient do
        approver { create(:user) }
      end
      
      after(:create) do |project, evaluator|
        evaluator.approver.add_role(:approver, project)
      end
    end
    
    trait :with_viewer do
      transient do
        viewer { create(:user) }
      end
      
      after(:create) do |project, evaluator|
        evaluator.viewer.add_role(:viewer, project)
      end
    end
    
    # Helper trait to create a project with all role types
    trait :with_all_roles do
      after(:create) do |project, _evaluator|
        create(:user) { |u| u.add_role(:owner, project) }
        create(:user) { |u| u.add_role(:creator, project) }
        create(:user) { |u| u.add_role(:editor, project) }
        create(:user) { |u| u.add_role(:checker, project) }
        create(:user) { |u| u.add_role(:approver, project) }
        create(:user) { |u| u.add_role(:viewer, project) }
      end
    end
    
    # Tags
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
    
    trait :with_civil_tags do
      transient do
        tags_count { 3 }
        discipline { create(:discipline, :c) }  # Using standard civil discipline
      end
      
      after(:create) do |project, evaluator|
        create_list(:tag, evaluator.tags_count, 
                   :civil,  # Using civil trait from tag factory
                   project: project, 
                   discipline: evaluator.discipline)
      end
    end
  end
end
