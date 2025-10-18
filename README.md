# Test Bench

A Ruby on Rails application for assisting with multiple engineering projects. The application is primarily intending to improve connectivity for all your engineering and project related data, through all phases of the project lifecycle.
A single database retains all data for all projects, so data can be shared, but access is managed as required.

## Users

[HOLD] user registration process is not finalized.
- Users are validated using the `devise` gem. Permissions are controlled using the `rolify` and `pundit` gems.

## Projects

- Projects are the top-level resource.
- There is a substantial wall around each project. The role based access control (RBAC) system has a "current project" context, so users are typically working on a single project at any time.
- Projects may have multiple "stages". (Stages might also be called "phases" but that conflicts with the electrical engineering term.)
- Stages can be used to partition projects by lifecycle stage, such as FEED, Design, Construction, Commissioning, Operation, etc. In this case, data would transition from one phase to the next, under a revision controlled process.
- Stages can also be used to segregate projects into cost centres, or phased construction.

## Disciplines

- Each project has a set of disciplines, which are used to define the workflow and schema for the core resources: tags and documents.
- Typical disciplines for an engineering project would include civil, process, piping, electrical, instruments, communications, etc.
- [HOLD] - Because they are not typically mutable, there is no UI for managing disciplines. They are set by db:seed.

## Tags

- Engineering design elements require a tag to be assigned.
- Tags are the link and provide the label for all design elements, such as buildings, pipes, motors, gauges, etc.
- Tags have a service description, which succinctly describes the purpose of the design element.
- [HOLD] Tags belong to projects, but can be sub-grouped within a project by assigning a project stage.
- Tags belong to disciplines, and the discipline sets the schema for the prefix tagging convention on the project. This allows tag prefixes to be constrained to acceptable values or formats.
- Tags have a loop number, which is intended to be unique to the function of the tagged item. Note that loop is traditionally an instrument tagging concept, and the in that case the loop is actually the first character of the prefix, followed by a number.
- Internally, loop is referenced as 'serial' to avoid confusion with loop in a programming context. This should not be visible to users.
- Tags may have a suffix , useful for when multiple items are required for the same function, e.g. street lights on the same circuit.
- Tags are required to be unique, but the constraint is over the whole combination of project, discipline, prefix, serial number, and suffix. So, projects don't have to be aware of other project's tags. Disciplines can use the same prefix for different meanings, without knowing about other assignments.
- The tag is the link to data sheet and other detailed information, such as electrical load data.
- For a tag to have further information added, it has to be assigned to a type. The information required is generally what is needed to produce a data sheet for procurement.
- The following tagable types are available: [TODO: keep this list up to date]
  - Switchboard, Cable, Motor, SocketCct, LightCct, Pipe, Source, Consumer

## Electrical

- Electrical power distribution can be modeled, mainly for the purpose of producing documentation.
- [HOLD] - Electrical load modeling
- The following tag types can have attached electrical load information: [TODO: keep this list up to date]
  - Switchboard, Cable, Motor, SocketCct, LightCct

### Switchboards

- Switchboards have multiple outgoing circuits, each uniquely identified.
  - Each circuit can have protection devices and options.
- Switchboards are always of load type "summation", meaning they aggregate the loads of their outgoing circuits.

### Cables

- Cables have a cable type, which defines the cable's properties, such as insulation type, conductor material, etc.
- Cable type set is specific to the project, but facilities are available to copy between projects.
- Cables have a "from" assignment and a "to" assignment.
- Cables can connect switchboard circuits to electrical loads by assigning the circuit as "from" and the load as "to".
- [TODO - at present cables are only "from" power source (switchboard) to load (motor, socket, light, etc.) Build a more flexible cable model]

## Role Based Access Control (RBAC)

The application implements a role-based access control (RBAC) system. Refer to docs/ROLES_AND_PERMISSIONS.md for details.

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
