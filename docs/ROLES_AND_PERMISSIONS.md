# Roles and Permissions Guide

## Overview
This document outlines the role-based access control (RBAC) system implemented in the application. The system uses a combination of Pundit for authorization and Rolify for role management.

## Role Hierarchy

### System Roles (Global)
1. **App Owner**
   - Full system access
   - Can manage all resources and users
   - Can assign any role to any user

2. **Admin**
   - Nearly full system access
   - Can manage most resources
   - Cannot modify App Owner accounts

### Project Roles (Resource instance scoped)
1. **Project Owner**
   - Full control over a specific project
   - Can create and revoke project instance roles
   - Can modify project settings and content

2. **Team Member**
   - Can view and contribute to project content
   - Limited access to project settings
   - Cannot manage team members

### Functional Roles (Global or Resource scoped)
1. **Electrical Designer**
   - Required, in addition to project team member role, for create, edit, update on electrical resources:
      - Cable Types
      - Cables
      - Circuits
      - Demands
      - Switchboards
      - Motors
      - Sockets
      - Lights

2. [TODO- HOLD]**Mechanical Designer**
   - Can view and contribute to mechanical design content
   - Limited access to mechanical design settings
   - Cannot manage mechanical design settings

## Role Assignment

### New Users
- New users are created without any roles by default
- An administrator must explicitly assign appropriate roles to each new user

### User Interface
- The user interface for granting and revoking global and resource wide roles is the roles form based on the roles index.
- It is only accessible to admins and app_owner.
- The user interface for instance specific roles is a sub_form on the resource instance edit page, present only if the user has the required permissions to grant or revoke roles on that instance.

## Permissions

#### General Rules
- Only `:app_owner` and `:admin` roles can create new users [HOLD - at preent creation of users is managed by devise]
- Roles can be created and destroyed but not edited. (The concept of editing is invalid: if a role changes it is a different role.)
- Permissions are generally managed through the project resource. A user must have a role on a project to perform actions on that project. A functional role may also be required depending on the resource and action.

#### Destroy Action Rules
- The project uses a revision control system for most data
- Deletion of data is restricted to admins, and only used for database repairs or similar, to preserve the data history.
- Only `app_owner` can destroy projects due to the significant impact of this action.
- **Exception for Roles**: 
  - Roles are destroyed when revoked without history tracking
  - Project owners can destroy roles within their own projects
  - Role destruction permissions are resource-specific

## Permission Matrix

| Action                     | App Owner | Admin | Project Owner | Team Member |
|----------------------------|-----------|-------|---------------|-------------|
| Create Project             | ✓         | -     | -             | -           |
| Edit Any Project           | ✓         | ✓     | ✓ (own)       | -           |
| Delete Project             | ✓         | -     | -             | -           |
| Manage Team Members        | ✓         | ✓     | ✓ (own)       | -           |
| View Project               | ✓         | ✓     | ✓             | ✓           |
| View Team Members          | ✓         | ✓     | ✓             | ✓           |
| View Functional Roles      | ✓         | ✓     | ✓             | ✓           |
| Edit Project Content       | ✓         | ✓     | ✓             | ✓ (config)  |
| Create Users               | ✓         | ✓     | -             | -           |
| Manage Roles               | ✓         | ✓     | ✓ (own proj)  | -           |
| Delete Roles               | ✓         | ✓     | ✓ (own proj)  | -           |

## Managing Roles

### Assigning and Revoking Roles
```ruby
# Make a user a project owner (only App Owner can do this)
user.grant(:project_owner, project)

# Make a user a team member
user.grant(:team_member, project)

# Grant admin privileges (only App Owner can do this)
user.grant(:admin) if current_user.app_owner?
```

### Revoking Roles
```ruby
# Revoke a user's project owner role
user.revoke(:project_owner, project)

# Revoke a user's team member role
user.revoke(:team_member, project)

# Revoke admin privileges (only App Owner can do this)
user.revoke(:admin) if current_user.app_owner?
```

### Team Management
- Team membership is binary (a user is either a team member or not)
- Only project owners and administrators can modify team membership
- All team members can view the team list and roles
- Functional roles are managed separately from team membership

### Checking Permissions
```ruby
# In controllers
authorize @project

# In views
if policy(@project).edit?
  link_to 'Edit', edit_project_path(@project)
end

# In policies
def edit?
  user.is_app_owner? || user.is_admin? || user.is_project_owner?(@project)
end
```

## Best Practices
1. Always check permissions in both controllers and views
2. Use Pundit's scopes for filtering collections
3. Keep policy methods focused and testable
4. Document any custom permission logic
