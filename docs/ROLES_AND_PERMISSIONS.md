# Roles and Permissions Guide

## Overview
This document outlines the role-based access control (RBAC) system implemented in the application. 

## Roles
The application RBAC system uses the rolify gem for role management.

### Constraints
The permitted roles are constrained by a constant hash built from `config/constants/role.yml`. Assignment of a role name other than those permitted in the constants set up will result in a validation error.

### Hierarchy

#### System Roles (Global)
1. **App Owner**
   - Full system access
   - Can manage all resources and users
   - Can assign any role to any user

2. **Admin**
   - Nearly full system access
   - Can manage most resources
   - Cannot modify App Owner accounts

#### Project Roles (Resource instance scoped)
1. **Project Owner**
   - Full control over a specific project
   - Can create and revoke project instance roles
   - Can modify project settings and content

2. **Team Member**
   - Can view and contribute to project content
   - Limited access to project settings
   - Cannot manage team members

#### Functional Roles (Global or Resource scoped)
1. **Electrical Designer**
   - Required, in addition to project team member role, for content modifying actions on electrical resources.

2. [TODO- HOLD]**Mechanical Designer**
   - Required, in addition to project team member role, for content modifying actions on mechanical resources.

### Role Assignment

#### New Users
- New users are created without any roles by default
- An administrator must explicitly assign appropriate roles to each new user

#### User Interface
- The user interface for granting and revoking global and resource wide roles is the roles form based on the roles index.
- It is only accessible to admins and app_owner.
- The user interface for instance specific roles is a sub_form on the resource instance edit page, present only if the user has the required permissions to grant or revoke roles on that instance.

## Permissions and Scopes
The application RBAC system uses the pundit gem for permissions and scopes.

### Policies
- Pundit uses policy objects, one for each resource to be managed.
- Policies provide a boolean permission for each action in a resource's controller.
- Policies also provide a scope object which enables restricting the list of resources available to a user.
- By design, pundit policies use the signed in user (current user) and the resource being managed to determine permissions. 
- Policy permission logic will check the current user's assigned roles to determine access to actions on resource. 
- This application has extended pundit to include the current project as a context for permissions. This is used to limit visibility to only include resource instances that belong to the current project, and to ensure that users are assigned to the current project team before allowing actions.
- Permissions are generally managed through the project resource. A user must have a role on a project to perform actions on resources within that project. A functional role may also be required depending on the resource and action.
- Index and show actions are generally available to any user with any role on the current project.
- Content modification actions (new/create and edit/update) are usually available only to users with a role on the current project, and a functional role appropriate to the resource and action.

#### Destroy Action Rules
- The application uses a revision control system for most data.
- Deletion of data is restricted to admins, and only used for database repairs or similar, to preserve the data history.
- Only `app_owner` can destroy projects due to the significant impact of this action.
- **Exception for Roles**: 
 - Although internally treated as a resource, with rolify rules and a pundit policy, the role model is core to the machinery of the RBAC and is not a user available resource.
 - Roles are destroyed when revoked without history tracking.
 - Role destruction permissions are resource-specific.


## PERMISSIONS AND SCOPE FOR ROLE MODEL

- Permissions for the role model are a special case, because they to a large extent control assignment of other permissions.
- User with :app_owner role is effectively a super admin, and can assign any role to any user, access all view and model resources and complete any task. This would typically be somone who has access to console commands, such as a developer or sysadmin. This role should be used with care for security, and limited to a core of trusted systems personnel.
- User with :admin role also can access all view and model resources and complete any task. User with :admin role is typically responsible for most other role assignments, but cannot assign :app_owner and :admin roles.  This role should also be used with care for security.
- User with :project_owner role can assign roles to users, specific to their own project.
- Scope for admin and app_owner roles includes all roles. 
- Scope for other users includes all of their own roles, plus all roles linked to the current project.

### Permission Matrix for Role Model

| Action                         | App Owner | Admin | Project Owner   | Team Member        |
|--------------------------------|-----------|-------|-----------------|--------------------|
| View global and resource roles | ✓         | ✓     | ✓               | ✓                  |
| Grant global :app_owner role   | ✓         | x     | x               | x                  |
| Grant global :admin role       | ✓         | x     | x               | x                  |
| Revoke global :app_owner role  | ✓         | x     | x               | x                  |
| Revoke global :admin role      | ✓         | x     | x               | x                  |
| Grant other global roles       | ✓         | ✓     | x               | x                  |
| Revoke other global roles      | ✓         | ✓     | x               | x                  |
| View resource specific roles   | ✓         | ✓     | ✓               | ✓ (in project team)|
| Grant :project_owner role      | ✓         | ✓     | x               | x                  |
| Revoke :project_owner role     | ✓         | ✓     | x               | x                  |
| Grant other permitted roles    |           |       |                 | x                  |
| on project instance            | ✓         | ✓     | ✓ (own project) | x                  |
| Revoke other permitted roles   |           |       |                 | x                  |
| on project instance            | ✓         | ✓     | ✓ (own project) | x                  |
|--------------------------------|-----------|-------|-----------------|--------------------|

