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
- The tag is the link to data sheet and further detailed information. 
- [TODO - implement flexible tag structure.] Tags are unique within disciplines and projects.
- [TODO]: Provide an option for tags to be unique only on the project level. Requires coordination of tag prefixes.
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
  - Each circuit can have protection devices and options.
  - Each circuit can have an assigned load and cable. These are used to evaluate the distribution as a tree data structure.
- Switchboards are always of load type "summation", meaning they aggregate the loads of their outgoing circuits.

### Cables
- Cables are assigned to cable types, which define the cable's properties, such as insulation type, conductor material, etc.
- Cable type set is specific to the project.
- [TODO - at present cables are only "from" power source (switchboard) to load (motor, socket, light, etc.) Build a more flexible cable model]

## Role Hierarchy and Permissions

The application implements a role-based access control (RBAC) system. Refer to docs/ROLES_AND_PERMISSIONS.md for details.

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
