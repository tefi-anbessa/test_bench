# Roles and Permissions Guide

## Overview

This document outlines the role-based access control (RBAC) system implemented in the application.

The objective of the RBAC system is to provide a framework with which to control access to resources. A default setup is provided, which should fulfill most use cases. The system is flexible enough to allow projects to modify their own requirements.

Refer to [DEVELOPER_NOTES](DEVELOPER_NOTES.md#application-structure) for an overview of the application structure. The RBAC system is largely built around the project model as the container for all resources. Users are required to select a "current project" to work on. They will only be able to select from projects where they have a role. Once the selection is made, resources will be made available in accordance with their permissions on that project. A cookie is provided (if enabled by the user's browser) to remember the selection between sign in sessions.

The first level of access control is provided by restricting the scope of collections for views to items in the current project.

The second level of access control is provided by restricting users from creating and editing resource content, unless they have been granted the required role for the resource. Required role is the same for create and edit actions in most cases.

The default required role is defined by the resource module's `base.rb` model, from which all its classes inherit. Classes may override the required role in special cases. Projects may override the class required role by defining a required role for a module in the Discipline model, using the `:required_role` attribute. Disciplines are linked to modules by their `:module` attribute in the Discipline model.

The third level of access control is provided by restricting users from actioning workflow steps, unless they have been granted the designated role for the step.

## RBAC Architecture

The application's resources fall into a number of categories for implementation of the RBAC system.

1. System resources.

   High level resources such as the Role model, the User model, and the Project model must define their roles and responsibilities individually. There are a small number of other system wide resources that have their own individual access control, including colour swatches and software source titles.

1. Project resources.

   Resources scoped to projects use a common project resources permissions policy.

1. Discipline resources.

   Resources scoped to disciplines use a common discipline resources permissions policy. Resources may belong to subsidiary resources, but permissions will depend on the parent discipline.

## Roles

The application RBAC system uses the [rolify gem](https://github.com/RolifyCommunity/rolify/wiki/Usage) for role management.

### Constraints

To avoid proliferation of ad hoc roles and rules which may lead to confusion, the RBAC is quite tightly controlled. Role names cannot be assigned by users: the available role names in the application are constrained by a constant hash built from [role.yml](../config/constants/role.yml). Translation of role names and descriptions is provided in `config/locales/core/xx/xx.rolify.yml` where `xx` is the locale code. Assignment of a role name other than those permitted in the constant set up will result in a permissions error. Details are in the implementation section.

### Hierarchy

#### Global Roles

Global roles are provided for system administration purposes. Users with global roles are considered to "have a project role" for all projects. These roles collectively are referred to in this document as global admin roles.

1. **App Owner**
   - Permission for all controller actions, including destroy.
   - Can assign any available role to any user, including :admin and other :app_owner roles.

1. **Admin**
   - Permission for all controller actions, including destroy.
   - Can assign any available role to any user, except :admin, :project_admin, and :app_owner roles.

#### Resource Wide Roles

- The RBAC system caters for resource wide roles, but none have been implemented to date.
- A resource wide role would give a user access to all instances of a resource, e.g. all document source formats or all colour swatches.

#### Project Instance Roles

- Some permissions are managed through the project resource, with content modification actions requiring a designated role scoped to the project instance.
- Project teams should be self managed as far as is practicable. Global admins create a project and assign a user with the :project_manager role, who then assigns the necessary roles for completing the project.
- If a project is large, it may not want to depend on the global admins for record deletion and other system maintenance tasks, so can have a :project_admin role assigned.

1. **Project Manager**
   - The :project_manager role can only be granted by a global admin.
   - A user with :project_manager role has control over the assigned project, and can modify project details and settings.
   - A project manager can grant and revoke other permitted roles to users for the assigned project, with the exception of the :project_manager and :project_admin roles.

1. **Project Administrator**
   - The :project_admin role can only be granted by an :app_owner role.
   - A user with :project_admin role has permission for all controller actions, including destroy, for records belonging to the project.
   - The :project_admin role does not give permission to grant or revoke other roles.

1. **Team Member**
   - A user with :team_member role can view project content and can raise change requests.

#### Discipline Instance Roles

- Disciplines belong to a project, so a role scoped to a discipline is effectively also scoped to the project.
- A discipline role gives access only to content within that discipline.

1. **Functional Roles**
   - The primary functional role is :designer.
   - Additional roles are used for workflow approval: :checker, :approver.
   - The role :custodian is required for catalog type models, e.g. CableTypes.

### Role Assignment

#### New Users

- New users are created without any roles by default.
- A global admin or project manager must explicitly assign appropriate roles to each new user.

#### User Interface

- The user interface for granting and revoking global and resource wide roles is the new roles form, available from the roles index if authorised.
- The form is only accessible to global admins.
- The user interface for project and discipline specific roles is a sub-form on the resource edit page, present only if the user has the required permissions to grant or revoke roles on that project or discipline.

## Permissions and Scopes

The application RBAC system uses the [pundit gem](https://github.com/varvet/pundit) for permissions and scopes.

### Policies

- Pundit uses policy objects, one for each resource to be managed.
- Policies provide a boolean permission for each action in a resource's controller.
- Policies also provide a scope object which enables restricting the list of resource instances available to a user.
- Conventionally, pundit policies use the signed in user (current user) and either the resource class, or the resource instance being managed to determine permissions.
- This application has extended pundit to include the current project as a context for permissions and scopes.
  - Scope is used to limit visibility of records to only include those that belong to the current project.
  - Permissions are checked to ensure that user has the required role scoped to the current project before allowing action.
  - Index and show actions are generally available to a user with any role on the current project.
  - Content modification actions (#new/#create and #edit/#update) are usually available only to users with the required role scoped to the current project.
- This application extends most resource controllers to include the non-standard actions #import and #copy. Policies should always provide a method for every action in the associated controller.
  - The #import action requires a content modification role in the current project.
  - The #copy action requires a content modification role in the current project, where the object will be created, and a show role in the source object, which may be in another project where the user has a role.
- Models that have role assignments attached (Project, Discipline) are delegated by the Roles controller to manage granting and revoking of their instance linked roles. Their policies require the additional `grant_role?` and `revoke_role?` methods.

#### Destroy Action Rules

- The application uses a revision tracking system for most data.
- Deletion of data is restricted to admins, and only used for database repairs or similar, to otherwise preserve the data history.
- Only `app_owner` can destroy projects due to the significant impact of this action.
- **Exception for Roles**:
  - Although internally treated as a resource, with rolify roles and a pundit policy, the Role model itself is integral to the working of the rolify gem, therefore core to the machinery of the RBAC and is not considered a normal user-accessible resource.
  - Roles are destroyed when the last user with the role is revoked, there is no history tracking. This is an internal function of the rolify gem.
  - Role destruction permissions are resource-specific.

#### Required Role

- By default, tagable resource models define their own required role. This is inherited from the module Base class, but may be overridden in individual classes.
- Projects may override the class defined required role by setting the associated discipline's :required_role attribute, which must be a permitted role for the Discipline class. This should be left as nil to use the default, which is :designer for engineering resources.
- Tags and documents are core models. They are nested under discipline in routes, and derive their required role from the discipline.

## Permissions Details

This section lists the reasoning for the RBAC implementation for each of the main elements of the application. A matrix of roles and permissions is provided for each resource or group of resources with similar permissions.

As well as the checks in the matrices, policies also check that the action does not breach the current project boundary. Policies will deny actions that would affect resources outside of that project.

### Terminology

- The terminology used in this document does not necessarily agree exactly with the code implementation. [HOLD make it do so?]
- Because they mostly have the same permissions, global admin roles (:app_owner and :admin) and :project_admin role are grouped together in the matrices under the column "Admin", unless there are permissions differences (such as for the Role model).
- "Team member" is used in the matrices to mean any user with any project role, with the exception of users who may have more specific permissions in other columns. This is not the same as a user with a :team_member role.
- "Accredited user" is used in the matrices to include any user with a required role specific to the action in that row. The same term is used in code to include __any__ user with permission for the action, i.e. including the admin roles.

## Permissions and Scope for Role Model

- Permissions for the role model are a special case, because they to a large extent control assignment of other permissions.
- User with :app_owner role is effectively a super admin, and can grant any role to any user, access all view and model resources and complete any task. This would typically be somone who has access to console commands, such as a developer or sysadmin. This role should be used with care for security, and limited to a core of trusted systems personnel.
- Only a user with :app_owner role can grant other admin roles :app_owner, :admin and :project_admin.
- Users with :admin role can access all views and model resources and complete any task.
- The :admin role does not give permission to grant :app_owner and :admin roles, but does give permission to grant other permitted roles including :project_manager. This role should also be used with care for security.
- User with :project_manager role can grant roles to users, specific to their own project.
- User with :project_admin roles cannot grant roles.
- Scope for admin and app_owner roles includes all roles.
- Scope for other users includes all of their own roles, plus all roles linked to the current project.
- The role policy checks that roles are valid for the resource type when granting roles. This raises forbidden error rather than getting a validation error, which would allow the user to continue. This check is not applied on revoking roles, allowing admins to remove invalid roles that may have occurred.

### Permission Matrix for Role Model

| Action                                   | App Owner | Admin | Project Manager | Project Admin | Team Member |
|------------------------------------------|-----------|-------|-----------------|---------------|-------------|
| View global and resource roles           | ✓         | ✓     | ✓               | ✓             | x           |
| Grant/revoke global :app_owner role      | ✓         | x     | x               | x             | x           |
| Grant/revoke global :admin role          | ✓         | x     | x               | x             | x           |
| Grant/revoke other global, resource roles| ✓         | ✓     | x               | x             | x           |
| View resource specific roles             | ✓         | ✓     | ✓               | ✓             | ✓           |
| Grant/revoke :project_manager role       | ✓         | ✓     | x               | x             | x           |
| Grant/revoke :project_admin role         | ✓         | x     | x               | x             | x           |
| Grant/revoke project instance roles      | ✓         | ✓     | ✓               | x             | x           |
| Grant/revoke discipline instance roles   | ✓         | ✓     | ✓               | x             | x           |
|

## Permissions and Scope for Project Model

The Project model is a "walled garden" in the application. For the most part, users are only working on one project (current_project) at any time. Some roles assigned to users are scoped to a project instance.

- Only a user with :admin or :app_owner role can create a new project.
- Only a user with :app_owner role can delete a project, because this would result in destruction of all subsidiary data history.
- A user with :project_manager or :project_admin role can edit the project title, description, and metrics for the project instance where the role is held.
- Pundit scope for the Project model includes all projects for which the user has any role. This is used in listing available projects for current project selection, and for #copy actions.

### Permission Matrix for Project Model

| Action                         | Global admin | Project admin | Project Manager | Team Member |
|--------------------------------|--------------|---------------|-----------------|-------------|
| View Project                   | ✓            | ✓             | ✓               | ✓           |
| Create Project                 | ✓            | x             | x               | x           |
| Edit Project                   | ✓            | ✓             | ✓               | x           |
| Delete Project                 | ✓            | x             | x               | x           |
|

## Permissions and Scope for Discipline Model

The disciplines model is used to categorize tags, documents, etc. Disciplines belong to a project, which enables all child objects to determine their scope. Disciplines generally correspond to software modules within the application.

- Disciplines are created by the system at project creation, according to the user's selections.
- More disciplines can only be created by admins.
- A user with :project_manager role can edit disciplines for their project.
- Admins have full access to disciplines.
- Scope for the discipline model includes all disciplines for the current project.

### Permission Matrix for Discipline Model

| Action             | Admins | Project Manager |   Team Member  |
|--------------------|--------|-----------------|----------------|
| View Disciplines   | ✓      | ✓               | ✓              |
| Create Disciplines | ✓      | x               | x              |
| Edit Disciplines   | ✓      | ✓               | x              |
| Delete Disciplines | ✓      | x               | x              |
|

## Permissions and Scope for Tag Model

Tags are the building blocks for engineering elements data. Ultimately, most tags will be linked to a tagable resource, but this is not a requirement.

- Tags belong to a discipline, which in turn determines their project association.
- Tags use their discipline association to determine their required role. If this is nil, they will determine the required role from the discipline's module (by name) Base class.
- Tags are shallow nested under discipline in routes, so discipline must be provided for #index, #new and #create actions.
- Admins have full access to tags.
- Only a user with an admin role can delete a tag, because this would result in destruction of all associated tag data history.
- Users with any role on the current project can view tag details.
- Scope for the tag model includes all tags belonging to the current project.

### Permission Matrix for Tag Model

| Action                         | Admins | Accredited User | Team Member |
|--------------------------------|--------|-----------------|-------------|
| View Tag                       | ✓      | ✓               | ✓           |
| Create Tag                     | ✓      | ✓               | x           |
| Edit Tag                       | ✓      | ✓               | x           |
| Delete Tag                     | ✓      | x               | x           |
|

## Permissions for Tagable Models

Tagable models are the database equivalent to datasheets for engineering elements. Each element is linked to a tag. The tag's discipline corresponds to the module containing the tagable model.

- Tagable resources belong to a tag, and the tag's discipline association determines their project association.
- Users can create and modify content for a tagable resource, if they have the required role. Required role can be defined by the parent tag's discipline, but if this is nil it defaults to the resource class required_role.
- Admins have full access to tagable resources.
- Only admin users can delete any tagable model resources, because this would result in destruction of associated data history.
- Users with any role on the current project can view the tagable models.
- Scope for the tagable models includes all resources belonging to the current project. (Tagables are inherently discipline scoped by their module.)

### Permission Matrix for Tagable Models

| Action                         | Admins | Accredited User | Team Member |
|--------------------------------|--------|-----------------|-------------|
| View Resource                  | ✓      | ✓               | ✓           |
| Create Resource                | ✓      | ✓               | x           |
| Edit Resource                  | ✓      | ✓               | x           |
| Delete Resource                | ✓      | x               | x           |
|

## Document Control Models

### Permission for DocTypes Model

The DocTypes model provides a list of available document types for each discipline. The doc_type association of a document determines its workflow.

- DocTypes belong to a discipline, which determines their project association.
- The required role for doc_types is :document_controller scoped either to project or discipline.
- Global admins and project admins have full access to doc_type resources.
- Scope for the doc_type model includes all doc_types belonging to the current project.

### Permission Matrix for DocTypes Model

| Action                         | Admins | Accredited User | Team Member |
|--------------------------------|--------|-----------------|-------------|
| View DocType                   | ✓      | ✓               | ✓           |
| Create DocType                 | ✓      | ✓               | x           |
| Edit DocType                   | ✓      | ✓               | x           |
| Delete DocType                 | ✓      | x               | x           |

### Permission for Document Model

The Document model provides the document register for the project.

- Documents belong to a doc_type, which provides their discipline, and in turn determines their project association.
- Documents use their indirect discipline association to determine their required role. If this is nil, they will determine the required role from the discipline's module (by name) Base class.
- Documents are shallow nested under discipline in routes, so discipline must be provided for #index, #new and #create actions.
- Admins have full access to document resources.
- Only a user with an admin role can delete a document, because this would result in destruction of associated data history.
- Users with any role on the current project can view document details.
- Scope for the document model includes all documents belonging to the current project, but in practice the index view will be scoped to the discipline.

### Permission Matrix for Document Model

| Action                         | Admins | Accredited User | Team Member |
|--------------------------------|--------|-----------------|-------------|
| View Document                  | ✓      | ✓               | ✓           |
| Create Document                | ✓      | ✓               | x           |
| Edit Document                  | ✓      | ✓               | x           |
| Delete Document                | ✓      | x               | x           |

## Permissions for System Resources

System resources are system wide, with no project association of their own.

### Permission for Swatches Model

The Swatches model provides the application's colour theme system - sets of colours associated with disciplines, projects, or the app-wide default. As a system wide list, it is controlled entirely by global admins.

- Swatches have no project association.
- Only global admins (:admin, :app_owner) can create or edit a swatch.
- Only :app_owner can delete a swatch - stricter than most destroy rules elsewhere, which also allow :admin.
- Any signed-in user can view swatches.
- Scope for swatches includes all records.

### Permission Matrix for Swatches Model

| Action                         | App Owner | Admin | Team Member |
|--------------------------------|-----------|-------|-------------|
| View Swatch                    | ✓         | ✓     | ✓           |
| Create Swatch                  | ✓         | ✓     | x           |
| Edit Swatch                    | ✓         | ✓     | x           |
| Delete Swatch                  | ✓         | x     | x           |

### Permission for SourceFormats Model

The SourceFormats model provides a list of available software source formats. This is a system wide list, so is primarily controlled by global admins. However, as it is not critical data, individual projects are allowed to contribute to the list. Any user with a document_controller role can create entries, but not edit or delete (as these actions could affect other projects using the same entries).

- Source formats have no project association.
- The required role for source_formats is document controller scoped to any project.
- Global admins have full access to source_format resources.
- Scope for source_formats includes all records.

### Permission Matrix for SourceFormats Model

| Action                         | Global Admin | Project Admin | Accredited User | Team Member |
|--------------------------------|--------------|---------------|-----------------|-------------|
| View SourceFormat              | ✓            | ✓             | ✓               | ✓           |
| Create SourceFormat            | ✓            | x             | ✓               | x           |
| Edit SourceFormat              | ✓            | x             | x               | x           |
| Delete SourceFormat            | ✓            | x             | x               | x           |

## Permissions for Change Management Models

The ChangeManagement module tracks and manages changes on a project. 

- Requests belong to a project.
- Proposals and orders have a one to one association with the initiating request, which determines their project association.
- Any team member may initiate a change request on a project, there is no required role.
- Only project managers and admins can initiate CPs and COs.
- Users with the lead discipline's required role can edit CPs and COs.
- Admins have full access to all change control resources.
- Scope for all change_management models is the current project.

### Permission Matrix for ChangeManagement Models

| Action                         | Admins | Project Manager | Accredited User | Team Member |
|--------------------------------|--------|-----------------|-----------------|-------------|
| View Request                   | ✓      | ✓               | ✓               | ✓           |
| Create Request                 | ✓      | ✓               | ✓               | ✓           |
| Edit Request                   | ✓      | ✓               | ✓               | ✓           |
| Delete Request                 | ✓      | x               | ✓               | x           |
| View Proposal                  | ✓            | ✓               | ✓               | ✓           |
| Create Proposal                | ✓            | ✓               | ✓               | x           |
| Edit Proposal                  | ✓            | ✓               | ✓               | ✓           |
| Delete Proposal                | ✓            | x               | ✓               | x           |
| View Order                     | ✓            | ✓               | ✓               | ✓           |
| Create Order                   | ✓            | ✓               | ✓               | x           |
| Edit Order                     | ✓            | ✓               | ✓               | x           |
| Delete Order                   | ✓            | ✓               | ✓               | x           |
| 

## Implementation Guidance

- Read the gem documentation for [rolify](https://github.com/RolifyCommunity/rolify) and [pundit](https://github.com/varvet/pundit) to understand them.

### Rolify

- Most resources will reference the existing roles on the Project or Discipline models. Carefully consider the implications of adding roles to any other models, as they won't necessarily respect the project "walled garden" concept.
- To control access to any new resource:
  - add "resourcify" to the model class.
  - add entries in the constants file [role.yml](config/constants/role.yml) to specify the new resource and its allowed roles.
  - add grant_role? and revoke_role? methods to the model's policy, as the role policy delegates these methods.
  - Update all config/locales/core/xx/xx.rolify.yml files to reflect any new or changed role names.
- Methods for listing valid roles of different types, and for checking role validity for a resource are provided in the Role class.

### Pundit

- When adding a new resource using the app's scaffold generator, a new pundit policy and policy test file are automatically created.
- When adding a new resource using the app's tagable generator, no policy is required. Tagables use a single abstracted controller and policy which references the tag policy.
- Pundit policies determine access to controller actions based on the logged in user, the role/s assigned to the user, the resource instance or class, and the current project.
- Note that including the current project in the pundit context is not rails/pundit convention, it is an extension for this application.

### Policy Architecture

The preferred architecture for policies is to use inheritance to push shared logic up into base classes. Individual resources will inherit from those base classes and only implement what's genuinely particular to them.

Note that in this section, "accredited user" refers to users with permissions for content modification actions: #new, #create, #edit, #update.

#### Application Policy

The `ApplicationPolicy` is the base class for all policies. It provides common methods and logic for all policies.

- It implements the mechanics of current project context, making it available to pundit scopes and policies.
- It provides the method user_has_project_role?(project) for both Scope and Policy classes.
- It defaults all controller actions except #destroy as false, as the safe fallback.
- It defines the #destroy action as admin only, as this logic is used repeatedly throughout the RBAC system.

#### System Resources

System resources by definition don't belong to any other model. They don't follow patterns that can be abstracted. They each have a bespoke policy that inherits only from `ApplicationPolicy`.

- Examples of system resources are the core models Project, User, and Role; and others such as Swatch and SourceFormat shared resources. Use their policies for guidance.
- The scaffold generator can build system resources by using the `--nesting=none` option. The generator writes a template only (stub overrides to fill in), which must be manually completed as part of the build.

#### Project Resources

Project resources belong directly to a project, and cross all the project's disciplines.

- An example of a project resource is `ChangeManagement::Request`.
- The scaffold generator can build project resources by using the `--nesting=project` option.
- Policies inherit from [ProjectResourcePolicy](../app/policies/project_resource_policy.rb).
- A resource's own policy needs to implement `user_is_accredited?(record)` - which role, and on what, counts as accredited for this resource.
- Exception: Discipline is a project resource (`DisciplinePolicy < ProjectResourcePolicy`), but disciplines are auto-created and permissions are a bit different from the usual pattern.

#### Discipline Resources

- An example of a discipline resource is `Tag`.
- The scaffold generator can build discipline resources by using any of the nesting options other than `none` or `project`.
- Policies inherit from [DisciplineResourcePolicy](../app/policies/discipline_resource_policy.rb).
- DisciplineResourcePolicy provides a Scope query that works for models with a direct belongs_to association to a discipline. Models that are indirectly associated with discipline need to override their Scope queries, as the ActiveRecord association won't work here.
- The scaffold generator provides the correct query in the policy, based on the nesting option.
- Exception: DocType and CableType check a `:document_controller`/`:custodian` role instead of the discipline's generic `required_role` - catalog/reference data is deliberately gated by a narrower, dedicated role.
- Exception: tagable resources (Motor, Cable, etc.) have no policy of their own at all - the tagables controller uses `TagPolicy` for all models.

### Synonyms

Rolify provides various synonyms or short cut names for the role methods. The following synonyms are preferred in the implementation:

- grant is a synonym for add_role and is preferred.
- revoke is a synonym for remove_role and is preferred.
- is_name? is a synonym for has_role?[:name]

### Assigning and Revoking Roles

Only to be used within the roles controller and test setup:

```ruby
# Make a user a project owner (only App Owner can do this)
user.grant(:project_manager, project)

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

if policy(Project).new?
  link_to 'New Project', new_project_path
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

1. Use the app generators to ensure:
   1. Controllers always check authentication.
   1. Controllers use the pundit scope to ensure users only access resources on the current project.
   1. Controllers use the scope when setting instance variables from params, to ensure that any param injection is caught.
   1. Controllers will present only disciplines for which the user has permissions when setting up forms.
   1. Policies and policy tests are automatically generated.
1. If a policy needs to be modified, first update the plain language requirements and matrix in this document.
1. All pundit policies have an associated policy test. Use TDD and modify the test first, then modify the policy to pass the test.
1. Run tests after any modification to policies or tests.
1. Keep policy methods focused and testable.
1. Carefully document any custom permission logic in this document.

### Roles Helper

The RolesHelper module provides helper methods for setting up role assignment UI components. It is used by controllers to initialize instance variables needed by the _role_assignment partial.

Methods:

setup_role_assignment(resource = nil) - Main entry point called by controllers. Initializes all instance variables needed for the role assignment form. Handles three cases based on the resource parameter:
Resource instance (e.g., @project) → Shows roles scoped to that specific instance (resource.roles)
Resource class (e.g., Project) → Shows roles scoped to that resource type but not assigned to any instance (Role.where(resource_type: "Project", resource_id: nil))
nil → Shows global roles (Role.where(resource_type: nil))
role_names - Builds grouped options for role dropdowns from Constants.roles. Returns a hash with translated group labels as keys and arrays of [translated_name, role_key] pairs as values. Groups global roles and resource-specific roles separately.
role_names_by_resource_type - Same options as role_names, but keyed by the raw resource_type string (e.g. "Project", "" for global) instead of a translated group label. Used by the resource-type-selector Stimulus controller to repopulate the role_name dropdown client-side when the resource type changes, without a server round-trip.
prepare_roles_for_display(roles_scope) - Flattens a scope of roles into an array of hashes suitable for display tables. Each hash contains: role id, user id, resource type, resource label (or "-" if none), role name, user name, and the role object itself. Sorts by resource type, resource label, and role name.
group_roles(roles) - Takes the flattened roles array and groups it hierarchically: first by resource type, then by resource label, then by role name. Returns a nested hash: { resource_type => { resource_label => { role_name => [user_names] } } }.
grouped_roles_for_resource(resource) - Convenience method for the _role_assignment partial. Combines prepare_roles_for_display and group_roles for a specific resource instance.
Error Handling: The module wraps setup logic in a begin/rescue block to catch exceptions and log them to Rails.logger, ensuring the UI doesn't crash if role data is malformed.

Instance Variables created by setup_role_assignment:


| Variable | Content |
|---|---|
| @resource_types | Array for the resource_type dropdown. Format: [[translated_name, class_name], ...]. First element is ['Global', ''], followed by all Rolify resource types (Project, Discipline, etc.) with humanized names |
| @grouped_role_names | Hash for the role_name dropdown. Keys are translated group labels (e.g., "Global Roles"), values are arrays of [translated_role_name, role_key] pairs |
| @role_names_by_resource_type | Same content as @grouped_role_names, grouped differently - keys are raw resource_type strings (e.g. "Project", "" for global) instead of translated labels |
| @users | User.all - all users available for role assignment |
| @roles | ActiveRecord relation of roles to display. Scope varies: specific instance roles, class-wide roles, or all global roles |
| @grouped_roles | Nested hash for display tables. Structure: {resource_type => {resource_label => {role_name => [user_names]}}} |
| @role | New Role instance with resource pre-set (for the create form). Initialized as Role.new(resource: resource) |
| @resource_type | String class name if resource is an instance (e.g., "Project"), else nil |
| @resource_id | ID if resource is a persisted instance, else nil |
| @role_name | nil (placeholder for form binding) |
| @user_id | nil (placeholder for form binding) |
Used by _role_assignment Partial:

@resource_types, @grouped_role_names, @users → populate dropdown options
@role_names_by_resource_type → passed to the resource-type-selector Stimulus controller as JSON, for client-side role_name repopulation
@role → form model object
@grouped_roles → display existing roles in tables
@role_return_path (set by controller, not helper) → redirect after create/destroy