## PERMISSIONS AND SCOPE FOR PROJECT MODEL

- Permissions for the project model are another special case, because they control permissions to most subsidiary resources.
- Only a user with :admin or :app_owner role can create a new project.
- Only a user with :app_owner role can delete a project, because this would result in destruction of all subsidiary data.
- User with :project_owner role can edit the project title, description, and metrics for the project instance where the role is held.
- Scope for the project model includes all projects for which the user has any role. This is used in listing available projects for current project selection

### Permission Matrix for Project Model

| Action                         | App Owner | Admin | Project Owner | Team Member         |
|--------------------------------|-----------|-------|---------------|---------------------|
| View Project                   | ✓         | ✓     | ✓ (own)       | ✓ (in project team) |
| Create Project                 | ✓         | x     | x             | x                   |
| Edit Project                   | ✓         | ✓     | ✓ (own)       | x                   |
| Delete Project                 | ✓         | x     | x             | x                   |
|--------------------------------|-----------|-------|---------------|---------------------|


## PERMISSIONS AND SCOPE FOR TAG MODEL

- Users with any permitted role on the current project can modify content for the tags resource.
- Only a user with :admin role can delete a tag, because this would result in destruction of all associated tag data. [HOLD Dependent on the data history system chosen, it may be that editing tags is replaced by expiring them and replacement with new data.]
- Scope for the tag model includes all tags belonging to the current project.

### Permission Matrix for Tag Model

| Action                         | App Owner | Admin | Project Owner     | Team Member       |
|                                |           |       | (current project) | (current project) |
|--------------------------------|-----------|-------|-------------------|-------------------|
| View Tag                       | ✓         | ✓     | ✓                 | ✓                 |
| Create Tag                     | ✓         | ✓     | ✓                 | ✓                 |
| Edit Tag                       | ✓         | ✓     | ✓                 | ✓                 |
| Delete Tag                     | ✓         | ✓     | x                 | x                 |
|--------------------------------|-----------|-------|-------------------|-------------------|


## PERMISSIONS FOR ELECTRICAL MODELS

- Users with any permitted role on the current project can view the electrical models.
- Users with :electrical_designer functional role can modify content for the electrical resources, provided they also have another permitted role on the current project.
- Only a user with :admin role can delete any electrical model resources, because this would result in destruction of all associated data. [HOLD Dependent on the data history system chosen, it may be that editing is replaced by expiring and replacement with new data.]
- Scope for the electrical models includes all resourcess belonging to the current project.

### Permission Matrix for Electrical Models

| Action                         | App Owner | Admin | Project Owner     | Team Member       | Electrical |
|                                |           |       | (current project) | (current project) | Designer   |
|--------------------------------|-----------|-------|-------------------|-------------------|------------|
| View Cable Type                | ✓         | ✓     | ✓                 | ✓                 | ✓          |
| Create Cable Type              | ✓         | ✓     | x                 | x                 | ✓          |
| Edit Cable Type                | ✓         | ✓     | x                 | x                 | ✓          |
| Delete Cable Type              | ✓         | ✓     | x                 | x                 | x          |
|--------------------------------|-----------|-------|-------------------|-------------------|------------|


## Implementation Guidance

### Synonyms

Rolify provides various synonyms or short cut names for the role methods. The following synonyms are preferred in the implementation:
 - grant is a synonym for add_role 
 - revoke is a synonym for remove_role 
 - is_[:name]? is a synonym for has_role?[:name]

### Assigning and Revoking Roles
Only to be used within the roles controller and test setup:

```ruby
# Make a user a project owner (only App Owner can do this)
user.grant(:project_owner, project)

# Make a user a team member
user.grant(:team_member, project)

# Grant admin privileges (only App Owner can do this)
user.grant(:admin) if current_user.app_owner?

# Revoke a user's project owner role
user.revoke(:project_owner, project)

# Revoke a user's team member role
user.revoke(:team_member, project)

# Revoke admin privileges (only App Owner can do this)
user.revoke(:admin) if current_user.app_owner?
```

### Checking Permissions Using Pundit Methods
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
### Using Scopes

```ruby
# In controllers
@projects = policy_scope(Project)

# In views
@projects.each do |project|
  if policy(project).edit?
    link_to 'Edit', edit_project_path(project)
  end
end
```

## Best Practices

1. Controllers and views should always check permissions.
2. Use pundit scopes for filtering collections.
3. If a policy needs to be modified, first update the plain language requirements and matrix in this document.
4. All pundit policies have an associated policy test. Use TDD and modify the test first, then modify the policy to pass the test.
5. Run tests after any modification to policies.
6. Keep policy methods focused and testable.
7. Carefully document any custom permission logic in this document.
