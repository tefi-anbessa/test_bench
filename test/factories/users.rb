FactoryBot.define do
  factory :user do
    sequence(:name) { |n| "user#{n}" }
    sequence(:email) { |n| "user#{n}@example.com" }
    password { 'password123' }  # More secure default password
    password_confirmation { 'password123' }
    confirmed_at { Time.current }
    
    after(:create) do |user|
      user.add_role(:default) unless user.has_role?(:admin) || user.has_role?(:default)
    end
    
    trait :unconfirmed do
      confirmed_at { nil }
      confirmation_sent_at { Time.current }
    end
    
    trait :locked do
      failed_attempts { User.maximum_attempts + 1 }
      locked_at { Time.current }
    end
    
    trait :admin do
      after(:create) { |user| user.add_role(:admin) }
    end
    
    trait :with_roles do
      transient do
        roles_count { 2 }
      end
      
      after(:create) do |user, evaluator|
        create_list(:role, evaluator.roles_count, users: [user])
      end
    end
    
    trait :with_project do
      transient do
        project { create(:project) }
        role { :member }
      end
      
      after(:create) do |user, evaluator|
        user.add_role(evaluator.role, evaluator.project)
      end
    end
    
    trait :with_role do
      transient do
        role { :default }
        resource { nil }
      end
      
      after(:create) do |user, evaluator|
        user.add_role(evaluator.role, evaluator.resource)
      end
    end
  end
end
