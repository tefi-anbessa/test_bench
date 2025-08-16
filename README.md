# Test Bench

A Ruby on Rails application for managing multiple engineering projects.
## Users
- Users are validated using the `devise` gem. Permissions are controlled using the `rolify` and `pundit` gems. 

## Projects
- Projects are the top-level resource. 
- Projects are uniquely identified by a 2-letter code, e.g. AA, AB, AC, etc.

## Tags
- Design elements require a tag to be assigned. 
- Tags belong to projects, but can be sub-grouped within a project by assigning a project stage (1 to 10).
- The tag is the link to data sheet and further detailed information. [TODO - implement flexible tag structure.] Tags are unique across disciplines and projects.
- For a tag to have further information added to produce a data sheet, it has to be assigned to a tagable type. The following tagable types are available: [TODO: keep this list up to date]
- Switchboard
- Cable
- Motor
- SocketCct
- LightCct
- Pipe
- Source
- Consumer

## Electrical
- Electrical power distribution can be modeled, mainly for the purpose of producing documentation. 
- The following tag types are loadable, meaning they can have attached electrical load information: Switchboard, Motor, SocketCct, LightCct. [TODO: keep this list up to date]
- Switchboards have multiple outgoing circuits, each uniquely identified. 
- Each circuit has protection devices and options.
- Each circuit can have an assigned load and cable.
- Switchboards are always of load type "summation", meaning they aggregate the loads of their outgoing circuits.

## Role Hierarchy and Permissions

The application implements a role-based access control (RBAC) system with the following hierarchy:

### Global Roles
The UI for global and resource roles is the roles index page.

#### 1. Owner (Super Admin)
- **Role**: `:owner`
- **Permissions**:
  - Full system access
  - Can assign/revoke `:admin` roles
  - Can perform all CRUD operations on all resources
  - Only one user should have this role globally

#### 2. Admin
- **Role**: `:admin`
- **Permissions**:
  - Can perform all CRUD operations on all resources
  - Can manage users (except assigning `:owner` global role)
  - Can assign/revoke `:creator`, `:approver`, `:editor`, `:checker`, `:reader` roles

### Projects resource
- The UI for project instance roles is a sub-form on the project show page.
- Roles on the project resource propagate down to child resources such as tags and documents. - These roles should be tied to project instances, they should not be resource wide.
- `:owner` - Full control over a project, including all subsidiary resources
- `:creator` - Can create and edit resources
- `:editor` - Can edit resources
- `:checker` - Can check resources
- `:approver` - Can approve resources for publication
- `:viewer` - Read-only access to resources

### Resource-Instance Roles
- The UI for resource instance roles is a sub-form on the resource show page, where applicable.
- `:creator` - Can create and edit resources
- `:editor` - Can edit resources
- `:checker` - Can check resources
- `:approver` - Can approve resources for publication
- `:viewer` - Read-only access to resources

- Can be assigned to other users on resource instances, e.g. Project, Document, etc. to allow delete permissions within that instance.

## Implementation Notes

- Roles are managed using the `rolify` gem
- Permissions are enforced using Pundit policies
- The `:owner` role should be assigned during initial setup
- Only the `:owner` can assign the `:admin` role
- `:admin` users can manage other users' roles except for the `:owner` role

### Development Guidelines

### UI/UX Conventions

#### Forms
- Use Bootstrap form helpers (`bootstrap_form_with` and `bootstrap_form_for`) consistently throughout the application
- Follow Rails conventions for form structure and helpers

#### Icons
- Use the `icon` helper for all Bootstrap Icons
- Basic usage: `icon('icon-name')`
- Example with button and spacing: 
  ```erb
  <button class="btn btn-primary">
    <span class="me-1"><%== icon('save') %></span> Save
  </button>
  ```
- The helper automatically adds the `bi` and `bi-[icon-name]` classes
- For accessibility, the helper includes `aria-hidden="true"` by default
- Always wrap the icon in a `<span>` if you need to apply margin or other styling

#### Layout
- Follow Bootstrap's grid system and component structure
- Use Bootstrap's spacing utilities for consistent margins and padding
- Maintain responsive design principles

### Getting Started

These instructions will get you a copy of the project up and running on your local machine for development and testing purposes.

#### Prerequisites

* Ruby version

* System dependencies

* Configuration

* Database creation

* Database initialization

* How to run the test suite

* Services (job queues, cache servers, search engines, etc.)

* Deployment instructions

* ...
