# Test Bench

A Ruby on Rails application for assisting with multiple engineering projects. The application is primarily intending to improve connectivity for all your engineering and project related data, through all phases of the project lifecycle. A single database retains all data for all projects, so data can be shared, but access is managed as required.

## Users

[HOLD] user registration process is not finalized.
- Users are validated using the `devise` gem. Permissions are controlled using the `rolify` and `pundit` gems.

## Projects

Projects are the top-level resource in the application.

- There is a control wall around each project. The role based access control (RBAC) system has a "current project" context, and users are typically working on a single project at any time. RBAC system roles are scoped to projects, so users must be granted access privileges for each project where they have a role.
- All resources belong to a project, apart from a small number of system resources.

## Disciplines

Each project has a set of disciplines, which are used to group resources functionally.

- Typical disciplines for an engineering project would include civil, process, piping, mechanical, electrical, instrumentation, communication.
- Disciplines are correlated with the software modules which provide the functionality of data management in the application. A set of standard disciplines is provided, which link to the actual software modules in the application, but projects can customise disciplines if needed.
- Disciplines specify the default role needed to create and edit content in the associated module's resources. E.g. the electrical discipline by default requires a user to have "electrical_designer" role to create tags and datasheets for cables, motors etc. Projects can override the defaults in the discipline definition.
- Disciplines have a colour swatch assigned, which is used to provide a visual clue to the user.

## Tags

Engineering design elements require a tag to be assigned.

- Tags are the link and provide the label for all design elements, such as buildings, pipes, motors, gauges, etc.
- Every tag belongs to a discipline, through which they belong also to the discipline's project.
- Tag numbers comprise a prefix, loop number, and optional suffix. They must be unique within their discipline.
- The discipline sets the schema for the prefix tagging convention. This allows tag prefixes to be constrained to acceptable values or formats.
- The loop number should be unique to the function of the tagged item.
- Where multiple elements provide the same function, a suffix may be added to distinguish them.
- Note that loop is traditionally an instrument tagging concept, and for instrumentation type tags, the loop is actually the first character of the prefix, followed by the numeric part.
- Tags require a service description, which succinctly describes the purpose of the design element.
- Tags can be sub-grouped within a project by assigning a project stage.
- Tags can be assigned a location, which is generally a physical location for the element.
- Internally, loop is referenced as 'serial' to avoid confusion with loop in a programming context. This should not be visible to users.
- The tag is the link to data sheet and other detailed information, such as electrical load data.
- For a tag to have further information added, it has to be assigned to a type. The type information is used to produce a data sheet.
- The following tagable types are available: [TODO: keep this list up to date]
  - Electrical: Switchboard, Cable, Motor, SocketCct, LightCct, Pipe, Source, Consumer

## Documents

The Document Control module implements a document register. At present, it is not linked to a repository, but this is planned for the future.

- Like tags, every document belongs to a discipline, through which they belong also to the discipline's project.
- Document numbers include the project code, discipline label, document type code, and a serial number. The serial number is automatically generated to ensure a unique document number.
- Document type codes are set for each discipline.
- Once created, document numbers may not be edited.
- Documents require a title.

## Changes

The application provides a change control system, to manage and track project changes.

- Changes are initiated by raising a change request (CR). The CR simply describes the issue that needs to be addressed, and offers a summary solution.
- The CR is then reviewed according to the project specified workflow. The CR may be closed or it may initiate a Change Proposal (CP).
- The CP is assigned to engineering for development, with a clear performance metric to be met. Change proposals are assigned a lead discipline.
- The CP development will include studies as required to indicate the preferred solution, and all required detailed design engineering.
- The CP is then reviewed according to the project specified workflow. Typically, the CP may be closed, returned for further development, or it may initiate a Change Order (CO).
- The CO is an instruction to implement the changes described in the CP.
- The party assigned to implement the CO will then complete procurement, installation, testing, and completion.

## Module Resources

### Electrical

- Electrical power distribution can be modeled, mainly for the purpose of producing documentation.
- [HOLD] - Electrical load modeling
- The following tag types can have attached electrical load information: [TODO: keep this list up to date]
  - Switchboard, Cable, Motor, SocketCct, LightCct

#### Switchboards

- Switchboards have multiple outgoing circuits, each uniquely identified.
  - Each circuit can have protection devices and options.
- Switchboards are always of load type "summation", meaning they aggregate the loads of their outgoing circuits.

#### Cables

- Cables have a cable type, which defines the cable's properties, such as insulation type, conductor material, etc.
- Cable type set is specific to the project, but facilities are available to copy between projects.
- Cables have a "from" assignment and a "to" assignment.
- Cables can connect switchboard circuits to electrical loads by assigning the circuit as "from" and the load as "to".
- [TODO - at present cables are only "from" power source (switchboard) to load (motor, socket, light, etc.) Build a more flexible cable model]

## Role Based Access Control (RBAC)

The application implements a role-based access control (RBAC) system. Refer to `docs/ROLES_AND_PERMISSIONS.md` for details.

### Getting Started

[TODO] These instructions will get you a copy of the project up and running on your local machine for development and testing purposes.

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
