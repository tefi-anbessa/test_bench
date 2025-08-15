# Test Bench

A Ruby on Rails application for managing engineering projects, tags, and user roles.

## Role Hierarchy and Permissions

The application implements a role-based access control (RBAC) system with the following hierarchy:

### 1. Owner (Super Admin)
- **Role**: `:owner`
- **Permissions**:
  - Full system access
  - Can assign/revoke `:admin` roles
  - Can perform all CRUD operations on all resources
  - Only one user should have this role

### 2. Admin
- **Role**: `:admin`
- **Permissions**:
  - Can perform all CRUD operations on all resources
  - Can manage users (except assigning `:owner` role)
  - Can assign/revoke `:creator` and `:member` roles

### 3. Creator
- **Role**: `:creator`
- **Permissions**:
  - Can create and edit resources
  - Cannot delete resources
  - Cannot manage users

### 4. Member (Default)
- **Role**: `:member` (default role for new users)
- **Permissions**:
  - Read-only access to most resources
  - Limited to viewing resources they have been granted access to

## Resource-Specific Roles

In addition to global roles, users can have project-specific roles:

- `:project_owner` - Full control over a specific project
- `:project_editor` - Can edit a specific project
- `:project_viewer` - Read-only access to a specific project

## Implementation Notes

- Roles are managed using the `rolify` gem
- Permissions are enforced using Pundit policies
- The `:owner` role should be assigned during initial setup
- Only the `:owner` can assign the `:admin` role
- `:admin` users can manage other users' roles except for the `:owner` role

## Development Guidelines

## Development Guidelines

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
