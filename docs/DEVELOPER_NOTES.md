# Developer Guidance

1. Read [Readme](../README.md), it is the primary documentation for installers and users. It explains the application's capabilities. [TODO: update readme]
1. Read [DOCUMENTATION_PREFERENCES](DOCUMENTATION_PREFERENCES.md), it explains the available documentation for the application and how to use it.
1. Read [ROLES_AND_PERMISSIONS](ROLES_AND_PERMISSIONS.md), it explains the role based access control (RBAC) system, one of the pillars of the application.
1. Read the following sections of this document:
   - AI Integration
   - KISS Principle Guidelines
   - Implementation
   Other sections can be skimmed until needed:
   - Known Issues
1. The backlog (development checklist, technical debt, refactoring opportunities, potential features) is tracked in the project's GitHub issues, not in this document. The pre-GitHub version of those lists is archived in [retired_check_lists.md](retired_check_lists.md) for historical reference only.

## Application Objective

This application provides a unified approach to generating and maintaining the records associated with an engineer, procure, construct and operate project. The fundamental premise is to have a single source of information for all records available and readily accessed from anywhere it may logically be required.

The application caters for various user scenarios, including:

- design and execute team such as a constructor, using a shared website app.
- engineering design service for multiple clients, using a shared website app.
- application installed in house for a single client.

## AI Integration

This project has used more than one AI coding tool over time. AI can assist with repetitive tasks, can advise on coding conventions, can research the internet for use cases, and can assist with debugging. AI should not be relied upon when making fundamental design and architecture decisions.

The operational rules an AI must actually follow live in a file or files specific to the tool. This is a fast changing technology so the guidance should be checked before using. [CLAUDE.md](../CLAUDE.md), not here - this section is background and day-to-day practice, not a second copy of the rules themselves.

### Developers Using AI

#### Cascade

1. Cascade reads all contents in .windsurf/rules at the commencement of each session. Within rules, fundamentals.md directs it to read this document.

#### Claude

1. Claude Code reads [CLAUDE.md](../CLAUDE.md) automatically at the start of every session, which in turn points it at this document, `docs/DOCUMENTATION_PREFERENCES.md`, `docs/TESTING.md`, and `docs/ROLES_AND_PERMISSIONS.md`. A different AI tool won't necessarily do this on its own - point it at the same documents directly.
1. Let a tool consult whatever persistent memory it maintains rather than re-deriving project context from scratch each session.

### Documentation Maintenance

- These guidelines and requirements evolve over time.
- Any changes should be reflected in the documentation.
- When modifying role permissions or access controls, ensure both [ROLES_AND_PERMISSIONS](ROLES_AND_PERMISSIONS.md) and the corresponding policy files are updated.

## KISS Principle Guidelines

The project follows the KISS (Keep It Simple, Stupid) principle with these priorities:

1. **Minimal Viable Features First**:
   - Implement only requested features
   - Avoid adding unrequested functionality
   - Keep initial implementations simple and focused

1. **Testing Foundation**:
   - Ensure all tests pass before adding new features
   - Maintain test coverage for core functionality
   - Focus on stable, working features over feature completeness

1. **Incremental Development**:
   - Build a solid foundation before adding enhancements
   - Get approval for each feature before moving forward
   - Keep pull requests and changes small and focused

1. **Focus**:
   - Application functionality is always the priority
   - Format and presentation should be deferred until core functionality is stable
   - Avoid premature optimization or over-engineering

1. **Code Review Guidelines**:
   - Question any added complexity
   - Challenge features that weren't explicitly requested
   - Prefer simple, maintainable solutions over complex ones

## Implementation

### Application Structure

The application has a core structure encompassing Users and the associated access control system, Projects, Disciplines, Tags and Documents. Further functionality is encapsulated in modules, which correspond to engineering disciplines.

Only one level of module nesting is envisaged, however some features have provisioned for future sub-modules.

Refer to [ROLES_AND_PERMISSIONS](ROLES_AND_PERMISSIONS.md) for details on the RBAC system.

#### Projects

Projects are the top level resource of this application. Projects are "ring-fenced" for security, so users are always working on their current project. Users with access to more than one project can copy from one to the other. [TODO: not implemented yet]

#### Disciplines and Modules

Disciplines are used to group engineering objects, and associate them to functional requirements. Each project has disciplines which can be selected from a core set including instrument, electrical, mechanical, etc. Core disciplines have associated modules, which provide the code for discipline specific elements. Projects may add bespoke disciplines, but these will have no linked module for functionality.

Modules keep the app's file structure manageable.

#### Tags

Engineering design elements require a tag to be assigned. Tags are used to label design elements, and link them to their own data, as well as to other elements, to documents, assets and other functionality. Tags belong to a discipline, which determines their available prefixes, via the prefix_schema attribute.

#### Tagables

Tags can have a "tagable" model attached, which extends the information linked to the tag to include the specific information relevant to the type of element. For example, a motor and a cable have different information requirements, so the database needs to have a different table for each, but they share the structure of the tags table. Each of these models is known as a tagable model. All tagables are grouped into modules which associate them to the correct discipline.

