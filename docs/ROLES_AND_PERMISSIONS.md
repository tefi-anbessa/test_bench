# Roles and Permissions Guide

## Overview

This document outlines the role-based access control (RBAC) system implemented in the application.

The objective of the RBAC system is to provide projects with a framework with which to control access to their resources. A default setup is provided, which should fulfill most use cases. The system is flexible enough to allow projects to modify their own requirements.

The first level of access control is provided by restricting users from creating and editing resource content, unless they have been granted the required role for the resource. Required role is the same for create and edit actions in most cases.

The default required role is defined by the resource module's `base.rb` model, from which all its classes inherit. Classes may override the required role in special cases. Projects may override the class required role by defining a required role for a module in the Discipline model, using the `:required_role` attribute. Discipline is linked to modules by their `:name` attribute in the Discipline model.

The second level of access control is provided by restricting users from actioning workflow steps, unless they have been granted the designated role for the step.

## System Architecture

Refer to [DEVELOPER_NOTES](DEVELOPER_NOTES.md) section Application Structure, also [README.md](../README.md) for an overview of the application structure.

The application's resources fall into a number of categories for implementation of the RBAC system.

1. System resources.

   High level resources such as the Role model, the User model, the Project model and the Discipline model must define their roles and responsibilities individually. There are a small number of other system wide resources that have their own individual access control.

1. Project resources.

   Resources scoped to projects use a common permissions policy.

1. Discipline resources.

   Resources scoped to disciplines/modules use a common permissions policy.

## Roles

