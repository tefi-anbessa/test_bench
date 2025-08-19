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

### Project Roles (Resource-scoped)
1. **Project Owner**
   - Full control over a specific project
   - Can manage team members and their roles
   - Can modify project settings and content

2. **Team Member**
   - Can view and contribute to project content
   - Limited access to project settings
   - Cannot manage team members

### Functional Roles (Global)
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
- Roles can be assigned at both the global and project level
- Use the role management interface in the application to assign roles

## Permission Matrix

| Action                     | App Owner | Admin | Project Owner | Team Member |
|----------------------------|-----------|-------|---------------|-------------|
| Create Project             | ✓         | ✓     | -             | -           |
| Edit Any Project           | ✓         | ✓     | -             | -           |
| Delete Project             | ✓         | ✓     | ✓ (own)       | -           |
| Manage Team Members        | ✓         | ✓     | ✓ (own)       | -           |
| View Project               | ✓         | ✓     | ✓             | ✓           |
| View Team Members          | ✓         | ✓     | ✓             | ✓           |
| View Functional Roles      | ✓         | ✓     | ✓             | ✓           |
| Edit Project Content       | ✓         | ✓     | ✓             | ✓ (config)  |
| Assign Admin Role          | ✓         | -     | -             | -           |

## Managing Roles

### Assigning Roles
```ruby
# Make a user a project owner (only App Owner can do this)
user.add_role(:project_owner, project)

# Make a user a team member
user.add_role(:team_member, project)

# Grant admin privileges (only App Owner can do this)
user.add_role(:admin) if current_user.app_owner?
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
  user.admin? || user.project_owner?(@project)
end
```

## Best Practices
1. Always check permissions in both controllers and views
2. Use Pundit's scopes for filtering collections
3. Keep policy methods focused and testable
4. Document any custom permission logic
