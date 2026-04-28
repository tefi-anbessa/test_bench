FactoryBot.define do
  factory :role do
    # Default to a global admin role
    name { 'admin' }
    
    # Generate traits for all roles from constants
    Constants.roles.global_roles.each do |role_name|
      trait role_name.to_sym do
        name { role_name }
      end
    end
    
    # Generate traits for resource-specific roles
    Constants.roles.resources.to_h.each do |resource_type, roles|
      roles.each do |role_name|
        trait "#{resource_type}_#{role_name}".to_sym do
          name { role_name }
          resource_type { resource_type.to_s.classify }
          resource { association resource_type.to_sym }
        end
      end
    end
    
    # Factory for resource-specific roles
    factory :resource_role do
      transient do
        resource_type { 'Project' } # Default resource type
        resource { nil }            # Allow passing a resource directly
      end
      
      # Set default role based on resource type
      name { Constants.roles.resources[resource_type.underscore.to_sym]&.first || 'team_member' }
      
      after(:build) do |role, evaluator|
        if evaluator.resource
          role.resource = evaluator.resource
        else
          role.resource_type = evaluator.resource_type
          role.resource_id = create(evaluator.resource_type.underscore).id
        end
      end
    end
    
    # Factory for user assignment with role
    factory :user_role do
      transient do
        user { create(:user) }
        role_name { nil }  # Allow specifying role name
        resource { nil }   # Optional resource
      end
      
      after(:create) do |role, evaluator|
        role_name = evaluator.role_name || role.name
        evaluator.user.add_role(role_name.to_sym, role.resource)
      end
      
      # Create traits for each role type
      Constants.roles.global_roles.each do |role_name|
        trait role_name.to_sym do
          name { role_name }
          resource { nil }
        end
      end
      
      # Create traits for resource-specific roles
      Constants.roles.resources.to_h.each do |resource_type, roles|
        roles.each do |role_name|
          trait "#{resource_type}_#{role_name}".to_sym do
            name { role_name }
            resource_type { resource_type.to_s.classify }
            resource_id { create(resource_type.to_sym).id }
          end
        end
      end
    end
  end
end
