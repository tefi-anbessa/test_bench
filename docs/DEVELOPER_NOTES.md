# Developer Guidance

1. Read [Readme](../README.md), it is the primary documentation for installers and users. It explains the application's capabilities. [TODO: update readme]
2. Read [DOCUMENTATION_PREFERENCES](DOCUMENTATION_PREFERENCES.md), it explains the available documentation for the application and how to use it.
3. Read [ROLES_AND_PERMISSIONS](ROLES_AND_PERMISSIONS.md), it explains the role based access control (RBAC) system, one of the pillars of the application.
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

### AI Rules

Windsurf IDE has introduced a new feature called "AI Rules". These are rules that are applied to the code by the AI. The rules are defined in the .windsurf/rules directory.

Progressively build the set of rules to implement these guidelines.

### Developers Using AI

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
- When modifying role permissions or access controls, ensure both [ROLES_AND_PERMISSIONS](ROLES_AND_PERMISSIONS.md)`and the corresponding policy files are updated.
- Request the AI to update its Memories when significant changes occur. [waste of time]

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

### Application Structure

The application caters for various user scenarios, including:

- design and execute team such as a constructor, using a shared website app.
- engineering design service for multiple clients, using a shared website app.
- application installed in house for a single client.

The application has a core structure encompassing Users and the associated access control system, Projects, Disciplines, Tags and Documents. Further functionality is encapsulated in modules, which correspond to engineering disciplines.

Only one level of module nesting is envisaged, however some features have provisioned for sub-modules.

Refer to [ROLES_AND_PERMISSIONS](ROLES_AND_PERMISSIONS.md) for details on the RBAC system.

#### Projects

Projects are the top level resource of this application. Projects are "ring-fenced" for security, so users are always working on their current project. Users with access to more than one project can copy from one to the other. [TODO: not implemented yet]

#### Disciplines

Disciplines are used to group engineering objects, and associate them to functional requirements. Each project is provided with a standard set of disciplines including instrument, electrical, mechanical, etc.

#### Tags

Engineering design elements require a tag to be assigned. Tags are used to label design elements, and link them to their own data, as well as to other elements, to documents, assets and other functionality. Tags belong to a discipline, which determines their available prefixes, via the prefix_schema attribute.

#### Tagables

Tags can have a "tagable" model attached, which extends the information linked to the tag to include the specific information relevant to the type of element. For example, a motor and a cable have different information requirements, so the database needs to have a different table for each, but they share the structure of the tags table. Each of these models is known as a tagable model. All tagables are grouped into modules, and modules are coupled to the disciplines provided.

#### Documents

Documents are used to manage and control the issue of information on a project. The document model is located in the core application.

Each discipline has its own set of document types. A document must have a document type, which determines the discipline to which it belongs, as well as the associated workflow when issuing the document.

Documents can be generated from the application database, or stored in a content delivery network from files uploaded by users.

[HOLD At present, no repository is included, only a document register].

#### Modules

Generally, tagable models are segregated into modules according to their discipline. This is primarily to keep the file structure manageable, but flows into the presentation of views, which are accessed by project or discipline. Disciplines are able to impart some default properties to their members through inheritance from the Base model for each module.

Exceptions to this structure are the Cable and Cable Types models, which are used by the electrical, instrument, and communication disciplines, so reside in the application core.

### Internationalization

The application has been designed for international use from the outset.

- All user facing text is provided with translations for all implemented languages.
- To date, the only need for translation of database content identified is for discipline names. Further content translation is included in the potential features list below.
- The application uses the rails-i18n gem to assist with internationalization. This gem provides translations into many languages for the core rails features, including model validation, database errors, time and date functions, currency, etc.
- For reference, a copy of the en version of the translations is saved in [config/locales/rails-i18n gem en for reference/en.yml.ref](../config/locales/rails-i18n%20gem%20en%20for%20reference/en.yml.ref). This file is not used in the application, it is simply a copy of the en.yml file that is provided by the rails-i18n gem. Check in this file if you are not sure whether a translation is already provided, and *avoid duplicating core translations* if possible. Also note that not all language files include all translations! It is a community work in progress...
- The locale setting follows the basic guidelines in [Rails Internationalization (I18n) API section 2.2](https://guides.rubyonrails.org/i18n.html#setting-the-locale-from-url-params).
- Changing locale is available in the layout header via a drop down menu.
- The storage of translation files is detailed in the [INTERNATIONALIZATION](INTERNATIONALIZATION.md) document.

### Constants

- Constants in Rails applications are the subject of debate in the forums. The understanding of what should be constant varies widely.
- The context for this application includes:
  - Engineering and scientific constants that are indepedent of the application, such as standard ratings for circuit breakers, cable sizes, etc.
  - Role Based Access Control (RBAC) system configuration.
  - Default setup for disciplines and associated prefix schemata.
  - Allowed values for enum type attributes.
- Refer to [CONSTANTS](CONSTANTS.md) for details on the constants management system implemented for this application.

### MVC Guidelines

Ruby on Rails implements the Model View Controller (MVC) pattern for data driven web applications.

#### Models

- Model classes include all logic pertaining to the object.
- Model classes should include custom validations where required. Custom validations must include i18n translation of custom error messages.
- All resource models should have a label method, which is used to present a human readable, non language specific identifier, preferably unique, for the model. This can be simply a reference to another attribute, or a combination of attributes. It will be used in views as a card header, link id, etc.
- All resources should have a long label method, which includes a parent identifier as well as the instance identifier. This will be used for view headers.

#### Controllers

CRUD operations refer to the four basic functions of persistent storage in computer programming: Create, Read, Update, and Delete. These operations are essential for managing data in databases and applications, allowing users to add, retrieve, modify, and remove data as needed.

- Controller classes include logic for performing CRUD operations on the object.
  - Controllers are responsible for setting variables for the view, including select options that are derived from data.
  - Controllers are responsible for providing the user with feedback via an appropriate flash message after every operation.

#### Views

The standard set of views (as generated by the rails scaffold generator, or the application's tagable generator) should be provided for each resource model, including:

- Index
- Show
- New
- Edit

The index view should use partials for the header and list items:

- `_header`
- `_row`

The new and edit views should only set title and variables, then defer to the form partial:

- `_form`

In addition, a card partial should be provided for drop down view on other pages:

- `_card`

- All views shall provide a page title which appears on the browser tab, which includes the view and the model name.
- Index and show views shall have a header line which includes the header and a standard set of navigation buttons.
- The index header shall specify whether the index is for project, discipline, or all projects (only available to global admins).
- The show view header shall include the resource model name, the record's long_label, and optionally a title or service description.
- The new view header shall include the scope where the resource is to be created e.g. discipline label.
- The edit view header shall include the resource's long_label.
- Navigation buttons for index and show views shall include "return" index buttons to the higher level views, locate to the left of the header.
- Navigation buttons for show views shall also include previous and next buttons, located left and right of the header.
- Index views shall also include new "action" button to the right of the header, conditional on user permissions.
- Show views shall also include edit, delete, and new "action" buttons to the right of the header, conditional on user permissions.
- Title and header shall be translated using a `views.yml` file in the locales structure, see [INTERNATIONALIZATION](../config/locales/INTERNATIONALIZATION.md).
- Views should not include complex logical processing.
- Conditionals should be controlled by pundit policy calls where applicable.
- Conditionals may also use presence or otherwise of variables set in the controller.
- Views should use model constants such as enums to generate select options directly. Use human_enum_name from [application_record](../app/models/application_record.rb) to provide the translations.
- Views should include i18n translations for all user facing text, including:
  - Model names.
    - Model name translations are pluralized for English: two options are provided, :one and :other. Either provide a count, or include the explicit key required in the translation call.
    - Future refactor may be required for other language pluralization.
    - Use of I18n::t('activerecord.models.tag.one') is preferred, as it is a strict translation and raises "translation missing" in dev environment, if required.
    - Use of @tag.model_name.human is acceptable, but if the translation is missing it will fall back to humanize the coded model name, which won't look good in other locales.
  - Attribute labels.
    - In forms, use bootstrap_form fields, which automatically wrap with a translated label.
    - Use of I18n::t('activerecord.attributes.tag.prefix') is preferred in other cases.
    - Use @tag.class.human_attribute_name(:prefix) may be used but uses fallbacks to the coded attribute name.
  - Attribute help text.
    - In bootstrap_form fields, use help: I18n::t('activerecord.help.tag.prefix') option.
    - Use I18n::t('activerecord.help.tag.prefix') if required in other cases.
  - Select options.
    - If select options are derived from data, they should be built as an instance variable (hash or array) in the controller, and passed to the view. Options derived from data won't generally have translations available.
    - If select options are built from enums (which mostly will be built in turn from Constants), and don't require translation, use the model enum methods directly in the view.
    - If select options are built from enums, and require translation, use something like:
      ```demand.class.configs.keys.collect { |config| [demand.class.human_enum_name(:config, config), config] },```
      directly in the view.
  - Flash messages
      - Flash messages should be generated and translated in the controller, and the standard layout will display them. Normally nothing is required in views.
      - Complex forms may require further flash processing.
  - Messages
          - Occasionally, bespoke explanatory messages are required. Translations should be provided in the appropriate views.yml file.

### Error Handling

Errors are categorized as:

#### Unauthenticated access

- Users need to be authenticated by the devise system for all MVC actions.
- Errors are handled by the application controller rescue_from Devise::NotAuthenticatedError.
- Users are redirected to the sign in page.
- Controllers typically use a single before_action :authenticate_user! to implement devise security.
- Controller tests typically include one test to ensure that unauthenticated access is not possible.
- Tests can use the test helper method assert_unauthenticated.

#### Unauthorized access

- These are pundit authorisation failures.
- Generally, the workflow should not provide access to unauthorized functions.
- However, until the application is thoroughly tested in use, this is considered a lesser error than a security breach attempt.
- Errors are processed by the application controller rescue_from Pundit::NotAuthorizedError.
- Rescue includes a flash danger message with the translated standard error message, and redirects to custom error page /403 forbidden.
- Policy tests should be used to verify that policies meet their objectives, refer to [ROLES_AND_PERMISSIONS](ROLES_AND_PERMISSIONS.md).
- Controller tests should also include tests of unauthorized access, to ensure that appropriate authorization calls are included in relevant actions.
- Controller tests should only test the pass and fail paths, they are not intended to test the policy details.
- Tests can use the test helper method assert_forbidden.

#### User data entry errors

- These are errors that can be fixed by the user, such as missing required fields or invalid data.
- Required fields are highlighted by html5 without any additional code. Not sure how to translate these.
- Invalid data should be detected in the controller and the form displayed again with flash :alert messages.
- Rails manages standard model validation messages but check that the translations are provided in the core application (config/locales/rails-i18n gem en for reference/en.yml.ref).
- Model validation messages are displayed on form views using the partial app/views/shared/_error_messages.html.erb
- More complex validations of associations use custom error messages with their translations.
- Model tests should include test of each validation to ensure that user data entry errors are caught and translated error messages are added to the model object.

#### Security breach attempts

- These are trapped forbidden operations that should not be possible using normal workflows.
- They are probably injected HTML or JSON requests in an attempt to defeat the permissions system.
- Controllers need to be designed carefully to ensure all user provided data is sanitized. Frequent use of enum attributes, length validation, strong parameters, and explicit type checking can help prevent these attacks.
- When a controller detects invalid parameters, custom error class ConflictError should be raised, with a message key specific to the actual error.
- ConflictErrors are handled in ApplicationController by rescue_from ConflictError and method handle_conflict.
- handle_conflict logs the error with the message code, redirects to the custom /409 conflict page, and logs out the current user.
- At present, the custom /409 page includes a flash alert with the translated error message. This may not be required in production if it is considered that 409 errors are definitely hacking attempts.
- Controller tests should include thorough test of each path through the controller to ensure that all security breach attempts are trapped.
- Tests can use the test helper method assert_conflict.

### Form Design

- Use bootstrap_form for forms.
- Use bootstrap buttons wherever possible for consistent appearance and behavior.
- Use bootstrap card format wherever applicable, for consistent appearance.
- Make use of the reusable collapsible card (with js controller) for ancilliary information relevant to the form but not for modification. e.g. Cable form includes a collapsible card showing details of the cable type.

### Icons

- Bootstrap icons are used as graphical elements to support usability.
- The gem bootstrap-icons-helper simplifies finding the icons (notoriously difficult with the recommended installation methods).
- Icons have been copied to app/assets/icons.
- If a new icon is required, search in <https://icons.getbootstrap.com>, find the name and use it. (The website doesn't include sorting facilities so it is not easy to find by function unless the name corresponds to the function.)
- The helper method bs_icon(name) in app/helpers/bootstrap_icon_helper.rb is used to further simplify icon usage.
- Typical usage is:
`<%= f.submit((yield(:button_text)), class: 'btn btn-primary') do %>
          <%== bs_icon('save') %>
        <% end %>`
- Important: The double equals is used to prevent html escaping of the icon.
- Be consistent in icon usage. Preferred icons and colours are:
  - "list-columns-reverse" class "-info" for index views
  - "box-arrow-in-left" class "-secondary" for link to previous object same class
  - "box-arrow-in-right" class "-secondary" for link to next object same class
  - "box-arrow-down-right" class "-info" for link to child object
  - "box-arrow-up-left" class "-info" for link to parent object
  - "folder" class "-info" for link to project object
  - "layers" class "-info" for link to discipline object
  - "tag" class "-info" for link to tag object or index
  - "file" class "-info" for link to document object or index
  - "eye" class "-info" for link to view other objects
  - "link" class "-primary" for link to open a form for a new child object
  - "plus" class "-primary" for new buttons to open a form
  - "pencil" class "-warning" for edit buttons to open a form
  - "trash" class "-danger" for delete buttons to delete the object
  - "search" class "-primary" for search buttons on views
  - "x-square" class "-warning" for Discard Changes buttons on forms
  - "save" class "-primary" for save (create or update) buttons on forms
- Flag icons are used to assist with locale/language selection.
  - The gem rails-icons is used with the library 'flags' to provide the icons.
  
## Known Issues

### Tagable Validation

It is possible to create multiple tags referencing the same tagable element, despite the validations in place.

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
- [x] Build a module generator.
- [x] Build a tagable generator.
- [x] Build a scaffold generator for models without links to tags.
- [ ] Enhance electrical model with network load calculations.
- [ ] Enhance the existing database models to include revison control of data.
- [ ] Build a document control module to manage document storage, issue, history including versions and workflow.
- [ ] Add polymorphic comments.
- [ ] Management of Change.
- [ ] Build an instrument module.
- [ ] Build a bookkeeping module to manage financial transactions.
- [ ] Build a process piping module similar to the electrical module, using pipes and fittings to model a process piping network.
- [ ] Build an asset management module to track assets and link from design to maintenance.
- [ ] Build a maintenance management module.
- [ ] Add hazardous area functionality.
- [ ] Risk Management.
- [ ] Functional Safety.

## Technical Debt

- [x] Refactor models to incorporate i18n messages for validations
- [x] Refactor error messages partial to use i18n.
- [x] Refactor error views to use i18n.
- [x] Refactor roles new view and projects edit view to translate resource names with a key value pair in the select field.
- [x] Serve bootstrap from local dev or prod.
- [x] Complete tags controller test.
- [x] Review all policies and tests for compliance with guidelines.
- [x] Review all models for compliance with guidelines.
- [x] Clean up old Load model references after migration.
- [x] The project was originally written for Rails 7 but got hibernated. On reawakening, it was upgraded to Rails 8. It has never been deployed to production, so Rails 8 upgrade is not yet officially declared complete.
- [x] The transition to rails 8 should have changed over the asset pipeline to use propshaft. This has not been done properly, needs to be rectified.
- [x] Improve has_one validation on tagable, possibly include database constraint.
- [x] Improve has_one validation on demandable, possibly include database constraint.
  - Database constraints deferred due to risk of locking database. Continue with inclusion of orphans on admin index displays, and manual clean up.
- [x] Revisit the roles policy test. The roles policy is now using the role context from the controller, need to factor this into tests.
- [x] Roles policy is delegating to resource policies for resource instances. Tests need to consider this.
- [x] Ensure select for role names does not include restricted roles unless current user has app_owner role.
- [x] System tests for all resources.
- [x] Model tests should include test of enums.
- [ ] Complete workflows with admin and no project selected.
- [ ] Complete proper ordering by switchboard tag and serial for circuits.
- [x] Update index view header lines.
- [ ] Custom 404 not found error page. E.g. Case where admin deletes a record than uses browser back button.
- [ ] Translation of html5 messages on required fields. Alternatively, suppress html 5 and use client side js.
- [x] Complete discipline system tests.
- [ ] Complete swatch system tests.
- [x] Complete switchboard controller test.
- [ ] Complete cable system tests for from and to after switchboard, demand, and circuit tests are working.
- [x] Use of button text for new and edit forms is mixed. Standardise on create for new, update for edit.
- [ ] Demand form live update of calculated values not working.
- [ ] Workflow for cable types with no current project.
- [x] Refine the collapsibles component to retain state after refresh operations (e.g. sorting links with ransack). Make a generalised solution, maybe use turbo.
- [ ] Fix the page size js controller.
- [ ] Write thorough tests for the tag parser and builder.
- [x] Cable types routing should be nested under projects.
- [ ] Cable types controller should be revised to suit nesting and protect against current project setting.
- [ ] Add searching and sorting for from and to fields in cables index.
- [ ] Expand tagable and scaffold generator tests to include all types and options.
- [ ] Improve system test template for scaffold generator.
- [ ] Scaffold generator check for valid module names is not working correctly.
- [x] Verify if two set of routes are really needed for tagables.
- [ ] Review all use of the method underscore. It apparently is not aware of the OS and uses '/' as the separator. Use File.join wherever appropriate.
- [ ] Fix module generator to use nested parent modules.
- [ ] Provide a means for admins to edit tags to remove broken links to tagable.
- [x] Add tagable controller checks to ensure discipline belongs to current project.
- [x] Cable factory begets discipline, project, then cable_type, but cable_type begets its own project. Should inherit from cable factory.
- [ ] Add model tests for read only attributes - documents, tags.
- [x] Review security of all controllers wrt injection attacks.
- [ ] Check that usage of accepts_nested_attributes_for is correct for tagable concern.
- [ ] Fix previous and next functionality in tagable navigation, and generalise it for non tagables. All models next and prev should only look inside policy scope. At present can raise forbidden.
- [ ] RBAC still has anomalous behaviour when resource wide roles are applied. Scope will include all projects, and allow selection of any project as current, but accessing the project without a specific role will result in forbidden. Either block resource wide roles or implement them in policies.
- [ ] Clean up responsive views - test all on simulator.
- [x] Issue policy has been removed. Assess whether it is required or just use document policy, like circuits.
- [x] Fix update test in tag system test.
- [x] Fix error in doc_types system test (edit).
- [ ] Refactor cable and cable type system tests after restructure to core.
- [ ] Fix error in discipline system test where the test seems to be building new disciplines.
- [ ] Write a test for collapsible on attribute rather than association (specifically discipline prefix schema).
- [ ] Decide what to do about deletion of data. It is affecting many aspects of the architecture.
- [ ] Complete demand system test after refactor.

## Refactoring Opportunities

- [x] Improve role and permissions implementation and workflow.
- [x] Refactor models to include a universal "label" attribute to be used when presenting polymorphic associations.
- [x] Refactor projects controller with improved workflow.
- [ ] Add type checking with Sorbet or RBS
- [ ] Implement caching for frequently accessed data
- [x] Upgrade to Rails 8 (Completed in rails8 branch)
- [x] Refactor electrical policy classes (CablePolicy, SwitchboardPolicy, MotorPolicy, LightCctPolicy, SocketCctPolicy) to use a shared concern or base class to reduce code duplication
- [x] Refactor all views to use pundit policy checks.
- [x] Change terminology and implementation from project owner to project manager.
- [ ] Refactor projects controller and application controller setting of current project: `def after_sign_in_path_for(resource)to use app/controllers/concerns/current_project_concern.rb to reduce code duplication.
- [ ] Tags:
  - [x] Refactor tag 'description' to 'service'.
  - [x] Add location attribute to tag, remove from all tagables.
  - [ ] Add parent/child capability.
