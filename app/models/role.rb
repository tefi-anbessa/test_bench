class Role < ApplicationRecord
  # === Mixins ===

  # === Constants ===

  # === Gem macros ===
  resourcify

  # === Attributes ===

  # === Associations ===
  # This sets up the many-to-many relationship with users through the users_roles join table
  has_and_belongs_to_many :users, join_table: :users_roles, class_name: 'User'
  belongs_to :resource, polymorphic: true, optional: true

  # === Scopes ===
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

  # === Validations ===
  validates :resource_type, inclusion: { in: Rolify.resource_types }, allow_nil: true
  # Role validation
  validates :name, 
            presence: { message: :blank },
            uniqueness: { 
              scope: [:resource_type, :resource_id],
              message: :taken
            },
            inclusion: {
              in: ->(role) { valid_roles_for(role.resource_type, role.resource_id) },
              message: :invalid
            }

  # === Callbacks ===

  # === Class methods ===         
  # Class methods for role queries
  class << self
    # Sentinel default for the resource_id param below - lets callers that
    # omit it entirely (wanting "the general list for this resource type",
    # e.g. Discipline#validate_required_role, DisciplinePolicy#grant_role?)
    # get the resource_instance list, while a caller that explicitly passes
    # nil (an actual role with no resource_id, i.e. truly resource-wide -
    # see Role's own :name validation) gets the resource_wide list. Plain
    # nil can't distinguish "omitted" from "explicitly nil" on its own.
    UNSPECIFIED = :unspecified

    # Get valid roles for a resource type, scoped by whether a specific
    # resource instance is involved. A resource_type with no resource_id
    # means a resource-wide role (applies to every instance of the type);
    # see config/constants/role.yml's resource_instance/resource_wide split.
    # @param resource_type [String, Symbol, Class, nil] The resource type, class, or nil for global roles
    # @param resource_id [Integer, nil, UNSPECIFIED] Explicit nil means resource-wide; omitted means resource_instance
    # @return [Array] Array of valid role names for the resource type
    def valid_roles_for(resource_type = nil, resource_id = UNSPECIFIED)
      resource_type = resource_type.name if resource_type.is_a?(Class)

      if resource_type.blank?
        # Return global roles when no resource type is specified
        Array(Constants.roles.global_roles)
      elsif Constants.roles.respond_to?(:resources)
        # Return resource-specific roles
        resource_key = Constants.roles.resources.to_h.keys
                               .find { |k| k.to_s.downcase == resource_type.to_s.downcase }
        return [] unless resource_key
        scoped = Constants.roles.resources[resource_key]
        Array(resource_id.nil? ? scoped[:resource_wide] : scoped[:resource_instance])
      else
        []
      end
    end

    # Check if a role is valid for a resource type
    # @param role_name [String, Symbol] The role name to check
    # @param resource_type [String, Symbol, Class, nil] The resource type or class
    # @param resource_id [Integer, nil, UNSPECIFIED] Explicit nil means resource-wide; omitted means resource_instance
    # @return [Boolean] Whether the role is valid for the resource type
    def valid_role?(role_name, resource_type = nil, resource_id = UNSPECIFIED)
      role_name = role_name.to_s
      resource_type = resource_type.name if resource_type.is_a?(Class)

      if resource_type.present?
        valid_roles_for(resource_type, resource_id).include?(role_name)
      else
        global_roles.include?(role_name)
      end
    end
    
    # Get all global roles
    # @return [Array<String>] Array of global role names
    def global_roles
      Array(Constants.roles.try(:global_roles) || [])
    end
    
    # Get all valid role names across all categories
    # @return [Array<String>] Array of all role names
    def role_names
      (global_roles + all_resource_roles.values.flatten).uniq
    end
    
    # Get all resource types and their roles, flattening resource_instance
    # and resource_wide into one list per type - callers of this method
    # want "every role name that could apply to this resource type" without
    # caring which scope it's valid under.
    # @return [Hash{Symbol => Array<String>}] Hash mapping resource types to their roles
    def all_resource_roles
      @all_resource_roles ||=
        if Constants.roles.respond_to?(:resources)
          Constants.roles.resources.to_h.each_with_object({}) do |(type, scoped), hash|
            hash[type.to_sym] = (Array(scoped[:resource_instance]) + Array(scoped[:resource_wide])).uniq
          end
        else
          {}
        end
    end
  end

  # === Public methods ===

  # ransackable_attributes/ransackable_associations must stay public class
  # methods - Ransack calls them from outside this class.
  def self.ransackable_attributes(auth_object = nil)
    ["name", "id"]
  end

  def self.ransackable_associations(auth_object = nil)
    ["users", "resource"]
  end
end
