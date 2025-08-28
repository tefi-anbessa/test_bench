# Test Bench

A Ruby on Rails application for managing multiple engineering projects.
## Users
- Users are validated using the `devise` gem. Permissions are controlled using the `rolify` and `pundit` gems. 

## Projects
- Projects are the top-level resource. 
- Projects are uniquely identified by a 2-letter code, e.g. AA, AB, AC, etc.

## Disciplines
- Disciplines can be used to group tags, documents, etc.
- Disciplines are set across the organization, so all projects share the same set of discipine codes.
[HOLD] - Disciplines interact with functional role assignments. 
- Because they are not typically mutable, there is no UI for managing disciplines. They are set by db:seed.

## Tags
- Engineering design elements require a tag to be assigned. 
- Tags belong to projects, but can be sub-grouped within a project by assigning a project stage (1 to 10).
- Tags belong to disciplines, e.g. Electrical, Piping, etc.
- The tag is the link to data sheet and further detailed information. [TODO - implement flexible tag structure.] Tags are unique within disciplines and projects.
[TODO]: Provide an option for tags to be unique only on the project level. Requires coordination of tag prefixes.
- For a tag to have further information added, it has to be assigned to a tagable type. The information required is generally what is needed to produce a data sheet for procurement.
- The following tagable types are available: [TODO: keep this list up to date]
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
- The following tag types are demandable, meaning they can have attached electrical load information: 
  - Switchboard 
  - Motor
  - SocketCct
  - LightCct
[TODO: keep this list up to date]
### Switchboards
- Switchboards have multiple outgoing circuits, each uniquely identified. 
  - Each circuit has protection devices and options.
  - Each circuit can have an assigned load and cable.
- Switchboards are always of load type "summation", meaning they aggregate the loads of their outgoing circuits.
### Cables
- Cables are assigned to cable types, which define the cable's properties, such as insulation type, conductor material, etc.
- Cable type set is specific to the project.
- [TODO - at present cables are only "from" power source (switchboard) to load (motor, socket, light, etc.) Build a more flexible cable model]

## Role Hierarchy and Permissions

The application implements a role-based access control (RBAC) system. Because most resources will be subject to a revision control system, delete operations are not allowed by default. This is to prevent accidental deletion of data history. The roles have the following hierarchy:

### Global Roles
- The UI for global roles is the roles index page.

#### 1. Owner (Super Admin)
- **Role**: `:app_owner`
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
  - Can assign/revoke functional roles
  - Unless otherwise specified, only admin or app_owner can perform delete operations


### Projects resource
- The UI for project instance roles is a sub-form on the project show page.
- A ':team_member' role on the project instance is required to access child resources such as tags and documents.
- There should be no resource wide roles for Project.
- **Role**: `:project_owner`
- **Permissions**:
  - There should be only one user granted this role for each project instance
  - Create, edit and update a project instance and its child resources
  - Can assign/revoke `:team_member` roles
- **Role**: `:team_member`
- **Permissions**:
  - Default read-only access to all of the project instances resources
  - Required for create, edit and update access to child resources such as tags and documents, and other functional roles.

### Resource-Wide Roles
- The UI for resource wide roles is the roles index page.
- Resource wide roles are based on functional roles.
- A resource wide role gives a user create, edit and update access to the resources associated with the function, provided the user also has a member role for the project instance.

#### 1. Electrical resources
- **Role**: :electrical_designer'
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
