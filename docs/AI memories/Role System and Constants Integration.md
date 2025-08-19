# Role System and Constants Integration

## Overview
The application's role system is tightly integrated with the Constants system for role management.

## Implementation Details

### 1. Constants Source
- Roles are defined in `config/constants/role.yml`
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
- Always use `Constants.roles` instead of hardcoding role names
- Update the YAML file when adding new roles
- Use factory methods for consistent testing
- Leverage the provided helper methods for role validation