- [x] Cable types:  
  - [x] convert core material to enum.
  - [x] convert insulation material to enum.
  - [x] add volt rating enum.
- [ ] Motors:
  - [x] convert motor type to enum.
  - [x] convert frame size to enum.
  - [ ] build a ruby structure for ingress protection, convert ingress protection to this type.
- [x] Redesign tag module:
  - [x] builder/parser model for each discipline which creates the string according to the required format, and can parse the string back into the components.
  - [x] provide default format for each discipline, e.g. isa5.1
  - [x] add next/previous functionality
  - [x] add colour code by discipline
- [ ] Look at use of hover on buttons, and use turbo to prevent page refresh.
- [x] Improve implementation of Discipline model, including translation. Consider using constants hash for each project.
- [ ] Refactor colour system to use CSS variables.
- [ ] Abstract ingress protection functionality so it can be reused by instrument module.
- [ ] Change all delete links to use turbo to prevent full page refresh.
- [ ] Revise index views to use turbo for ransack searches.
- [ ] Replace devise views with bespoke views in the style of the rest of the application.
- [ ] Add user profile info.
- [x] Refactor RBAC system with functional roles limited to project scope, and project admin roles.
- [ ] Refactor all controllers to use the preferred safe params expect rather than require.
- [x] Refactor test helpers to minimise code duplication, and simplify generation of new models.
- [ ] Improve forbidden error logging messages, include user. Consider automatic sign out.
- [ ] Abstract controllers for project linked models, similar to tagables controller.
- [ ] Add catalog required roles in disciplines, to allow different role for cable types and doc types, etc.
- [ ] Refactor cable and cable types to be core module available to electrical, instruments, telecoms (any module). Should belong to discipline.
- [ ] Index views should preload permissions and not check every row.
- [ ] Scaffold generators should include enum configuration, or build a separate generator.
- [ ] Include a valid value for fields in generators args.
- [ ] Consider whether the same improvement applies to demand.
- [x] Remove unnecessary namespacing within electrical module naming, e.g. switchboard has many electrical_circuits. Switchboards can refer to circuits, and circuits can refer to switchboards, without the module prefix.
- [x] Transition documents to discipline nested.
- [x] Transition cable types to core module, discipline nested. This should allow other disciplines (instrument, communication) to create appropriate cable types.
- [ ] Revise index views to get credentials once and use for links, for all resources where the credentials are not granular, which would be most everything that is discipline nested.
- [x] Refactor model translations with count.
- [x] Revert activerecord translations to convention with / instead of . key for namespaced models.
- [ ] Rename project change module to change management.
- [ ] Set up ransack to sort on translated attributes where relevant.
- [ ] Add a prefix breakdown drop down on tags show view.
- [ ] Use scopify to simplify setup for role assignment views.
- [ ] Refactor show views in style of documents, include generator templates.
- [ ] Decide on a standard clear presentation for booleans in show views, add it to show view for circuits, and add it to generic tests and generator templates.
- [ ] Prettification.
- [ ] Refactor collapsible component to use only stimulus js.
- [ ] Consider expanding scope for models to include all projects for which user has a role.
- [ ] Migrate i18n translations to a database system rather than YAML.
- [ ] Refactor documents to normalize discipline: remove fk and associate discipline through doc_type.
- [ ] Ditto cables: remove fk and associate discipline through cable_type. At the same time, sort out a decent label and add unique constraint on code.
- [ ] Refactor show views using standardised attributes helper.

