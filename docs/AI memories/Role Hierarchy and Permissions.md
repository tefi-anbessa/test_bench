# Role Hierarchy and Permissions
This is an AI generated summary, refer to docs/ROLES_AND_PERMISSIONS.md for up to date guidance.

## Global Roles
- The UI for global roles is the roles index page.

### 1. App Owner (Super Admin)
- **Role**: `:app_owner`
- **Permissions**:
  - Full system access
  - Can assign/revoke `:admin` roles
  - Can perform all CRUD operations on all resources
  - Only one user should have this role globally
  - Only role that can destroy projects due to significant impact

### 2. Admin
- **Role**: `:admin`
- **Permissions**:
  - Can perform all CRUD operations on most resources
  - Can manage users (except assigning `:owner` or `:admin` global roles)
  - Can assign/revoke functional roles
  - Can create new users (along with app_owner) [HOLD - Currently managed by Devise, future security improvements may be needed]
  - Cannot destroy projects (only app_owner can do this)
  - Can manage roles within their scope (create/destroy, but not edit - roles are recreated when changed)

## Project Instance Roles
- The UI for project instance roles is a sub-form on the project edit page.
- A project role (including but not limited to `:team_member`) is required to access child resources such as tags and documents.
- The term 'team member' in general discussion refers to any user with any role specifically linked to the project instance, not just the `:team_member` role.
- There should be no resource wide roles for Project.

### Project Owner
- **Role**: `:project_owner`
- **Permissions**:
  - There should be only one user granted this role for each project instance
  - Create, edit and update a project instance and its child resources
  - Can grant or revoke project roles (currently limited to `:team_member` but may be extended in the future)
  - Has full authority over role management within their project (except for project owner role which is managed by admins)
  - Cannot destroy the project itself (only app_owner can do this)

### Team Member
- **Role**: `:team_member`
- **Permissions**:
  - Default read-only access to all of the project instances resources
  - Required for create, edit and update access to child resources such as tags and documents, and other functional roles
  - Cannot manage roles or team members
  - Cannot destroy any resources (except as allowed by specific functional roles)

## Resource-Wide Roles
- The UI for resource wide roles is the roles index page.
- Resource wide roles are based on functional roles.
- A resource wide role gives a user create, edit and update access to the resources associated with the function, provided the user also has a member role for the project instance.

### Electrical Resources
- **Role**: `:electrical_designer`
- **Permissions**:
  - Create, edit and update access to general project resources, as long a project role is also granted:
    - Tags
    - Documents
  - Create, edit and update access to resources in the Electrical module, as long as a project role is also granted:
    - CableTypes
    - Switchboards
    - Motors
    - SocketCcts
    - LightCcts
    - Cables
