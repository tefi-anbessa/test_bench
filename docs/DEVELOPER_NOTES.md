# Developer Notes & Ideas

## AI Integration

From git commit 6da446f onwards, this project has used Windsurf/Cascade AI to speed up development and improve code quality. The learnings of this process including coding conventions and project peculiarities, etc. have been captured in "Memories" on the Cascade server side.

### For Developers:
1. When initiating a new session with AI, request it to review the project guiding documentation:
   - `README.md`
   - Project documentation in `docs/`:
      - `docs/DEVELOPER_NOTES.md`
      - `docs/DOCUMENTATION_PREFERENCES.md
      - `docs/TESTING.md`
      - `docs/ROLES_AND_PERMISSIONS.md`
2. Request AI to review the memories and follow the guidance therein. If memories are not available, refer to the duplicated documentation in `docs/AI memories/`.

### Maintenance:
- These guidelines and requirements will evolve over time.
- Any changes should be reflected in the documentation.
- When modifying role permissions or access controls, ensure both `ROLES_AND_PERMISSIONS.md` and the corresponding policy files are updated.
- Request the AI to update its Memories when significant changes occur.

## Known Issues

### Pagination
- **Issue**: The pagination system is not respecting the `per_page` parameter correctly.
- **Symptoms**: 
  - The URL updates with the selected `per_page` value
  - The page size selector shows the correct selected value
  - However, the number of items displayed remains at the default (20)
- **Affected Files**:
  - `app/controllers/concerns/page_sizeable.rb`
  - `app/views/shared/_page_size_selector.html.erb`
  - `test/system/page_size_selector_test.rb`
- **Next Steps**:
  - Check if the pagination is being overridden by any default scopes
  - Verify the pagination parameters are being passed correctly to the database query
  - Add more detailed logging to trace the pagination flow

## KISS Principle Guidelines

The project follows the KISS (Keep It Simple, Stupid) principle with these priorities:

1. **Minimal Viable Features First**:
   - Implement only requested features
   - Avoid adding unrequested functionality
   - Keep initial implementations simple and focused

2. **Testing Foundation**:
   - Ensure all tests pass before adding new features
   - Maintain test coverage for core functionality
   - Focus on stable, working features over feature completeness

3. **Incremental Development**:
   - Build a solid foundation before adding enhancements
   - Get approval for each feature before moving forward
   - Keep pull requests and changes small and focused

4. **Current Focus**:
   - Projects functionality is the current priority
   - Dashboard features should be deferred until core functionality is stable
   - Avoid premature optimization or over-engineering

5. **Code Review Guidelines**:
   - Question any added complexity
   - Challenge features that weren't explicitly requested
   - Prefer simple, maintainable solutions over clever ones

## Development Check List
- [x] Build static pages as framework for future displays for casual visitors
- [x] Build application layout with headers, footers, navigation
- [x] Build core module with project and tag models
- [x] Internationalise the application
- [ ] Build user interaction management, using gems devise for authentication, rolify and pundit for authorization
- [ ] Build electrical module with basic data sheet options for electrical tagged items
- [ ] Enhance electrical module, allowing interconnection of tagged items with cables to model a distribution network
- [ ] Build a process piping module similar to the electrical module, using pipes and fittings to model a process piping network
- [ ] Build a document control module to manage document storage, issue, history including versions
- [ ] Enhance the existing database models to allow revison control of data
- [ ] Build a bookkeeping module to manage financial transactions
- [ ] Build an asset management module to track assets and link from design to maintenance
- [ ] Build a maintenance management module 


## Technical Debt
- [ ] Refactor models to incorporate i18n messages for validations
- [ ] Serve bootstrap from local dev or prod
- [ ] Write more tests for the Demand model
- [ ] Review all policies and tests for compliance with guidelines
- [ ] Review all models for compliance with guidelines
- [x] Clean up old Load model references after migration
- [ ] The project was originally written for Rails 7 but got hibernated. On reawakening, it was upgraded to Rails 8. It has never been deployed to production, so Rails 8 upgrade is not yet officially declared complete.
- [ ] Improve has_one validation on tagable, possibly include database constraint.
- [ ] Improve has_one validation on demandable, possibly include database constraint.
- [ ] Nest project related resource under projects to improve security around assignment to other than the current project.

## Refactoring Opportunities
- [ ] Improve role and permissions implementation and workflow.
- [ ] Refactor projects controller with improved workflow.
- [ ] Consider extracting demand calculations into a service object
- [ ] Add type checking with Sorbet or RBS
- [ ] Implement caching for frequently accessed demand data
- [x] Upgrade to Rails 8 (Completed in rails8 branch)
- [ ] Refactor electrical policy classes (CablePolicy, SwitchboardPolicy, MotorPolicy, LightCctPolicy, SocketCctPolicy) to use a shared concern or base class to reduce code duplication
- [ ] Change terminology and implementation from project owner to project manager.
- [ ] Refactor projects controller and application controller `def after_sign_in_path_for(resource)to use app/controllers/concerns/current_project_concern.rb to reduce code duplication.
- [ ] Cable types: 
   - [ ] convert core material to enum.
   - [ ] convert insulation material to enum.
   - [ ] add volt rating enum.
- [ ] Refactor tag 'description' to 'service'.
- [ ] Redesign tag module:
   - [ ] base full tag becomes a string object.
   - [ ] builder/parser model for each discipline which creates the string according to the required format, and can parse the string back into the components.
   - [ ] provide default format for each discipline, e.g. isa5.1.
 
## Potential Features
- [ ] Add more comprehensive reporting for demand calculations
- [ ] Implement bulk import/export for demands
- [ ] Add more detailed documentation for the demand calculation formulas
- [ ] See if pagy can provide user selectable page size
- [ ] Data revision management
- [ ] Customize devise views
- [ ] Customize devise users:
   - Allow users to self register through devise, edit their own profile and user name, email, password. 
   - Insert an admin approval in the confirmation process
   - Disable destroy, because the [future] change history will have links to users making changes. We may need to historise user name changes as well, that's a future problem. The revision management system may well include some sort of active/inactive status features. 
- [ ] Customize error trapping:
   - [ ] Customize error trapping for Pundit::NotAuthorizedError
   - [ ] Customize error trapping for unknown format
   - [ ] Customize error trapping for forbidden
- [ ] Improve locale setting, and include language/currency/flag in locale selection.

## Architecture Considerations
- [ ] Move Electrical to a module or namespace.
- [ ] Consider API versioning strategy
- [ ] Plan for database scaling as demand data grows

## Role System Documentation

The role system is defined by the following components:

1. **Configuration**:
   - Defined in `config/constants/role.yml`
   - Uses three categories: `global_roles`, `functional_roles`, and resource-specific roles under `resources`

2. **Key Files**:
   - `app/models/role.rb`: Core role model with validation and query methods
   - `test/factories/roles.rb`: Dynamic factory that generates traits from Constants
   - `docs/ROLES_AND_PERMISSIONS.md`: Detailed documentation on the role system
   - `docs/USER_GUIDE.md`: End-user documentation for role management

3. **Integration**:
   - The Role model validates against the constants
   - Provides helper methods like `valid_roles_for` and `valid_role?`
   - Factory generates traits dynamically from the constants

## Notes
- Keep backward compatibility during the Load → Demand transition
- Document any non-obvious electrical calculation formulas
- Consider adding performance benchmarks for critical paths
