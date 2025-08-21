# Project Overview and Key Features

## Test Bench - Ruby on Rails Application

## Core Components

### 1. User Management
- **Authentication**: Devise
- **Authorization**: Rolify and Pundit
- **Role Hierarchy**:
  - App Owner
  - Admin
  - Project Owner
  - Team Member

## Deployment Requirements

### Offline/Local Operation
- The application must function entirely offline or on local networks without internet access
- All JavaScript/CSS dependencies must be bundled locally
- No external CDN dependencies are allowed
- All assets must be precompiled and served locally

## Core Features

### 1. Project Management
- Unique 2-letter project codes (e.g., AA, AB, AC)
- Project stages (1-10) for organization
- Document versioning with paper_trail
- Role-based access control

### 3. Tagging System
- **Tag Types**:
  - Switchboard
  - Cable
  - Motor
  - SocketCct
  - LightCct
  - Pipe
  - Source
  - Consumer
- Tags are unique within disciplines and projects
- Can be linked to datasheets and detailed information
- Support for hierarchical relationships

### 4. Electrical Power Distribution
- Models for electrical components
- Load calculation and management
- Circuit protection and cable sizing
- Integration with tagging system

## Technical Stack

### Backend
- **Framework**: Ruby on Rails
- **Database**: PostgreSQL
- **Background Jobs**: Active Job with Sidekiq
- **Search**: pg_search (PostgreSQL full-text search)

### Frontend
- **Templating**: ERB with ViewComponent
- **Styling**: Bootstrap 5 with custom theme
- **JavaScript**: Stimulus.js for interactivity
- **Icons**: Bootstrap Icons

### Testing
- **Test Framework**: minitest
- **Feature Tests**: Capybara with Selenium
- **Test Coverage**: SimpleCov
- **Test Data**: FactoryBot for test factories

## Development Workflow

### Version Control
- Git with GitHub Flow
- Semantic versioning (MAJOR.MINOR.PATCH)
- Conventional commits

### Code Quality
- RuboCop for Ruby style guide enforcement
- ESLint for JavaScript
- Pre-commit hooks for automated checks
- Code reviews required for all changes

## Documentation
- Comprehensive README with setup instructions
- API documentation with RDoc
- Database schema documentation
- Architecture decision records (ADRs)
- User guides and developer documentation
