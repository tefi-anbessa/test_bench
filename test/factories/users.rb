FactoryBot.define do
  factory :user do
    sequence(:name) { |n| "User#{n}" } # Removed space to match name validation
    sequence(:email) { |n| "user#{n}@example.com" }
    password { 'password123' }
    password_confirmation { 'password123' }
    confirmed_at { Time.current }  # Confirmed by default for testing

    # Override the initialize_with to prevent default role assignment
    initialize_with { new(attributes) }
    to_create { |instance| instance.save(validate: false) }

    # Basic traits for testing validations
    trait :with_name do
      name { 'TestUser' } # Removed space to match name validation
    end

    trait :with_email do
      email { 'test@example.com' }
    end

    # Devise-specific traits
    trait :unconfirmed do
      confirmed_at { nil }
      confirmation_sent_at { Time.current }
    end

    trait :locked do
      failed_attempts { User.maximum_attempts + 1 }
      locked_at { Time.current }
      
    trait :admin do
      after(:create) { |user| user.add_role(:admin) }
    end
    end

    # Role-based traits - these should be used with create, not build
    trait :admin do
      after(:create) { |user| user.add_role(:admin) }
    end

    trait :app_owner do
      after(:create) { |user| user.add_role(:app_owner) }
    end

    # Assign team_member role which is a valid project role
    trait :with_default_role do
      after(:create) do |user|
        user.add_role(:team_member, Project.first || create(:project))
      end
    end
  end
end