The application RBAC system uses the [rolify gem](https://github.com/RolifyCommunity/rolify/wiki/Usage) for role management.

### Constraints

To avoid proliferation of ad hoc roles and rules which may lead to confusion, the RBAC is quite tightly controlled. Role names cannot be assigned by users: the available role names in the application are constrained by a constant hash built from `config/constants/role.yml`. Translation of role names and descriptions is provided in `config/locales/core/xx/xx.rolify.yml` where `xx` is the locale code. Assignment of a role name other than those permitted in the constant set up will result in a permissions error. Details are in the implementation section.

### Hierarchy

#### Global Roles

Global roles are provided for system administration purposes. Users with global roles can access all projects. These roles collectively are referred to in this document as global admin roles.

1. **App Owner**
   - Permission for all controller actions, including destroy.
   - Scope includes all records when no project is selected.
   - Can assign any available role to any user, including :admin and other :app_owner roles.

2. **Admin**
   - Permission for all controller actions, including destroy.
   - Scope includes all records when no project is selected.
   - Can assign any available role to any user, except :admin, :project_admin, and other :app_owner roles.

#### Resource Wide Roles

- The RBAC system caters for resource wide roles, but none have been implemented to date.
- A resource wide role would give a user access to all instances of a resource, e.g. all document source formats or all colour swatches.
- [TODO: source formats, swatches]

#### Project Instance Roles

- Some permissions are managed through the project resource, with content modification actions requiring a designated role scoped to the project instance.
- Project teams should be self managed as far as is practicable. Global admins create a project and assign a user with the :project_manager role, who then assigns the necessary roles for completing the project.
- If a project is large, it may not want to depend on the small number of global admins for record deletion and other system maintenance tasks, so can request that a :project_admin role be assigned.

1. **Project Manager**
   - The :project_manager role can only be granted by a global admin.
   - A user with :project_manager role has control over the assigned project.
   - A project manager can modify project details and settings.
   - A project manager can grant and revoke other further roles to users for the assigned project, with the exception of the :project_manager and :project_admin roles.

1. **Project Administrator**
   - The :project_admin role can only be granted by an :app_owner role.
   - A user with :project_admin role has permission for all controller actions, including destroy, for records belonging to the project.
   - The :project_admin role does not give permission to grant or revoke roles.

1. **Team Member**
   - A user with :team_member role can view project content.
   - [TODO: any create permissions? E.g. comments?]

### Discipline Instance Roles

- Disciplines belong to a project, so a role scoped to a discipline is effectively also scoped to the project.
- A discipline role gives access to content within the module represented by that discipline.

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
- The form is only accessible to admins and app_owner.
- The user interface for project and discipline specific roles is a sub-form on the resource edit page, present only if the user has the required permissions to grant or revoke roles on that project or discipline.

## Permissions and Scopes

The application RBAC system uses the [pundit gem](https://github.com/varvet/pundit) for permissions and scopes.

### Policies

- Pundit uses policy objects, one for each resource to be managed.
- Policies provide a boolean permission for each action in a resource's controller.
- Policies also provide a scope object which enables restricting the list of resource instances available to a user.
- By design, pundit policies use the signed in user (current user) and either the resource class, or the resource instance being managed to determine permissions.
- This application has extended pundit to include the current project as a context for permissions and scopes.
  - Scope is used to limit visibility of records to only include those that belong to the current project.
  - Permissions are checked to ensure that user has the required role scoped to the current project before allowing action.
  - Index and show actions are generally available to any user with any role on the current project.
  - Content modification actions (new/create and edit/update) are usually available only to users with the required role scoped to the current project.
  - Users with global admin roles are not constrained by current project context for viewing, but current project must be set in order to create or edit a record.

#### Destroy Action Rules

- The application uses a revision tracking system for most data.
- Deletion of data is restricted to admins, and only used for database repairs or similar, to otherwise preserve the data history.
- Only `app_owner` can destroy projects due to the significant impact of this action.
- **Exception for Roles**:
  - Although internally treated as a resource, with rolify roles and a pundit policy, the Role model itself is integral to the working of the rolify gem, therefore core to the machinery of the RBAC and is not considered a normal user-accessible resource.
  - Roles are destroyed when revoked without history tracking.
  - Role destruction permissions are resource-specific.

#### Required Role

- By default, tagable resource models define their own required role. This is inherited from the module Base class, but may be overridden in individual classes.
- Projects may override the class defined required role by setting the associated discipline's :required_role attribute, which must be a permitted role for the Discipline class. This should be left as nil to use the default, which is :designer for engineering resources.
- Tags and documents are core models, they don't belong to any module and don't have a required role. They are nested under discipline in routes, so a discipline must be provided to enable permissions checking for the new action.

## PERMISSIONS DETAILS

This section lists the reasoning for the RBAC implementation for each of the main elements of the application. A matrix of roles and permissions is provided for each resource or group of resources with similar permissions.

As well as the checks in the matrices, policies also check that the action does not breach the current project boundary. If current project is set, policies will deny actions that would affect resources outside of that project. If current_project is not set (only allowed for global admins) then only index, show, and destroy actions will be available.

#### Terminology

- The terminology used in this document does not necessarily agree exactly with the code implementation. [HOLD make it do so?]
- Because they mostly have the same permissions, global admin roles (:app_owner and :admin) and :project_admin role are grouped together under the column "Admin", unless there are permissions differences (such as for the Role model).
- "Team member" is used in the matrices to mean any user with any project role, with the exception of users who may have more specific roles in other columns. This is not the same as a user with a :team_member role.
- "Accredited user" is used in the matrices to include any user with a required role specific to the action in that row. The same term is used in code to include __any__ user with permission for the action, i.e. including the admin roles.

### PERMISSIONS AND SCOPE FOR ROLE MODEL

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

## PERMISSIONS AND SCOPE FOR PROJECT MODEL

The Project model is a "walled garden" in the application. For the most part, users are only working on one project (current_project) at any time. Most roles assigned to users are scoped to a project instance.

- Only a user with :admin or :app_owner role can create a new project.
- Only a user with :app_owner role can delete a project, because this would result in destruction of all subsidiary data history.
- A user with :project_manager or :project_admin role can edit the project title, description, and metrics for the project instance where the role is held.
- Scope for the Project model includes all projects for which the user has any role. This is used in listing available projects for current project selection.

### Permission Matrix for Project Model

| Action                         | Global admin | Project admin | Project Manager | Team Member |
|--------------------------------|--------------|---------------|-----------------|-------------|
| View Project                   | ✓            | ✓             | ✓               | ✓           |
| Create Project                 | ✓            | x             | x               | x           |
| Edit Project                   | ✓            | ✓             | ✓               | x           |
| Delete Project                 | ✓            | x             | x               | x           |
|

## PERMISSIONS AND SCOPE FOR DISCIPLINE MODEL

The disciplines model is used to categorize tags, documents, etc. Disciplines belong to a project, which enables all child objects to determine their scope. Disciplines generally correspond to software modules within the application.

- Disciplines are created by the system at project creation.
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

## PERMISSIONS AND SCOPE FOR TAG MODEL

Tags are the building block for engineering elements data. Ultimately, most tags will be linked to a tagable resource, but this is not a requirement.

- Tags belong to a discipline, which determines their project association.
- Tags use their discipline association to determine their required role. If this is nil, they will determine the required role from the discipline's module (by name) Base class.
- Tags are shallow nested under discipline in routes, so discipline must be provided for index, new and create actions.
- Admins have full access to tags.
- Only a user with an admin role can delete a tag, because this would result in destruction of all associated tag data history.
- Users with any role on the current project can view tag details.
- Scope for the tag model includes all tags belonging to the current project, but in practice the index view will be scoped to the discipline.

### Permission Matrix for Tag Model

| Action                         | Admins | Accredited User | Team Member |
|--------------------------------|--------|-----------------|-------------|
| View Tag                       | ✓      | ✓               | ✓           |
| Create Tag                     | ✓      | ✓               | x           |
| Edit Tag                       | ✓      | ✓               | x           |
| Delete Tag                     | ✓      | x               | x           |
|

## PERMISSIONS FOR TAGABLE MODELS

Tagable models are the database equivalent to datasheets for engineering elements. Each element is linked to a tag. The tag's discipline should correspond to the module containing the tagable model, though this is not enforced.

- Tagable resources belong to a tag, and the tag's discipline association determines their project association.
- Users can create and modify content for a tagable resource, as long as they have the required role. Required role can be defined by the parent tag's discipline, but if this is nil it defaults to the resource class required_role.
- Admins have full access to tagable resources.
- Only admin users can delete any tagable model resources, because this would result in destruction of associated data history.
- Users with any role on the current project can view the tagable models.
- Scope for the tagable models includes all resources belonging to the current project.

### Permission Matrix for Tagable Models

| Action                         | Admins | Accredited User | Team Member |
|--------------------------------|--------|-----------------|-------------|
| View Resource                  | ✓      | ✓               | ✓           |
| Create Resource                | ✓      | ✓               | x           |
| Edit Resource                  | ✓      | ✓               | x           |
| Delete Resource                | ✓      | x               | x           |
|

## PERMISSIONS FOR DOCUMENT MODEL

The Document model provides the document register for the project.

- Like tags, documents belong to a discipline, which determines their project association.
- Also like tags, documents initially use their discipline association to determine their required role. If this is nil, they will determine the required role from the discipline's module (by name) Base class.
- Documents are shallow nested under discipline in routes, so discipline must be provided for index, new and create actions.
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

## PERMISSIONS FOR DOCUMENT CONTROL MODELS

The DocTypes model provides a list of available document types for each discipline. The doc_type association of a document determines its workflow.

- DocTypes belong to a discipline, which determines their project association.
- The required role for doc_types is :document_controller scoped either to current project or discipline.
- Global admins and project admins have full access to doc_type resources.
- Scope for the doc_type model includes all doc_types belonging to the current project, but in practice the index view will be scoped to the discipline.

### Permission Matrix for DocTypes Model

| Action                         | Admins | Accredited User | Team Member |
|--------------------------------|--------|-----------------|-------------|
| View DocType                   | ✓      | ✓               | ✓           |
| Create DocType                 | ✓      | ✓               | x           |
| Edit DocType                   | ✓      | ✓               | x           |
| Delete DocType                 | ✓      | x               | x           |

The SourceFormats model provides a list of available software source formats. This is a system wide list, so is primarily controlled by global admins. However, as it is not critical data, individual projects are allowed to contribute to the list. Any user with a document_controller role can create entries, but not edit or delete.

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

## PERMISSIONS FOR CHANGE CONTROL MODELS

The ChangeManagement module tracks and manages changes on a project. The Request model records the instigation of change management processes. If a change request (CR) is considered beneficial, it is assigned to a lead discipline to develop a change proposal (CP). The CP fully evaluates the options, assess cost vs benefit, risk, and completes detailed engineering design of the proposed change. After submission, the CP is reviewed and either approved, sent for revision, or rejected. If approved, a Change Order (CO) is raised and assigned to an implementation team.

- Requests belong to a project.
- Proposals and orders have a one to one association with the initiating request, which determines their project association.
- Any team member may initiate a change request on a project, there is no required role.
- Only project managers and admins can initiate CPs and COs.
- Users with the lead discipline's required role can edit CPs and COs.
- Admins have full access to all change control resources.
- Scope for all change_management models is the current project.

### Permission Matrix for ProjectChange Models

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

- To control access to any resource, start by adding "resourcify" to the model class.
- Most resources can reference the roles on the Project model.
- If you add resourcify to a model, you need to add grant_role? and revoke_role? methods to the policy, as the role policy delegates these methods.
- Update the constants definition in config/constants/role.yml to add any new roles, or modify availabilty of roles to specific resources.
- Update all config/locales/core/xx/xx.rolify.yml files to reflect any new or changed role names.
- This constant hash determines what role name options are available in the role assignment forms, and is also used to validate role assignments before application, for security.
- Methods for listing valid roles of different types, and for checking role validity for a resource are provided in the Role class.

### Pundit

- When adding a new resource using either of the app's scaffold generators, a new pundit policy and policy test file are automatically created.
- The tagable generated policy inherits from the TagablePolicy class in [tagable_policy.rb](../app/policies/tagable_policy.rb). This class assumes that the resource has a connection to projects through tag, discipline and project associations.
- The scaffold generated policy inherits from the ProjectResourcePolicy class in [project_resource_policy.rb](../app/policies/project_resource_policy.rb). This class assumes that the resource has a direct association to projects.
- Pundit policies determine access to controller actions based on the logged in user, the role/s assigned to the user, the resource instance or class, and the current project.
- Note that including the current project in the pundit context is not rails/pundit convention, it is an extension for this application.

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
prepare_roles_for_display(roles_scope) - Flattens a scope of roles into an array of hashes suitable for display tables. Each hash contains: role id, user id, resource type, resource label (or "-" if none), role name, user name, and the role object itself. Sorts by resource type, resource label, and role name.
group_roles(roles) - Takes the flattened roles array and groups it hierarchically: first by resource type, then by resource label, then by role name. Returns a nested hash: { resource_type => { resource_label => { role_name => [user_names] } } }.
grouped_roles_for_resource(resource) - Convenience method for the _role_assignment partial. Combines prepare_roles_for_display and group_roles for a specific resource instance.
Error Handling: The module wraps setup logic in a begin/rescue block to catch exceptions and log them to Rails.logger, ensuring the UI doesn't crash if role data is malformed.

Instance Variables created by setup_role_assignment:


| Variable | Content |
|---|---|
| @resource_types | Array for the resource_type dropdown. Format: [[translated_name, class_name], ...]. First element is ['Global', ''], followed by all Rolify resource types (Project, Discipline, etc.) with humanized names |
| @grouped_role_names | Hash for the role_name dropdown. Keys are translated group labels (e.g., "Global Roles"), values are arrays of [translated_role_name, role_key] pairs |
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
@role → form model object
@grouped_roles → display existing roles in tables
@role_return_path (set by controller, not helper) → redirect after create/destroy