#### Documents

Documents are used to manage and control the issue of information on a project. The document model is located in the core application.

Each discipline has its own set of document types. A document must have a document type, which determines the discipline to which it belongs, as well as the associated workflow when issuing the document.

Documents can be generated from the application database, or stored in a content delivery network from files uploaded by users.

[HOLD At present, no repository is included, only a document register].

#### Change Management

TBC

#### Import

Bulk import of spreadsheet data (CSV, Excel `.xlsx`/`.xlsm`, OpenDocument `.ods`) is provided by a generic framework, not a one-off feature per model. It is optional - only add it to a model where bulk loading is a real user need.

- `Import::Base` is the abstract superclass every importable model's plugin extends. It provides the shared wizard mechanics: spreadsheet reading (via `Import::SpreadsheetReader`, any supported format), column-mapping suggestion, dry-run row building/validation, and deferred/self-referential reference resolution (e.g. a Tag's own parent reference).
- `Import::Committer` performs the actual commit once a batch has been reviewed, inside a transaction. A generic `InvalidRowsError` rescue means an unexpected per-row save failure surfaces as a friendly re-render rather than a raw 500 - see Error Handling below.
- `Import::BatchesController` drives the shared wizard: upload -> (optional) worksheet selection -> column mapping -> dry-run review -> commit. A model's own controller only needs an entry point (`import`/`create_import` actions), added via the `Importable` concern.
- Two kinds of model can be imported:
  - **Discipline-resource models** (Tag, Document, DocType) import directly - each row becomes a new record.
  - **Tagable models** (Motor, Heater, etc.) import via `Import::TagableBase`, which never creates a Tag - it only *attaches* to an already-persisted, unassigned Tag by natural key (full_tag). Expected workflow: bulk-import the Tag register first (`Import::Tags`, with `tagable_type` set, left deliberately unassigned), then bulk-import the type-specific detail columns, which resolve and attach to those tags. Optional Tag-level columns (Service, Stage, Location, Tag Notes) can also be set in the same pass, without ever overwriting an existing value with a blank cell.
- New model support is added via the `project_assistant:import` generator (`--tagable` flag for tagable models), which scaffolds the importer service, view, locale entries, index-button injection, and starter tests - the same "generator first" convention as the scaffold and tagable generators.
- Bulk import is authorised the same way the single-record path already is (e.g. `TagPolicy#create?` for tagables) - it is not a separate authorization story.

### Internationalization

The application has been designed for international use from the outset.

