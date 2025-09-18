# Developer Guidance

1. Read Readme.md, it is the primary documentation for installers and users. It explains the application's capabilities.
2. Read docs/DOCUMENTATION_PREFERENCES.md, it explains the available documentation for the application and how to use it.
3. Read docs/ROLES_AND_PERMISSIONS.md, it explains the role based access control (RBAC) system, one of the pillars of the application.
4. Read the following sections of this document:
   - AI Integration
   - KISS Principle Guidelines
   - Implementation
   Other sections can be skimmed until needed:
   - Known Issues
   - Development Check List
   - Technical Debt
   - Refactoring Opportunities
   - Potential Features

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

## Implementation
Set options for select fields in the controller, not in the view. Complete i18n translations for select fields in the view.

### Error Handling
   - Errors are categorized as:
      - User data entry errors: These are errors that can be fixed by the user, such as missing required fields or invalid data.
         - Required fields are highlighted by html5 without any additional code. Not sure how to translate these.
         - Invalid data should be detected in the controller and the form displayed again with error messages. Rails manages standard error messages but translations may need to be provided [HOLD] check this.
         - More complex validations of associations use custom error messages with translations.
      - 
      - Security breach attempts: These are trapped forbidden operations that should not be possible using normal workflows. They are probably direct HTML requests in an attempt to defeat the permissions system. This type of error should log a message to the rails logger, redirect to the custom /403 page, and log out the user. 

### Form Design

   - Use bootstrap buttons wherever possible for consistent appearance and behavior.
   - 

### Icons

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

## Development Check List
- [x] Build static pages as framework for future displays for casual visitors
- [x] Build application layout with headers, footers, navigation
- [x] Build core module with project and tag models
- [x] Internationalise the application
- [x] Build user interaction management, using gems devise for authentication, rolify and pundit for authorization
- [x] Build electrical module with basic data sheet options for electrical tagged items
- [ ] Enhance electrical module, allowing interconnection of tagged items with cables to model a distribution network
- [ ] Enhance the existing database models to allow revison control of data
- [ ] Build a document control module to manage document storage, issue, history including versions
- [ ] Build a bookkeeping module to manage financial transactions
- [ ] Build a process piping module similar to the electrical module, using pipes and fittings to model a process piping network
- [ ] Build an asset management module to track assets and link from design to maintenance
- [ ] Build a maintenance management module 


## Technical Debt
- [ ] Refactor models to incorporate i18n messages for validations
- [ ] Refactor error messages partial to use i18n.
- [ ] Refactor error views to use i18n.
- [x] Refactor roles new view and projects edit view to translate resource names with a key value pair in the select field.
- [x] Serve bootstrap from local dev or prod
- [ ] Write more tests for the Demand model
- [ ] Review all policies and tests for compliance with guidelines
- [ ] Review all models for compliance with guidelines
- [x] Clean up old Load model references after migration
- [ ] The project was originally written for Rails 7 but got hibernated. On reawakening, it was upgraded to Rails 8. It has never been deployed to production, so Rails 8 upgrade is not yet officially declared complete.
- [x] Improve has_one validation on tagable, possibly include database constraint.
- [x] Improve has_one validation on demandable, possibly include database constraint.
   - Database constraints deferred due to risk of locking database. Continue with inclusion of orphans on index displays, and manual clean up.
- [ ] Nest routes for project related resource under projects to improve security around assignment to other than the current project.
- [ ] Revisit the roles policy test. The roles policy is now using the role context from the controller, need to factor this into tests. 
- [ ] Roles policy is delegating to resource policies for resource instances. Tests need to consider this.
- [ ] Ensure select for role names does not include restricted roles unless current user has app_owner role.
- [ ] System test for tags.

## Refactoring Opportunities
- [x] Improve role and permissions implementation and workflow.
- [x] Refactor models to include a universal "label" attribute to be used when presenting polymorphic associations.
- [ ] Refactor projects controller with improved workflow.
- [ ] Consider extracting demand calculations into a service object
- [ ] Add type checking with Sorbet or RBS
- [ ] Implement caching for frequently accessed demand data
- [x] Upgrade to Rails 8 (Completed in rails8 branch)
- [x] Refactor electrical policy classes (CablePolicy, SwitchboardPolicy, MotorPolicy, LightCctPolicy, SocketCctPolicy) to use a shared concern or base class to reduce code duplication
- [x] Refactor all views to use pundit policy checks.
- [x] Change terminology and implementation from project owner to project manager.
- [ ] Refactor projects controller and application controller setting of current project: `def after_sign_in_path_for(resource)to use app/controllers/concerns/current_project_concern.rb to reduce code duplication.
- [ ] Cable types: 
   - [ ] convert core material to enum.
   - [ ] convert insulation material to enum.
   - [ ] add volt rating enum.
- [ ] Motors: 
   - [ ] convert motor type to enum.
   - [ ] convert frame size to enum.
   - [ ] build a ruby structure for ingress protection, convert ingress protection to this type.
   - [ ] convert poles to enum.
   - [ ] convert speed rated to enum.
- [x] Refactor tag 'description' to 'service'.
- [ ] Redesign tag module:
   - [ ] base full tag becomes a virtual field.
   - [ ] builder/parser model for each discipline which creates the string according to the required format, and can parse the string back into the components.
   - [ ] provide default format for each discipline, e.g. isa5.1
   - [ ] add next/previous functionality
   - [ ] add colour code by discipline
- [ ] Look at use of hover on buttons, and use turbo to prevent page refresh.
- [ ] Improve implementation of Discipline model, including translation.
 
## Potential Features
- [ ] Add more comprehensive reporting for demand calculations
- [ ] Implement bulk import/export
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
- [ ] Develop an application colour theme set. Consider discipline colour coding, also need to consider module colour coding.

## Architecture Considerations
- [ ] Move Electrical to a module or namespace.
- [ ] Consider API versioning strategy
- [ ] Plan for database scaling as data grows



## Notes
- [x] Keep backward compatibility during the Load → Demand transition
- Document any non-obvious electrical calculation formulas
- Consider adding performance benchmarks for critical paths