## Potential Features

- [ ] Implement copy from other project
- [ ] Implement bulk import/export
- [ ] Data revision management
- [ ] Customize devise users:
  - [ ] Add policy for users
  - [ ] Allow users to self register through devise, edit their own profile and user name, email, password.
  - [ ] Insert an admin approval in the confirmation process
  - [ ] Disable destroy, because the [future] change history will have links to users making changes. We may need to historise user name changes as well, that's a future problem. The revision management system may well include some sort of active/inactive status features.
- [ ] Customize error trapping:
  - [x] Customize error trapping for Pundit::NotAuthorizedError
  - [ ] Customize error trapping for unknown format
  - [x] Customize error trapping for forbidden
- [ ] Improve locale setting, and include language/currency/flag in locale selection. Include regions with fallback to language for most translations.
- [x] Develop an application colour theme set. Consider discipline colour coding, also need to consider module colour coding.
- [ ] Build an IP55 object to allow fully flexible reusable IP code generation.
- [ ] Allow projects to add role names.
- [ ] Add a generator for scaffolding nested models.
- [ ] Add a "locator" so accessing index view from show view centres the index on the present record.
- [ ] Add a clear search button for index views. Add hover title for search button.
- [ ] Add highlight to search results for all index views (refer projects).

## Architecture Considerations

- [x] Move Electrical to a module or namespace.
- [x] Nest routes for project related resource under projects to improve security around assignment to other than the current project.
- [x] Nest tag, document resources under disciplines.
- [ ] Move cable and cable type back to core, as they are shared by electrical and instrument disciplines, also communications.
- [ ] Move document issues to change module, generalise so it can be used for other entities (polymorphic).
- [ ] Plan for database scaling as data grows

## Notes

- [x] Keep backward compatibility during the Load → Demand transition
- [ ] Consider adding performance benchmarks for critical paths

## Glossary

Resource: In rails, resource usually refers to an abstracted model. In this application, resource more often refers to an abstracted tagable model. Context should clarify which meaning is intended.
Record: Resource instance. Used very specifically internally in Pundit.
