# README

This README documents the Test Bench application, a Ruby on Rails project.

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
