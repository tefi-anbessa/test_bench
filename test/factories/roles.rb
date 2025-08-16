# Define global roles constant for use in tests
module RoleConstants
  GLOBAL_ROLES = %w[owner admin].freeze
  PROJECT_ROLES = %w[project_owner creator editor checker approver viewer].freeze
end

FactoryBot.define do
  factory :role do
    # Default to a global role
    sequence(:name) { |n| "role_#{n}" }
    
    # Traits for global roles
    trait :owner do
      name { 'owner' }
    end
    
    trait :admin do
      name { 'admin' }
    end
    
    # Traits for project-level roles
    trait :project_owner do
      name { 'project_owner' }
      resource_type { 'Project' }
      resource_id { create(:project).id }
    end
    
    trait :creator do
      name { 'creator' }
    end
    
    trait :editor do
      name { 'editor' }
    end
    
    trait :checker do
      name { 'checker' }
    end
    
    trait :approver do
      name { 'approver' }
    end
    
    trait :viewer do
      name { 'viewer' }
    end
    
    # Factory for resource-specific roles
    factory :resource_role do
      transient do
        resource_type { 'Project' } # Default resource type
        resource { nil }            # Allow passing a resource directly
      end
      
      after(:build) do |role, evaluator|
        if evaluator.resource
          role.resource = evaluator.resource
        else
          role.resource_type = evaluator.resource_type
          role.resource_id = create(evaluator.resource_type.underscore).id
        end
      end
    end
    
    # Factory for user assignment
    factory :user_role do
      transient do
        user { create(:user) }
      end
      
      after(:create) do |role, evaluator|
        evaluator.user.add_role(role.name.to_sym, role.resource)
      end
    end
  end
end
