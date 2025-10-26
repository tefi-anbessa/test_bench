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

### Documentation Maintenance

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

4. **Focus**:
   - Application functionality is always the priority
   - Format and presentation should be deferred until core functionality is stable
   - Avoid premature optimization or over-engineering

5. **Code Review Guidelines**:
   - Question any added complexity
   - Challenge features that weren't explicitly requested
   - Prefer simple, maintainable solutions over complex ones

## Implementation

### Internationalization

- The application has been designed for international use from the outset. 
- All user facing text is provided with translations for all implemented languages.
- To date, no need for translation of database content has been identified. It's all engineering speak.
- The application uses the rails-i18n gem to assist with internationalization. This gem provides translations into  many languages for the core rails features, including model validation, database errors, time and date functions, currency, etc. 
- For reference, a copy of the en version of the translations is saved in config/locales/rails-i18n gem en for reference/en.yml.ref. This file is not used in the application, it is simply a copy of the en.yml file that is provided by the rails-i18n gem. Check here if you are not sure whether a translation is already provided, and avoid duplicating core translations if possible. Also note that not all language files include all translations! It is a work in progress...
- The locale setting follows the basic guidelines in [Rails Guides section 2.2](https://guides.rubyonrails.org/i18n.html#setting-the-locale-from-url-params).
- Changing locale is available in the layout header via a drop down menu.


### Constants

- The application implements a constants management system based on this article: [https://dev.to/vladhilko/say-goodbye-to-messy-constants-a-new-approach-to-moving-constants-away-from-your-model-58i1](https://dev.to/vladhilko/say-goodbye-to-messy-constants-a-new-approach-to-moving-constants-away-from-your-model-58i1).
- The code has been tweaked to allow the hash parsing to end on an array as well as a hash. This allows arrays for floating point numbers (primarily for electrical selectors).
- Usage: 
  - Constants.electrical.protection.rating yields an array: [1, 2, 4, 6, 10, 16, 20, 25, 32, 40, 50, 63]
  - Constants.electrical.protection.device yields a special hash: #<Constant::Model:0x000000012b7b1390 @constant_hash={:MCB=>1, :MCCB=>2}>. It may be necessary to convert this to a basic hash if required with to_h.

### MVC Guidelines

#### Models

- Model classes include all logic pertaining to the object.
- Model classes should include custom validations where required. Custom validations must include i18n translation of custom error messages.
- All resource models should have a label method, which is used to present a human readable identifier, preferably unique, for the model. This can (and in most cases will be) simply a reference to another attribute. It will be used in views as a card header, link id, etc.

#### Controllers

- Controller classes include basic logic for performing CRUD operations on the object.
   - Controllers are responsible for setting all variables for the view, generally including select options derived from data.

#### Views

- Views should not include complex logical processing.
   - Conditionals should be controlled by pundit policy calls where applicable.
   - Conditionals may also use presence or otherwise of variables set in the controller.
   - Views should use model constants such as enums to generate select options directly. Use human_enum_name from app/models/application_record.rb to provide the translations.
   - Views should include i18n translations for all user facing text, including:
      - flash error messages
      - select options




### Error Handling

   - Errors are categorized as:

   #### Unauthenticated access:

      - Users need to be authenticated by the devise system for all MVC actions.
      - Errors are handled by the application controller rescue_from Devise::NotAuthenticatedError.
      - Users are redirected to the sign in page.
      - Controllers typically use a single before_action :authenticate_user! to implement devise security. 
      - Controller tests typically include one test to ensure that unauthenticated access is not possible.
      - Tests can use the test helper method assert_unauthenticated.

   #### Unauthorized access:

      - These are pundit authorisation failures.
      - Generally, the workflow should not allow access to unauthorized functions.
      - However, until the application is thoroughly tested in use, this is considered a lesser error than a security breach attempt.
      - Errors are processed by the application controller rescue_from Pundit::NotAuthorizedError.
      - Rescue includes a flash danger message with the translated standard error message, and redirects to custom error page /403 forbidden.
      - Policy tests should be used to verify that policies meet their objectives, refer to docs/ROLES_AND_PERMISSIONS.md.
      - Controller tests should also include tests of unauthorized access, to ensure that appropriate authorization calls are included in relevant actions.
      - Controller tests should only test the pass and fail paths, they are not intended to test the policy details.
      - Tests can use the test helper method assert_forbidden.

   #### User data entry errors:

      - These are errors that can be fixed by the user, such as missing required fields or invalid data.
      - Required fields are highlighted by html5 without any additional code. Not sure how to translate these.
      - Invalid data should be detected in the controller and the form displayed again with flash :alert messages.
      - Rails manages standard model validation messages but translations may need to be provided [HOLD] check this.
      - Model validation messages are displayed on form views using the partial app/views/shared/_error_messages.html.erb
      - More complex validations of associations use custom error messages with their translations.
      - Model tests should include test of each validation to ensure that user data entry errors are caught and translated error messages are added to the model object.

   #### Security breach attempts: 

      - These are trapped forbidden operations that should not be possible using normal workflows.
      - They are probably injected HTML or JSON requests in an attempt to defeat the permissions system. 
      - When a controller detects invalid parameters, custom error class ConflictError should be raised, with a message key specific to the actual error.
      - ConflictErrors are handled in ApplicationController by rescue_from ConflictError and method handle_conflict. 
      - handle_conflict logs the error with the message code, redirects to the custom /409 conflict page, and logs out the current user.
      - At present, the custom /409 page includes a flash alert with the translated error message. This may not be required in production if it is considered that 409 errors are definitely hacking attempts.
      - Controller tests should include thorough test of each path through the controller to ensure that security breach attempts are trapped.
      - Tests can use the test helper method assert_conflict.

### Form Design

   - Use bootstrap buttons wherever possible for consistent appearance and behavior.
   - Use bootstrap card format wherever applicable, for consistent appearance.
   - Make use of the reusable collapsible card (with js controller) for ancilliary information relevant to the form but not for modification. e.g. Cable form includes a collapsible card for cable type, showing further details of the cable type.

### Icons

- Bootstrap icons are used as graphical elements to support usability.
- The gem bootstrap-icons-helper simplifies finding the icons (notoriously difficult with the recommended installation methods).
- Icons have been copied to app/assets/icons. 
- If a new icon is required, search in <https://icons.getbootstrap.com>, find the name and use it. (The website doesn't include sorting facilities so it is not easy to find by function unless the name corresponds to the function.)
- The helper method icon(name) in app/helpers/bootstrap_icon_helper.rb is used to further simplify icon usage.
- Typical usage is:
`<%= f.submit((yield(:button_text)), class: 'btn btn-primary') do %>
          <%== icon('save') %>
        <% end %>`
- Important: The double equals is used to prevent html escaping of the icon.
- Be consistent in icon usage. Preferred icons are:
  - "list-columns-reverse" for index views
  - "box-arrow-in-left" for link to previous object same class
  - "box-arrow-in-right" for link to next object same class
  - "box-arrow-down-right" for link to child object
  - "box-arrow-up-left" for link to parent object
  - "link" for link to open a form for a new child object
  - "plus" for new buttons to open a form
  - "pencil" for edit buttons to open a form
  - "trash" for delete buttons to delete the object
  - "search" for search buttons on views
  - "x-square" for Discard Changes buttons on forms
  - "save" for save buttons on forms

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
- [x] Enhance electrical module, allowing interconnection of tagged items with cables to model a distribution network
- [ ] Enhance electrical model with network load calculations
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
- [ ] Revisit the roles policy test. The roles policy is now using the role context from the controller, need to factor this into tests.
- [ ] Roles policy is delegating to resource policies for resource instances. Tests need to consider this.
- [ ] Ensure select for role names does not include restricted roles unless current user has app_owner role.
- [ ] System tests for all resources.
- [ ] Improve forbidden error logging messages, include user. Consider automatic sign out.
- [ ] Model tests should include test of enums.
- [ ] Complete workflows with admin and no project selected.
- [ ] Complete proper ordering by switchboard tag and serial for circuits.
- [ ] Update index view header lines.
- [ ] Custom error view for not found errors. e.g. Case where admin deletes a record than uses browser back button.
- [ ] Translation of html5 messages on required fields. Alternatively, suppress html 5 and use client side js.
- [ ] Complete switchboard controller test.
- [ ] Complete cable system tests for from and to after switchboard, demand, and circuit tests are working.
- [ ] Use of button text for new and edit forms is mixed. Standardise on save for new, update for edit.
- [ ] Demand form live update of calculated values not working.

## Refactoring Opportunities

- [x] Improve role and permissions implementation and workflow.
- [x] Refactor models to include a universal "label" attribute to be used when presenting polymorphic associations.
- [ ] Refactor projects controller with improved workflow.
- [ ] Add type checking with Sorbet or RBS
- [ ] Implement caching for frequently accessed demand data
- [x] Upgrade to Rails 8 (Completed in rails8 branch)
- [x] Refactor electrical policy classes (CablePolicy, SwitchboardPolicy, MotorPolicy, LightCctPolicy, SocketCctPolicy) to use a shared concern or base class to reduce code duplication
- [x] Refactor all views to use pundit policy checks.
- [x] Change terminology and implementation from project owner to project manager.
- [ ] Refactor projects controller and application controller setting of current project: `def after_sign_in_path_for(resource)to use app/controllers/concerns/current_project_concern.rb to reduce code duplication.
- [ ] Tags:
   - [x] Refactor tag 'description' to 'service'.
   - [ ] Add location attribute to tag, remove from all tagables.
- [x] Cable types: 
   - [x] convert core material to enum.
   - [x] convert insulation material to enum.
   - [x] add volt rating enum.
   - [ ] Add parent/child capability.
- [ ] Motors: 
   - [x] convert motor type to enum.
   - [x] convert frame size to enum.
   - [ ] build a ruby structure for ingress protection, convert ingress protection to this type.
- [ ] Redesign tag module:
   - [ ] base full tag becomes a virtual field.
   - [x] builder/parser model for each discipline which creates the string according to the required format, and can parse the string back into the components.
   - [x] provide default format for each discipline, e.g. isa5.1
   - [x] add next/previous functionality
   - [ ] add colour code by discipline
- [ ] Look at use of hover on buttons, and use turbo to prevent page refresh.
- [ ] Improve implementation of Discipline model, including translation. Consider using constants hash for each project.
- [ ] Consider changing all delete links to use turbo to prevent page refresh.
 
## Potential Features

- [ ] Add more comprehensive reporting for demand calculations
- [ ] Implement bulk import/export
- [ ] See if pagy can provide user selectable page size
- [ ] Data revision management
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
- [ ] Build an IP55 object to allow fully flexible reusable IP code generation.

## Architecture Considerations

- [ ] Move Electrical to a module or namespace.
- [ ] Nest routes for project related resource under projects to improve security around assignment to other than the current project.
- [ ] Consider API versioning strategy
- [ ] Plan for database scaling as data grows


## Notes

- [x] Keep backward compatibility during the Load → Demand transition
- [ ] Consider adding performance benchmarks for critical paths
