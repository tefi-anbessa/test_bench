# Role System and Constants Integration

## Overview
The application's role system is tightly integrated with the Constants system for role management. For the most up-to-date permission matrix and role definitions, see `ROLES_AND_PERMISSIONS.md` in the docs directory.

## Implementation Details

### 1. Constants Source
- Permitted roles are defined in `config/constants/role.yml`
- The YAML structure includes:
  - `global_roles`
  - `functional_roles`
  - Resource-specific roles under `resources`

### 2. Role Model Integration
- Role model validates against these constants
- Provides class methods:
  - `Role.valid_roles_for(resource_type)` - Get valid roles for a resource
  - `Role.valid_role?(name, resource_type)` - Check if a role is valid
  - `Role.global_roles` - Get all global roles
  - `Role.functional_roles` - Get all functional roles

### 3. Testing
- Roles factory generates traits dynamically from Constants
- Tests should use factory methods rather than hardcoding role names
- When adding new roles, only the YAML file needs updating

## Best Practices
- Always use the constants from `Constants.roles` rather than hardcoding role names
- When adding new roles, update the YAML file and the factory will handle the rest
- Use the provided factory methods for consistent testing
- Refer to `ROLES_AND_PERMISSIONS.md` for the complete permission matrix and constraints
- Leverage the provided helper methods for role validation
