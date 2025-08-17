# AI Implementation Tasks

## Current Tasks
- [ ] Remove deprecated Load model and related code
  - [ ] Delete old Load model file
  - [ ] Remove Load controller and views
  - [ ] Run database migration to rename tables/columns

## Completed Tasks
- [x] Rename Load model to Demand
- [x] Update all view templates to use demand_path/demands_path
- [x] Update routes to use demands instead of loads
- [x] Update controller actions to use Demand model
- [x] Update model associations and validations
- [x] Update locale files for user-facing text
- [x] Ensure backward compatibility with aliases

## Implementation Notes
- The Demand model was renamed from Load to avoid conflicts with Ruby's built-in Load class
- Backward compatibility has been maintained with aliases where needed
- User-facing text still shows "Load" where appropriate through locale files
