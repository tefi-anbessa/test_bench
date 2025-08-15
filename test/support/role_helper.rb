module RoleHelper
  # Assigns roles to users created in tests
  # This is now handled by FactoryBot's callbacks in the User factory
  def assign_roles
    # No-op: Roles are now assigned in the User factory
  end
end

# Include this in the test helper for backward compatibility
ActiveSupport::TestCase.include RoleHelper
