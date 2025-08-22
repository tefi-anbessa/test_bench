# Current Project Implementation in Dev and Test

## Overview
The application manages the currently selected project across requests using a combination of session storage and helper methods.

## Implementation Details

### 1. CurrentProjectConcern
- Located in `app/controllers/concerns/current_project_concern.rb`
- Included in ApplicationController
- Provides `current_project` and `project_selected?` methods to all controllers and views
- Uses session/cookie for persistence

### 2. Test Environment
- Test helper provides `current_project` and `with_current_project` helper
- `with_current_project` method sets up and cleans up the current project for test blocks
- Tests can use `current_project` to access the current project
- Project context is automatically cleaned up between tests

### 3. Policy Context
- Pundit policies have access to the current project through the controller context
- `current_project` is automatically available in all policies
- Used for scoping and authorization decisions

## Key Methods
- `current_project` - Returns the current project from session/cookie
- `project_selected?` - Checks if a project is currently selected
- `require_project!` - Ensures a project is selected (redirects if not)
- `store_location_for_project` - Saves the current URL for redirecting back after project selection
