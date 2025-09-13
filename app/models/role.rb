class Role < ApplicationRecord
  resourcify
  
    # Default scope to sort by resource_type (with nil first), then by resource_id, and finally by name
    # This helps maintain consistent pagination while the exact label-based sort is handled in the controller
    default_scope { 
      order(
        Arel.sql('CASE WHEN resource_type IS NULL THEN 0 ELSE 1 END'), 
        :resource_type,
        :resource_id,
        :name
      ) 
    }
  
  # This sets up the many-to-many relationship with users through the users_roles join table
  has_and_belongs_to_many :users, join_table: :users_roles, class_name: 'User'

  belongs_to :resource,
             polymorphic: true,
             optional: true

  validates :resource_type,
            inclusion: { in: Rolify.resource_types },
            allow_nil: true
            
  # Role validation
  validates :name, 
            presence: { message: :blank },
            uniqueness: { 
              scope: [:resource_type, :resource_id],
              message: :taken
            },
            inclusion: { 
              in: ->(role) { valid_roles_for(role.resource_type) },
              message: :invalid
            }
            
  # Class methods for role queries
  class << self
    # Get valid roles for a resource type
    # @param resource_type [String, Symbol, Class, nil] The resource type, class, or nil for global/functional roles
    # @param _resource_id [Integer, nil] Unused, kept for backward compatibility
    # @return [Array] Array of valid role names for the resource type
    def valid_roles_for(resource_type = nil, _resource_id = nil)
      resource_type = resource_type.name if resource_type.is_a?(Class)
      
      if resource_type.blank?
        # Return global and functional roles when no resource type is specified
        (Array(Constants.roles.global_roles) + Array(Constants.roles.functional_roles)).uniq
      elsif Constants.roles.respond_to?(:resources)
        # Return resource-specific roles
        resource_key = Constants.roles.resources.to_h.keys
                               .find { |k| k.to_s.downcase == resource_type.to_s.downcase }
        resource_key ? Array(Constants.roles.resources[resource_key]) : []
      else
        []
      end
    end

    # Check if a role is valid for a resource type
    # @param role_name [String, Symbol] The role name to check
    # @param resource_type [String, Symbol, Class, nil] The resource type or class
    # @param _resource_id [Integer, nil] Unused, kept for backward compatibility
    # @return [Boolean] Whether the role is valid for the resource type
    def valid_role?(role_name, resource_type = nil, _resource_id = nil)
      role_name = role_name.to_s
      resource_type = resource_type.name if resource_type.is_a?(Class)
      
      if resource_type.present?
        valid_roles_for(resource_type).include?(role_name)
      else
        global_roles.include?(role_name) || functional_roles.include?(role_name)
      end
    end
    
    # Get all global roles
    # @return [Array<String>] Array of global role names
    def global_roles
      Array(Constants.roles.try(:global_roles) || [])
    end
    
    # Get all functional roles
    # @return [Array<String>] Array of functional role names
    def functional_roles
      Array(Constants.roles.try(:functional_roles) || [])
    end
    
    # Get all valid role names across all categories
    # @return [Array<String>] Array of all role names
    def role_names
      (global_roles + functional_roles + all_resource_roles.values.flatten).uniq
    end
    
    # Get all resource types and their roles
    # @return [Hash{Symbol => Array<String>}] Hash mapping resource types to their roles
    def all_resource_roles
      @all_resource_roles ||= 
        if Constants.roles.respond_to?(:resources)
          Constants.roles.resources.to_h.each_with_object({}) do |(type, roles), hash|
            hash[type.to_sym] = Array(roles)
          end
        else
          {}
        end
    end
  end

  def self.ransackable_attributes(auth_object = nil)
    ["name", "id"]
  end

  def self.ransackable_associations(auth_object = nil)
    ["users", "resource"]
  end

  # Get all roles for a specific resource class
  # @param resource_class [Class, String, Symbol] The resource class or type name
  # @return [Array<String>] Array of role names for the resource
  def self.for_resource(resource_class)
    resource_type = resource_class.is_a?(Class) ? resource_class.name : resource_class
    valid_roles_for(resource_type)
  end

  # Get all roles for the current resource type
  # @param klass [Class] The resource class
  # @return [Array<String>] Array of role names for the resource
  def self.for_resource_class(klass)
    valid_roles_for(klass.name)
  end

#  scopify
end
