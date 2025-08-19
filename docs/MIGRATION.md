# Migration Guide: Roles and Permissions Refactor

## Overview
This document outlines the changes made during the roles and permissions refactor and provides guidance for updating existing code.

## Changes Summary

### 1. Role System Updates
- Consolidated role management using Rolify
- Standardized role names and permissions
- Added project-scoped roles

### 2. Policy Changes
- Implemented Pundit for authorization
- Created policy classes for all major models
- Added scopes for resource filtering

## Migration Steps

### 1. Update Gemfile
```ruby
gem 'pundit'
gem 'rolify'
```

Run:
```bash
bundle install
```

### 2. Database Migrations
Run the following migrations:
```bash
rails generate rolify:role
rails db:migrate
```

### 3. Model Updates
Update your User model:
```ruby
class User < ApplicationRecord
  rolify
  
  # Existing code...
end
```

### 4. Controller Updates
Update your controllers to use Pundit:
```ruby
class ProjectsController < ApplicationController
  include Pundit::Authorization
  
  def show
    @project = authorize Project.find(params[:id])
  end
  
  # Other actions...
end
```

## Backward Compatibility

### Role Helpers
Old role checks:
```ruby
if current_user.admin?
```

New role checks:
```ruby
if current_user.has_role?(:admin)
```

### Permission Checks
Old way:
```ruby
if can? :edit, @project
```

New way:
```ruby
if policy(@project).edit?
```

## Testing Updates

### Controller Tests
Update your controller tests to use Pundit's test helpers:

```ruby
require 'pundit/rspec'

RSpec.describe ProjectsController, type: :controller do
  describe 'GET #show' do
    it 'authorizes the action' do
      project = create(:project)
      sign_in user
      get :show, params: { id: project.id }
      expect(controller).to be_authorized
    end
  end
end
```

## Common Issues and Solutions

### "Undefined Method" Errors
If you see errors like:
```
undefined method `admin?' for #<User>
```

Update to use the new role system:
```ruby
# Old
user.admin?

# New
user.has_role?(:admin)
```

### Permission Denied Errors
If you get Pundit authorization errors, ensure:
1. The corresponding policy exists
2. The policy method returns true for the action
3. The user has the required role

## Rollback Plan
If you need to revert the changes:

1. Checkout the previous commit
2. Run database rollback:
   ```bash
   rails db:rollback VERSION=<pre_roles_migration_timestamp>
   ```
3. Remove the Pundit and Rolify gems
4. Run `bundle install`

## Support
For assistance with the migration, contact the development team or open an issue in the repository.
