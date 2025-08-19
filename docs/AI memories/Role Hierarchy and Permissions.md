# Role Hierarchy and Permissions

## Global Roles
- The UI for global roles is the roles index page.

### 1. Owner (Super Admin)
- **Role**: `:app_owner`
- **Permissions**:
  - Full system access
  - Can assign/revoke `:admin` roles
  - Can perform all CRUD operations on all resources
  - Only one user should have this role globally

### 2. Admin
- **Role**: `:admin`
- **Permissions**:
  - Can perform all CRUD operations on all resources
  - Can manage users (except assigning `:owner` global role)
  - Can assign/revoke functional roles
  - Unless otherwise specified, only admin or app_owner can perform delete operations

## Project Instance Roles
- The UI for project instance roles is a sub-form on the project show page.
- A ':team_member' role on the project instance is required to access child resources such as tags and documents.
- There should be no resource wide roles for Project.

### Project Owner
- **Role**: `:project_owner`
- **Permissions**:
  - There should be only one user granted this role for each project instance
  - Create, edit and update a project instance and its child resources
  - Can assign/revoke `:team_member` roles

### Team Member
- **Role**: `:team_member`
- **Permissions**:
  - Default read-only access to all of the project instances resources
  - Required for create, edit and update access to child resources such as tags and documents, and other functional roles.

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