- All user facing text is provided with translations for all implemented languages.
- To date, the only need for translation of database content identified is for discipline names. Further content translation is included in the potential features list below.
- The application uses the rails-i18n gem to assist with internationalization. This gem provides translations into many languages for the core rails features, including model validation, database errors, time and date functions, currency, etc.
- For reference, a copy of the en version of the translations is saved in [config/locales/rails-i18n gem en for reference/en.yml.ref](../config/locales/rails-i18n%20gem%20en%20for%20reference/en.yml.ref). This file is not used in the application, it is simply a copy of the en.yml file that is provided by the rails-i18n gem. Check in this file if you are not sure whether a translation is already provided, and *avoid duplicating core translations* if possible. Also note that not all language files include all translations! It is a community work in progress...
- The locale setting follows the basic guidelines in [Rails Internationalization (I18n) API section 2.2](https://guides.rubyonrails.org/i18n.html#setting-the-locale-from-url-params).
- Changing locale is available in the layout header via a drop down menu.
- The storage of translation files is detailed in the [INTERNATIONALIZATION](../config/locales/INTERNATIONALIZATION.md) document.
- In brief: a string rendered by one specific view via the implicit `t(".key")` shorthand belongs in `en.views.yml`, keyed by that view's own path - this applies to any view directory, not just ones backed by a full CRUD model (e.g. `roles:`, `errors:`, `import:` are all non-model view directories keyed this way). A string raised or set from non-view Ruby code (controller flash messages, service/model exceptions) with an explicit scope belongs in `en.yml` instead, grouped by subject rather than view path. See [INTERNATIONALIZATION](../config/locales/INTERNATIONALIZATION.md) for the full rule and worked examples.

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

- In this application, models correspond to database tables. For example, there is a tags table holding the data for the class Tag.
- Every tagable type has its own model.
- Model classes include all logic pertaining to the object.
- Model classes should include custom validations where required. Custom validations must include i18n translation of custom error messages.
- All resource models should have a label method, which is used to present a human readable, non language specific identifier, preferably unique, for the model. This can be simply a reference to another attribute, or a combination of attributes. It will be used in views as a card header, link id, etc.
- All resources should have a long label method, which includes a parent identifier as well as the instance identifier. This will be used for view headers.

#### Controllers

CRUD operations refer to the four basic functions of persistent storage in computer programming: Create, Read, Update, and Delete. These operations are essential for managing data in databases and applications, allowing users to add, retrieve, modify, and remove data as needed.

- Controller classes include logic for performing CRUD operations on the object.
  - Controllers are responsible for controlling access, by implementing the RBAC system.
  - Controllers are responsible for setting variables for the view, including select options that are derived from data.
  - Controllers are responsible for providing the user with feedback via an appropriate flash message after every operation that modifies content.

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

In addition, a card partial should be provided for collapsible view on pages where the model is associated:

- `_card`

- All views shall provide a page title which appears on the browser tab, which includes the view and the model name.
- Index and show views shall have a header line which includes the header and a standard set of navigation buttons.
- The index header shall specify whether the index is for project, discipline, or all projects.
- The show view header shall include the resource model name, the record's long_label, and optionally a title or service description.
- The new view header shall include the scope where the resource is to be created e.g. discipline label.
- The edit view header shall include the resource's long_label.
- Navigation buttons for index and show views shall include "return" index or show links to the higher level views, located to the left of the header.
- Navigation buttons for show views shall also include previous and next buttons, located left and right of the header.
- Index views shall also include new "action" button to the right of the header, conditional on user permissions.
- Where a model supports bulk import (see the Import section below), an Import "action" button should be included alongside the new button, also conditional on user permissions. This is optional - only importable models need it.
- Show views shall also include edit, delete, and new "action" buttons to the right of the header, conditional on user permissions.
- Title and header shall be translated using a `views.yml` file in the locales structure, see [INTERNATIONALIZATION](../config/locales/INTERNATIONALIZATION.md).
- Views should not include complex logical processing.
- Views should use the helpers in [view_helper.rb](../app/helpers/view_helper.rb). These helpers standardise the presentation of attributes in show and form views. Read the code to know what arguments are expected.
  - Show views can display most attribute types using `show_attribute`.
  - Forms can present most field types using `form_field`.
  - The helpers ensure that attributes labels are translated consistently.
  - The :enum_translated type ensures translation of enum options when translations are available.
- Show views should use the shared partials [_association](../app/views/shared/_association.html.erb) and [_children](../app/views/shared/_children.html.erb) to include collapsible cards with associated data.
- Conditionals should be controlled by pundit policy calls where applicable.
- Conditionals may also use presence or otherwise of variables set in the controller.
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

#### Bulk import row errors

- These arise during the spreadsheet-import wizard (see the Import section above) - a batch of rows, each independently valid or invalid.
- Per-row problems (missing required column, invalid enum value, reference not found, etc.) are shown in a review table before commit, with valid/invalid counts and an option to skip invalid rows and import the rest.
- `Import::Committer::InvalidRowsError` covers a different case: an unexpected failure *during* commit itself (e.g. a race condition - see `Import::TagableBase#after_commit_row`, which re-verifies a resolved Tag is still available immediately before linking it). This is rescued in `Import::BatchesController#commit` and rendered as a friendly re-render of the review step, not a raw 500.
- Tests should cover both: the per-row dry-run validation table, and a forced commit-time failure (e.g. a race condition) surfacing cleanly.

#### Security breach attempts

- These are trapped forbidden operations that should not be possible using normal workflows.
- They are probably injected HTML or JSON requests in an attempt to defeat the permissions system.
- Controllers need to be designed carefully to ensure all user provided data is sanitized. Frequent use of enum attributes, length validation, strong parameters, and explicit type checking can help prevent these attacks.
- When a controller detects invalid parameters, custom error class ConflictError should be raised, with a message key specific to the actual error.
- ConflictError is intentionally reserved for clear hacking/injection attempts only. Never raise it for anything a normal user workflow could trigger, including race conditions - those belong under "User data entry errors" above, or a dedicated rescue of their own.
- ConflictErrors are handled in ApplicationController by rescue_from ConflictError and method handle_conflict.
- handle_conflict is designed to log the error with the message code, render the custom /409 conflict page, and log out the current user, since a genuine hacking attempt warrants it. The logout step is currently deferred (not implemented): some existing ConflictError call sites can still be triggered by data races rather than a genuine attack, and logging a user out for a race condition would be worse than the problem it's meant to solve.
- TODO: audit existing ConflictError raise sites for any that a normal user (not an attacker) could trigger via a race condition or other non-malicious path, and fix or reclassify them. Only once that audit is clean should the logout step be reinstated.
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
  - "file-earmark-arrow-up" class "-primary" for import buttons (bulk spreadsheet import - optional, see the Import section below)
  - "pencil" class "-warning" for edit buttons to open a form
  - "trash" class "-danger" for delete buttons to delete the object
  - "search" class "-primary" for search buttons on views
  - "x-square" class "-warning" for Discard Changes buttons on forms
  - "save" class "-primary" for save (create or update) buttons on forms
- Flag icons are used to assist with locale/language selection.
  - The gem rails-icons is used with the library 'flags' to provide the icons.
  
## Known Issues

### Tagable Validation - fixed

It is possible to create multiple tags referencing the same tagable element, despite the validations in place.

### Pagination - fixed

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

## Glossary

Resource: In rails, resource usually refers to an abstracted model. In this application, resource more often refers to an abstracted tagable model. Context should clarify which meaning is intended.
Record: Resource instance. Used very specifically internally in Pundit.
Register: This is Claude's name for the discipline list in Constants.
