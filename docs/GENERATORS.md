# GENERATORS

## INTRODUCTION

The application Project Assistant (PA) provides shared functionality for all types of engineering design elements within a project. The tag is the linkage for all pertinent information about the element. The name 'tags' originated because identifying tags containing this core information were physically attached to the element. In this application, the tag model contains the core information about the element that is required for all tags across all disciplines. Detailed information about each element is stored in a tagable model, explained below.

### Tags

The tag model has the following database attributes:

* tag_number: it is a compound structure of prefix, serial number, and optional suffix. This structure is not universal but very common in engineering practice.
* service_description: a brief description of the function of the element.
* discipline: the engineering discipline to which the tag belongs.
* stage: the stage is a mechanism to allow grouping tags within a project. It can be used at the project's discretion. E.g. a project may use stages for different phases of construction.
* location: the physical location field also allows grouping of tags.

The tag model provides the following functionality:

* full_tag: the prefix, serial number and suffix are combined to form the full tag, as a virtual field within the database. This enables direct searching of tags by full tag.
* loop_id: This is another virtual field, specifically intended for instrument tags grouping, comprising just the measured value (prefix first character) and serial number.
* prefix_parts: this method parses the prefix into its constituent parts, based on the prefix schema defined in the discipline.

### Disciplines

* Disciplines are unique within a project, and provide the connection from a tag to its project.
* Disciplines are used to group tags, documents and other elements.
* Disciplines provide built in functionality, by linking to modules (see below).
* Discipline related functionality includes:
  * Specify the schema of the tag prefixes in the discipline.
  * Specify the schema for document type codes.
  * Specify the colour swatch for forms and tables.
  * Specifiy required roles for the RBAC system.
* Ideally, only standard disciplines would be required. These are defined in the constants system, which are copied when setting up a project.
* However, it is possible to create custom disciplines, as required, and these can be copied from standard disciplines.
* [HOLD FOR UPDATE Discipline names are one of the very few parts of the application where translation of the application generated user facing text is not presently provided. This is because translation would be required for the database content, not the configuration. Until a content translation solution is implemented, custom disciplines are one option for projects to provide translated discipline names which can link back to core discipline functionality by their module connection.]

### Tagables

* The next level of information for tagged elements is referenced in this application as the tagable data. This is not engineering terminology, it is Rails conventional naming for delegated types (also for polymorphic associations, of which delegated types are a special case). Delegated type is a Rails database concept allowing disparate models to share common attributes.
* A note about spelling: Many sources claim that the correct spelling is taggable, including material written by DHH himself. However, tagable is the convention rails uses for a delegated type from tag, so we have gone with that rather than override convention.
* Different design element types will require different information. E.g. within the electrical discipline, a motor will require different information than a switchboard. Therefore, the application includes a Motor model and a Switchboard model, but those models both include tagable, so they have all the functionality of the tag model as well.
* The tagable model can be considered as the datasheet for the element type. As such, the tagable model should incorporate all information required to specify the element for purchase, with exceptions for electrical and process modules, which have further delegated types appropriate to their needs.
* Electrical tagable models all require the same associated load data for analysing the network. This is stored in a demand model (it should be load but load is a core keyword in Ruby so demand has been chosen for internal representation - users should only see "load"). Demand also delegates to the tagable models as demandable, so electrical models are both tagable and demandable.
* [TODO] Process module under construction.

### Tagable Types

* As the application grows to cover more different design elements, the number of tagable types will grow significantly.
* Although the underlying models for different types of elements may not have much in common, the user actions associated with creating, editing, viewing and deleting them are very consistent.
* To avoid repetition of development effort, the tagable models have been abstracted where possible.
* Abstraction has been achieved to a large extent for controllers, policies, and their associated tests.

### Modules

* To manage the large number of tagable models that are required, they are stored in sub-folders of the main application.
* In Ruby on Rails terminology, the sub-folders become Ruby modules.
* Each core discipline has an associated module, which is also the name of the sub-folder.
* The module provides a "namespace" which is Rails terminology, meaning that names within the module must be unique, but can be the same as names in other modules.
* A generator is provided for creating all the file structure and edits required for a new module.
* Modules can be nested as sub-modules. While most of the generator code uses `class_path` and other `NamedBase` variables that cater for multi-part module names, this is not tested and will probably fail with nested modules. This is accepted as the app at this stage has no requirement for that level of complexity - sub-modules do occur in the generators code, but not in the main application structure. Any future development in this direction will require refactoring the module and scaffold generators.

### Generators

* A generator is a Rails feature that allows the developer to rapidly build an application based on repeating patterns of files and folders.
* The main benefits of using a generator are:
  * Consistent file structure and naming.
  * Correct initial file content.
  * Greatly reduced development time.
* Rails provides a number of generators for common tasks, such as creating a model, controller, or migration. These are typically very primitive, providing only bare bones of an application.
* The Rails scaffold generator is more comprehensive, providing a full suite of model, migration, controller, routes, views and associated tests.
* This application's bespoke generators build models and infrastructure that meets the application standards and requirements. 
* The generators are namespaced in the /lib folder under the application name ProjectAssistant. This prevents generator name clashes with other gems and rails standard generators.
* Generators comprise a sequence of instructions to create folders, create files from templates, or edit files. (They can also run migrations and all sorts of marvellous things, but the app's generators to date don't use these features.)
* Rails provides the facility to reverse a generator's action using the rails destroy command. Some points to consider about destroy:
  * Destroy bases its actions on the current generator file, so cannot properly destroy actions that are no longer in the generator, if it has been edited.
  * If the generator included a migration (whether run inside the generator or manually), be sure to rollback the migration before running destroy.
  * Destroy is not infallible, particularly on complex generators like those used in this app. Be sure to do a manual check after running destroy.
  * Destroy does not reverse file edits, or file creation by other than templates.
* Because `destroy` is unreliable for this app's generators (see above), the safe way to trial a generator and be able to cleanly retry is a git-based checkpoint, not `destroy`:
  1. Before running the generator, commit whatever you want to keep (hand corrections, a definition file, etc.) as a checkpoint:

     ```bash
     git add -A
     git commit -m "checkpoint before generator trial"
     ```

  2. Run the generator (`--pretend` first if you want to preview before committing to it for real).
  3. To revert back to the checkpoint, restore tracked files with a hard reset, then remove the generator's untracked output interactively rather than with a blind `-f`:

     ```bash
     git reset --hard HEAD
     git clean -i app/ test/ config/ db/migrate/
     ```

     `git reset --hard HEAD` only touches tracked files and resets them to the exact checkpoint commit - safe, since there's no merge involved and nothing is lost as long as the checkpoint has everything you want kept. **This also means: commit everything you want to keep before running it, including edits unrelated to the current generator trial - it resets the whole repository to the checkpoint, not just the files the trial touched.**

     `git clean -i` (interactive mode) lists every untracked file/directory under the given paths and lets you choose what to remove, rather than deleting blindly. Scoping it to the directories a generator actually writes to (`app/ test/ config/ db/migrate/`, adjust as needed - the module and scaffold generators create new, untracked files under `config/constants/` and `config/locales/` too, not just `app/`/`test/`) also means it physically can't touch unrelated untracked work sitting elsewhere in the repo.
  4. **Never run `git clean -f`/`-fd` without either `-i` or a prior `-n` dry run, and never run it unscoped (no paths) across the whole repo.** Untracked files have no git-based recovery path at all once deleted this way - not even `git fsck` can find them, since they were never staged.
* This procedure also works for correcting bugs found in a generator itself: commit the fix, retry the generator, and reset-and-clean again if the output still isn't right - without needing `destroy` at all.

## MODULE GENERATOR

### Specification

* This generator will create the folders, files and edits required to add a new module.
* Specific requirements
  * The generator itself is reasonably self documented, refer to `lib/generators/project_assistant/module_generator.rb`.
  * Here is a more detailed specification:
    * The generator expects a single command line parameter, which it receives as the variable `name` via its NamedBase inheritance. This is the name of the module to be created.
    * The generator first checks for the existence of the folders it is about to generate. If any of the folders exist, the generator will provide the user with the option to abort, as continuing will clobber any existing content. Abort is overriden in the test environment.
    * The folders created are:
      * `app/models/#{module_name}`
      * `app/controllers/#{module_name}`
      * `app/helpers/#{module_name}`
      * `app/policies/#{module_name}`
      * `app/views/#{module_name}`
      * `test/factories/#{module_name}`
      * `test/models/#{module_name}`
      * `test/controllers/#{module_name}`
      * `test/helpers/#{module_name}`
      * `test/policies/#{module_name}`
      * `test/system/#{module_name}`
      * `config/locales/#{module_name}`
      * `config/locales/#{module_name}/#{locale}` for each locale in `I18n.available_locales`
    * The files created are:
      * from template `lib/generators/project_assistant/module/templates/module.rb.erb`, to provide the module table name prefix, and any other functionality the module requires at the top level:
        * `app/models/#{module_name}.rb`
      * from template `lib/generators/project_assistant/module/templates/base.rb.erb`, to provide shared functionality for all models in the module:
        * `app/models/#{module_name}/base.rb`
      * for each locale in `I18n.available_locales`, files with no content:
        * `config/locales/#{module_name}/#{locale}.#{module_name}.yml`
        * `config/locales/#{module_name}/#{locale}.#{module_name}.models.yml`
        * `config/locales/#{module_name}/#{locale}.#{module_name}.views.yml`
      * from template `lib/generators/project_assistant/module/templates/module.yml.erb`, to provide constants such as enum options for the module:
        * `config/constants/#{module_name}.yml`

    * The edits made are:
      * In `config/routes.rb`, the generator looks for a line containing `# INSERTION POINT 1 FOR MODULE GENERATOR` (in the discipline-nested routes section) and a line containing `# INSERTION POINT 2 FOR MODULE GENERATOR` (in the project-nested routes section), and inserts an empty namespace at each:

        ```ruby
        namespace :#{module_name} do
        end
        ```

        This is a ready-made home for any non-tagable, module-namespaced model's own routes (for example `Electrical::CableType`), added later by the scaffold generator or by hand. Tagable models need no route changes.

      * In `config/constants/tagable.yml`, after the line `tagable:` the following comment line is added, as the placeholder to define tagable models in the module:

        `# #{module_name}`

### Usage

* The module generator is used as follows:
  * Run the generator with the following command:

    ```bash
    rails g project_assistant:module <ModuleName>
    ```

  * `ModuleName` should be provided as CamelCase but will be converted to snake_case for file names and CamelCase for class or module names within the generator.
* If prompted, it means the generator has found an existing folder, and will ask if you want to proceed.
  * If you are sure that the existing folder does not contain anything that needs to be retained, respond with 'y'.
  * If you are not sure, respond with 'n'. The generator will abort.
* The generator will create the folders, files and edits required to add a new module. The generator output will show the files and edits created.
* The module generator creates a locale file folder, with files for each locale for models, views, and general translations. These files have their namespace keys set to empty hashes.
* The generator creates a base class for the module, which is used as the parent class for all models in the module. This base class is used to define shared behavior for all models in the module.
* The base class defaults the colour swatch to "app_theme". Set as required.
* The base class defaults the module discipline to the same name as the module. This is used in testing.
* The base class defaults label and long_label methods to inherit from tag. If the module is not used for tagable models, this should be changed to something suitable, or removed.

## SCAFFOLD GENERATOR

A scaffold generator is provided to build a model with consistent structure and content matching the rest of the application, and facilitate rapid deployment. Tagable models are not built by this generator. Use `project_assistant:tagable` for those (see [Tagable Generator](#tagable-generator)).

The generator itself is reasonably self documented, refer to [scaffold_generator](../lib/generators/project_assistant/scaffold_generator.rb).

### Specification

#### Command Line

The generator shall be invoked using the rails generate command. The command line must include the generator name `project_assistant:scaffold`, and the model name as a Ruby class specifier in CamelCase - either bare (e.g. `Swatch`, for a core, non-namespaced model) or module-prefixed (e.g. `ChangeManagement::Request`). A list of arguments for the fields to be created can either be provided on the command line, or read from a definition file. Definition files must be YAML or Ruby format. By using a definition file, more complex information is easier to read, check and edit than with a long unformatted command line. Saving the definition file to revision history is useful.

**Important - option order**: `--nesting` (and any other `--option`) must come **after** the field arguments on the command line, not before. When options are placed before the field list, Thor's argument parsing silently drops every field that follows - the generator runs, reports the right nesting, but produces a model with none of the requested fields, with no error at all.

If a `--definition=filename` option is specified, the generator will look in folder `lib/generators/project_assistant/scaffold/definitions` for a file name as specified, with extension `.yml` or `.rb`.

For a namespaced model, the module (and every level of a nested module) must already exist, with its associated folders and files in place, before running the generator - always use the module generator first to ensure that structure is ready. A non-namespaced (core) model has no such prerequisite.

Note on sub-modules: While most of the code uses class_path and other NamedBase variables that cater for multi part module names, it is not tested and will probably fail with nested modules. This is accepted as the app at this stage has no requirement for that level of complexity. Any future development in this direction will require refactoring the module and scaffold generators.

#### Nesting Options

The `--nesting` option selects the model's relationship shape, and drives several generated details at once: the association added to the model, the policy/controller concern it's built against, and whether/where a route gets inserted. Valid values:

* `none` (the default): a plain, non-nested model with no automatic association. No route nesting; the route is inserted at the top-level "Insertion point for non-nested routes" marker in `config/routes.rb`.
* `project`: adds `belongs_to :project`. Policy is `ProjectResourcePolicy`-based; controller includes the `ProjectResourcesController` concern. Route inserted under the project-nested routes section. Example: ChangeManagement::Request and other models are project nested.
* `discipline`: adds `belongs_to :discipline`. Policy is `DisciplineResourcePolicy`-based; controller includes the `DisciplineResourcesController` concern. Route inserted under the discipline-nested routes section. This is the shape most discipline-scoped, non-tagable models use (e.g. a model like `Document`).
* `tag` (not fully developed; will be built out when a model needs it): adds `belongs_to :tag`. Policy is `TagResourcePolicy`-based; controller includes the `TagResourcesController` concern. Route inserted under the tag-nested routes section. Use for a model that's linked to a tag but is not itself a tagable delegated type (e.g. `Electrical::Demand`).
* `document` / `issue` (not fully developed; will be built out when a model needs them): adds `belongs_to :document` / `belongs_to :issue` respectively. Route inserted under the corresponding nested routes section. Used rarely; verify the generated routes edit landed in the right place before relying on it, as these two nesting values are less exercised than the others.
* Tagable models are not built by this generator. Use `project_assistant:tagable` (see [Tagable Generator](#tagable-generator)).

#### Fields

The user shall specify the model's required attributes by providing a set of fields. Fields can be specified on the command line, or alternatively in a definition file.

When using command line input for fields, following the model name, all fields to be included in the model shall be listed with their type and options. Fields are separated by whitespace. Within a field specification, the name, type, and options are separated by colons with no spaces allowed.

When using a definition file for fields, the command line shall include the option: `definition=filename`. Note that the filename extension shall not be provided.

The accepted YAML file format is of the form:

```yaml
name: 
  type: 
  option:
  option:
```

Refer to [electrical_test.yml](../lib/generators/project_assistant/scaffold/definitions/electrical_test.yml) for an example of a YAML definition file.

The accepted Ruby file format is of the form:

```ruby
name: { type: :string, required: true }
```

Refer to [electrical_test.rb](../lib/generators/project_assistant/scaffold/definitions/electrical_test_rb.rb) for an example of a Ruby definition file.

Fields are given either on the command line or in a definition file, never both: the generator shall abort if `--definition` is given together with field arguments. Any `--nesting` option goes after the fields.

* Names must be valid ruby identifiers.
* Types implemented shall be the standard rails types, with custom additions for this generator as listed below.
* Standard rails column types are: `:string, :text, :integer, :bigint, :float, :decimal, :datetime, :timestamp, :time, :date, :binary, :boolean, jsonb`.
* The generator shall implement `:references` or `:belongs_to` types as associations between models. These should only be used on the belongs_to model. They shall add the foreign key field to the migration, and provide appropriate view links.
* The generator shall implement the custom `:enum` type to create an enumerated field. The generator shall set integer type in the migration, and shall create a framework for the enum in the model, views, and constants files for the module. The allowable values for the enum should be included as a list of keys as strings in the command line option, or in the definition file.
* The generator shall implement the custom `:enum_translated` type to specify an enumerated field (with translations). The generator shall set integer type in the migration, and shall create a framework for the enum in the model, views, and constants as for `:enum` type. In addition, the locales files for the module shall be edited with placeholders for the field name and option translations. The translations for the enum will need to be set manually after generation.
* "Flag options" don't require a value in the command line, their presence implies true and absence implies false. However, they do accept a valid boolean (true or "1", false or "0") as a value. When used in a definition file, a valid boolean is required to conform to the file's language.
  * The generator shall respond to the `:index` flag option. This is standard rails generator format. This option shall result in an index being added in the migration.
  * The generator shall respond to the `:uniq` or `unique` flag options, instead of `:index`. This option shall result in a unique index being added in the migration.
  * The generator shall respond to the `:required` flag option. This is not standard rails generator format but is less ambiguous than the `:null` option rails uses. It shall result in a presence validation in the model, and an associated model test. IMPORTANT: The `:required` option for association types is significant. With rails, :belongs_to defaults to required, but in the generator it will be set to optional unless :required is true.
* Value options require a value. In the command line, the option and value are separated by '='. In a definition file, the syntax must conform to the selected language.
  * The generator shall respond to the :valid option for all types. The value provided must be valid for the field's type. The value will be used to default the test factory, and also in controller tests.
  * The generator shall respond to the :keys option, but only for :enum and :enum_translated field types. The value shall be an array of strings. On the command line, there must not be any spaces between elements (space is the separator between fields). The array elements shall be used as the enum keys by adding them to the Constants structure. For :enum_translated type, they shall also be added to the model translation files.
  * The generator shall respond to the :precision and :scale value options, but only for :decimal and :float types. The values provided must be valid integers. The options shall be passed to the migration for :decimal types. They shall be passed to view helpers for display formatting.
  * The generator shall respond to the :units option, but only for :float and :decimal types. The value shall be coerced to string class, and passed to display helpers for formatting.
  * The generator shall respond to the :si option, but only for :float and :decimal types. The value shall be a valid boolean. The value shall be passed to display helpers for formatting.
  * The generator shall respond to the :step option, but only for numeric types :integer, :bigint, :float, and :decimal. The value must be a valid decimal. The value shall be passed to form field helpers for implementing the step option on number_field tags.

The generator shall first parse all arguments. If invalid names, types, or options are provided, a warning shall be issued listing the invalid arguments. The generator shall abort unless all names, fields and options are valid.

#### Folders

For a namespaced model, the generator shall create the views folder:
  `app/views/#{controller_file_path}`

#### Files

The generator shall create these files:

##### Migration

* A database migration file to build the database table with the requested fields:
  * `db/migrate/#{timestamp}_create_#{table_name}.rb`

##### Model

* A model definition file including:
  * a `belongs_to` for every nesting value except `none`
  * enum declarations for any enum fields
  * belongs_to association declarations for any `:references`/`:belongs_to` fields
  * presence validations for any required fields
  * uniqueness validations for any unique fields
  * ransackable attributes for searching and sorting all attributes
  * ransackable associations for any fields of type `:references`
  * `app/models/#{file_path}.rb`

##### Policy

* A policy file matching the nesting option's own policy pattern (see Nesting Options above):
  * `app/policies/#{file_path}_policy.rb`

##### Controller

* A controller file with the standard RESTful actions deferring to the matching `*ResourcesController` concern, and safe parameters set to the defined fields:
  * `app/controllers/#{controller_file_path}_controller.rb`
No helper file is created.

##### Views

* A full suite of views built from templates and the specified fields:
  * `app/views/#{controller_file_path}/_form.html.erb`
  * `app/views/#{controller_file_path}/new.html.erb`
  * `app/views/#{controller_file_path}/edit.html.erb`
  * `app/views/#{controller_file_path}/index.html.erb`
  * `app/views/#{controller_file_path}/show.html.erb`
  * `app/views/#{controller_file_path}/_card.html.erb`
  * `app/views/#{controller_file_path}/_header.html.erb`
  * `app/views/#{controller_file_path}/_row.html.erb`

##### Factories

* A factory file with fields defined (but no default values):
  * `test/factories/#{controller_file_path}.rb`

##### Model Tests

* A model test file with tests for required fields, unique fields and enum declarations:
  * `test/models/#{file_path}_test.rb`

##### Policy Tests

* A policy test file with setup, which defers tests to the matching resource_policy_test helper:
  * `test/policies/#{file_path}_policy_test.rb`

##### Controller Tests

* A controller test file with setup, which defers tests to the shared test-pattern helper matching the nesting option:
  * `test/controllers/#{controller_file_path}_controller_test.rb`

##### System Tests

* A system test file with template content, which defers tests to the shared system-test-pattern helper matching the nesting option:
  * `test/system/#{controller_file_path}_system_test.rb`

#### Edits

* The generator shall make the following edits:

##### Routes

* One `resources :#{plural_name}` line shall be inserted into `config/routes.rb`, at the nested-routes section matching the nesting value (e.g. `--nesting=project` inserts just before `end # discipline nested routes`), or at the "Insertion point for non-nested routes" marker for `--nesting=none`. If the model is namespaced under a module and that module has its own `namespace :#{module_name} do ... end` block already present in the target section, move the newly-inserted line into it by hand afterward for a tidier result - the generator itself always inserts flat, at the top level of the nesting section, not inside a module namespace.
* If the expected marker/section is not found, the generator shall log an error message.
* The generator shall provide a success message if the file edit is completed.

##### Constants

* The generator shall look for the file `config/constants/#{module_name}.yml` (or `config/constants/core.yml` for a non-namespaced model). If found, a key shall be appended for defining any required model constants. Primarily, these are expected to be enum key definitions.
* If the model has no enum fields, the key shall be given an empty hash value rather than left bare (which would error on intialisation).
* If any enum fields have been specified (either :enum or :enum_translated), the generator shall insert a key for each required field name, followed by the list of key values, each with numeric index:

```ruby
    #{field[:name]}:
      value0: 0
      value1: 1
      ...
```

   The generator shall issue a success message if the file edit is completed. If the file is not found, the generator shall log an error message.


##### Translations

1. For each locale in I18n.available_locales, the generator shall edit the model translations file (`config/locales/#{module_name}/#{locale}/#{locale}.#{module_name}.models.yml` for a namespaced model, or `config/locales/core/#{locale}/#{locale}.models.yml` for a core model). This shall be done by using the `models` key as a marker, inserting the model name following the key, with an entry for one and other (plural). After the `attributes` key, the generator shall append a line for each field, with the field name and a dummy translation of "#{field[:name].humanize}". If a field is type :enum_translated, additional lines shall be appended with the plural of the field name as a key, and a line for each key. Example:

    ```yml
    en:
      activerecord:
        models:
          ...
          change_management/request: "Change Request"
        attributes:
          change_management/request:
            title: "Title"
            reason: "Reason"
            duration: "Duration"
            durations:
              permanent: "Permanent"
              trial: "Trial"
              temporary: "Temporary"
            ...
    ```

    The help and errors sections shall not be modified, these must be done manually if required.

    The generator shall provide a success message if the file edit is completed. If the file is not found, the generator shall log an error message.

2. For each locale in I18n.available_locales, the generator shall edit the matching views translations file, appending the model name at the end of the file, with the standard actions translations. Example:

    ```yml
        requests:
          index:
            title:            "Change Requests"
            header:           "Change Requests Schedule for %{scope_text}"
          edit:
            title:            "Edit Change Request"
            header:           "Edit Change Request %{label}"
          new:
            title:            "New Change Request"
            header:           "New Change Request in %{scope_text}"
          show:
            title:            "Change Request"
            header:           "Change Request %{label}"
    ```

    The generator shall provide a success message if the file edit is completed. If the file is not found, the generator shall log an error message.

### Usage

#### Preparation

Usage is explained using the example used by the generator test, which covers all types and options. The generator can be run entirely from the command line, or using a definitions file. The choice is largely down to complexity of the target datasheet. Using a definition file provides the added benefit of recording the "starting point" in git history.

1. Before running this complex generator, it is strongly recommended to commit all changes to git, so there is a safe return point if things get messy. Generators can be partly reversed with destroy action, but this does not undo the edits made (in fact destroy repeats the edits), nor does it remove migrations because they are timestamped. The safest way for recovering is to use git.

2. The second and most important step is to make a list of all the model's attributes, determine their types, and record the options required. Include all the necessary fields required to specify items of the new type. Unless the model is very simple, it is recommended to use an editor to prepare either the command line or a definition file.

    * Field names must be valid ruby identifiers.

    * Each field requires a valid type, selected from:

      * string: use for short definitive text information, but always prefer an enum (see below) if the text should be constrained to accepted values.
      * text: use for descriptive information. The generator will not provide search or sort on text fields, though these can be added later if required.
      * integer and bigint: use integer for most applications, bigint for huge numbers. (Bigint is rails default for primary keys, but the generator handles associations separately.)
      * float: use for floating point numbers, typically engineering attributes that may be involved in calculations and span a wide range of values. Float values exhibit round off error. The generator provides :scale and :precision, :units and :si options for float type.
      * decimal: use for fixed point numbers, typically currency. Decimal values are precise to the specified precision and scale. The generator provides :scale and :precision, :units and :si options for float type.
      * [HOLD] [Date time fields not tested as yet.]
      * datetime:
      * timestamp:
      * time:
      * date:
      * binary: [HOLD] [Binary fields not tested as yet.]
      * boolean: use for switches. The form has a check box.
      * jsonb: use for additional user defined data fields, stored as JSONB in the database. The form provides a json editor defaulted to tree mode.
      * enum: use for selection options. This is not a standard rails type, it is used by the generator to create an integer field in the database, with drop down select in the form. The generator accepts an array of allowed values.
      * enum_translated: this is as for :enum type, but also with translations for the options. The controller generated will build translated option key lists for form selectors, and the views will present translations rather than keys or database values.
      * references: or belongs_to: use for associations. This type sets up the framework of a belongs_to association.

    * Fields may also have options. Options are "flag options" or "value options". Flag options are boolean, and their presence determines the value of the boolean. Value options are of many types, but they are specified as a key/value pair. Available options are:

      * Flag options:
        * :index: use this option to implement a database index. This will greatly improve search and sort operations.
        * :uniq: or :unique: use one of these options instead of :index, if the field must be unique. It will ensure uniqueness at the database level, as well as in validation. [TODO: allow scope to be provided with unique]
        * :required: use this option for fields that must have a value set. Use carefully, as a record cannot be saved if it has a missing required field, which may degrade the user experience.

      * Value options:
        * :valid is available to all types. The value provided must match the field type.
        * :keys is only available for :enum and :enum_translated field types. The value must be an array of strings.
        * :precision and :scale are available for :float and :decimal types. The value must be a valid integer. They correspond to rails' options of the same name, and for :decimal types are enforced in the database.
        * :units is only available for :float and :decimal types. The value must be a string. It is appended to the value in views.
        * :si is only available for :float and :decimal types. The value must be a boolean. When true, the show views will scale the value to an engineering value between 1 and 1000, and use the scale to add the appropriate SI prefix to the units.
        * :step is only available for number types (:integer, :bigint, :float, :decimal). The value must be a decimal. It is used for number fields on forms only. Use with caution with real numbers: the step option causes input to be rejected if it does not fall exactly on a step value.

3. Note that enum field option keys become class methods for the model, so have to be unique across the whole class, and may not include Ruby method names. "None" is an easy trap to fall into, but is a standard class method so cannot be used as an option. For this reason the generator adds the prefix option in the model definition.

4. The generator has dependencies, which should automatically be met if the module generator has been used for setting up the module (for a namespaced model). Refer to the module generator documentation to see what is expected, and check that all requirements are in place.

5. The generator uses [field_types.rb](../lib/generators/project_assistant/field_types.rb) to make assumptions on how to present the various field types. Only field types in `SEARCHABLE_TYPES` will have search fields on the index view. Only field types in `INDEX_TYPES` will appear in the index view. If these assumptions don't suit the model being generated, it is acceptable to edit `field_types.rb` temporarily, but ensure it is restored when complete. For minor differences, it may be easier to edit the generated scaffold after the run, but be aware of the dependencies: test files need to match the code files. If this is a regular occurrence, consider adding named versions of field_types.rb.

6. With all the fields ready, it's time to prepare the command line.

#### Command with Definition File

If you have prepared a definition file, the command line is of the form:

```bash
rails generate project_assistant:scaffold ChangeManagement::Request --nesting=project --definition=change_management_request
```

By convention, the file should be named as the snake case of the new model's class name, but this is not presently enforced. The generator will look for the file name provided, with .yml or .rb extension. YAML takes precedence if both are there.

#### Command Line Arguments

You can type the command directly into a terminal, but if you are building a large complex model, it may be worth typing into an editor first, and paste it from there into the terminal window. This way, errors are more easily corrected.

Here is the example command line tweaked using the generator test arguments:

  ```bash
  rails generate project_assistant:scaffold ChangeManagement::Request name:string:required:valid="Test_name" description:text:valid="Factory_generated_description" selector:enum:keys=["s1","s2","s3"] status:enum_translated:keys=["draft","published","archived"] sort_order:integer:index:valid=100 power:float:precision=4:units=m:si=true:valid=5.555 money:decimal:precision=5:scale=2:valid=1.55 switch:boolean birthday:date created:datetime flex_field:jsonb code:string:uniq parent:references owner:belongs_to:required=true --nesting=project
  ```

Note the limitations of the command line: no spaces allowed. This mainly affects string option values: you cannot have multi-word valid values. Also be sure there are no spaces in the enum value arrays. Note also the option-order requirement above: `--nesting` goes at the end, after every field argument.

#### Running the Command

If using guard for testing, it is probably better to exit before running the generator, as generation will create files that trigger lots of failing tests.

A reminder: commit work in progress to git (see above).

Run the generator command using the --pretend option (or simply -p) first. This will run through the generator checks and methods and report all the actions, without actually creating or editing files and folders. If there are errors in the name, nesting, or field specifications, they should get caught here. Inspect the output to ensure it is what you are expecting. When everything is clean, run the generator without the --pretend option.

#### Follow Up

1. If using guard for testing, it is probably better to exit before completing follow up, as some edits will trigger lots of failing tests.

2. Open the model file (in our example app/models/change_management/request.rb).

    * Check that associations are correctly defined for :references fields. The generator adds `belongs_to` statements, but no options. These must be added if required. The generator assumes that the referenced class is in the same module/sub-module as the generated model. Add the inverse relation (has_many or has_one) to the referenced model, then save and close that file.
    * Check that any required :enum and :enum_translated type fields are specified as enum with reference to the constants defining the field options.
    * Check that the fields with :required option have presence validations.
    * Add any other validations required, such as range limits, numericality, format, etc.
    * If the `ransackable_attributes` line is too long, split it after a comma for ease of reading.
    * Check that `ransackable_associations` meet requirements.

3. Open the module constants file (in our example config/constants/change_management.yml).

    * There should be a new key for the model (request: in our example)
    * For each enum field, there should be a line with the field name as key.
    * Indented under the field name, each option key should have a unique integer value.
    * Every enum option key becomes a class method on the model, so key names must be unique across all enums in the model. The generator adds the prefix: true option in the model definition, in order to ensure all methods are unique. 
      * Note this prefix only affects the class method names, it doesn't change the values that are displayed in forms or views.
    * Save the model file and the module constants file.

4. Open the default locale file for models (in our example config/locales/change_management/en/en.change_management.models.yml).

    * Check that the model translation and all field translations are included as expected. The translations have been defaulted using Rails' `humanize` method, but they can be edited as required.
    * For any enum_translated fields, there should be a key for the options as plural of the field name, and a line for each option. Again, the translations are defaulted using Rails' humanize method.
    * Edit the translations for all locales (this can be deferred and passed to translators).
    * Save and close all the model translation files.

5. Open the default locale file for views (in our example config/locales/change_management/en/en.change_management.views.yml).

    * Check that the view translations are included as expected. The translations have been defaulted using Rails `humanize` method, but they can be edited as required.
    * In particular, the header for the index page should be checked to match group noun expectations for the model. For example, cables use schedule, instruments typically use index, others may use list, catalog, etc.
    * Edit the translations for all locales (this can be deferred and passed to translators).
    * Save and close all the view files.

6. Open the migration file (which should be the last migration created), in our example db/migrate/20251226040639_create_change_management_requests.rb.

    * Check all fields are included as expected.
    * Check index and uniq/unique options have been correctly implemented.
    * If there are any decimal fields, check the required precision and scale options are present.
    * Check that any references to existing tables are to the correct table name. For example, a model that belongs_to `widget` has the migration line
      `t.references :widget, foreign_key: true`
      However, if the referenced table does not exist yet, it will be better to create a new migration to add the reference later.
    * Other options are available, but not usually required. Refer to [http://api.rubyonrails.org/classes/ActiveRecord/ConnectionAdapters/SchemaStatements.html#method-i-add_column]
    * Save and close the migration file, then in a terminal, run `rails db:migrate`.

7. Open the factory file (in our example test/factories/change_management/requests.rb).

    * Check all fields are included as expected.
    * Ensure a valid value has been provided for any required fields, as the factory setup is used in testing and tests will fail if no value is entered.
    * Enter string values for enum keys, copied from the constants file but with string quotes added. Be sure to include a decimal point for float types. Note the factory template is a bit clever and if no valid option is provided for an enum type field, it defaults to the first key.
    * Save the factory file.
    * In the terminal, run `rails test test/factories_test.rb` and ensure there are no errors related to the present model.
    * Close the factory file.

8. Open the model test file (in our example `test/models/change_management/request_test.rb`).

    * Check that validations are tested for required fields.
    * Add tests for any other validations that have been added.
    * For electrical models, if it is a demandable type (has load information), add `test_demandable_association`.
    * Add tests for any other model functionality required.
    * Save the model test file.
    * In the terminal, run the test (in our example `rails test test/models/change_management/request_test.rb`).
    * Clear any errors before proceeding, then close the model test file.

9. Unless the new model has special permissions requirements, the policy and policy_test files should not need editing.

    * Run the policy test (in our example `test/policies/change_management/request_policy_test.rb`).

10. Open the controller file for review.

    * This is the dedicated controller (in our example `app/controllers/change_management/requests_controller.rb`).
    If the safe params line (`resource_params`) is too long, insert new lines after commas as required so it is readable. Add any required additional functionality for form setup, create, or update in `setup_additional_form_data`/`after_create_hook`/`after_update_hook`.
       * If the safe params line is too long, insert new lines after commas as required so it is readable.
       * If the model has association fields, check that form setup includes building instance variables for the association collection, for use in select fields in the form. Any other model specific form setup goes here also.
       * If the model has other requirements (for example, a model whose create also builds child records), this can be built into `after_create_hook` and `after_update_hook`.
    * Save and close the controller file.

11. Open the routes file config/routes.rb.

    * The generator should have added one `resources :#{plural_name}` line for the new model. If the model is namespaced and its module already has its own `namespace :#{module_name} do ... end` block in the same routes section, it's tidier to move the generated line into that namespace list along with the module's other models, then remove the line the generator added. Save and close the routes file.

12. Open the controller test file (in our example `test/controllers/change_management/requests_controller_test.rb`).

    * The controller test has a method called `create_params` which sets the expected params from a form submission for testing. Check there is an entry for each field. Ensure that any field with the :required option has a valid value set.
    * The controller test has a method called `invalid_param` which sets up a failing test, to test controller validation failure paths. Set one parameter to an invalid state here. It could be setting a required field to nil, or out of range, or an enum to a value not included in the enum options.
    * The controller test has two methods called `update_attribute_name` and `updated_attribute_value` which are used for testing the controller update action. Set update attribute name to any suitable attribute, and set updated attribute value to anything valid other than the value set in the factory.
    * The controller test has a method called `setup_model_specific_data`. This is where setup code is placed for any additional testing outside the shared test-pattern helper's own tests. For example, a controller test for a model with child records can set up parent and child records here, as part of the additional functionality of the controller. Leave the method empty if no additional setup is required.
    * After the updated_attribute_value method, insert any additional tests for additional controller functionality.
    * Save the controller test file, then run the controller tests (in our example `rails test test/controllers/change_management/requests_controller_test.rb`).
    * Clear any errors before proceeding, then save and close the controller test file.

13. If the model is electrical and has load information, edit the [electrical constants file](../config/constants/electrical.yml).

    * Under the key `loadable:` add a new line with the new model class.
    * Save and close the electrical constants file.

14. With the controller tests working, it is time to test the model in dev.

    * Start (or restart) the dev server.
    * Open a browser and navigate to local_host:3000.
    * Sign in as admin.
    * Navigate to an existing sandbox project.
    * Navigate to the discipline (or other scope) representing the new model's nesting. The new model should appear as expected in the app's navigation.
    * Navigate to the index view and check it is in order.
    * Navigate to the new form and build a new item.
    * Save the item, and you should be redirected to the show view.
    * Throughout this process, there may have been errors raised. Log them, and build a correction process.
    * Also through the process, there may have been parts of the model that didn't meet expectations. Log them, and build a correction process.
    * Depending on the complexity of change required, the correction process might entail using git to revert the whole generation, modify the arguments, and repeat the generation and checking process.

15. When any necessary corrections are complete, open the system test file (in our example `test/system/change_management/requests_system_test.rb`).

    * System tests are abstracted by nesting option, so all models sharing a nesting value follow the same basic tests.
    * The field sets in the system test are set up by the generator according to the [field_types.rb](../lib/generators/project_assistant/field_types.rb) file. Any special field types will need to be coded in the provided hooks. For example, a model may have a float field that the form presents as a select. The generator doesn't know how this works, so the system test has to set that field specially.
    * If the model has features not tested by the standard tests, add tests for them in the system test file. For example, a model with child records has a number of related tests.
    * Save and close the system test file.
    * Run the system test.
    * As before, log any errors, build a correction process and apply it, if required.

Congratulations! The new model is now built and tested. Deployment from dev to production is covered elsewhere.

## TAGABLE GENERATOR

A tagable generator builds a tagable model: a delegated-type model (`include Tagable`) that serves as the datasheet for one type of tagged element. It is split out of the scaffold generator, since tagable models differ in shape and routing enough to be generated on their own.

### Specification

#### Command Line

The command line must include the generator name `project_assistant:tagable` and the model name. The model name must be module-prefixed (e.g. `Electrical::Heater`); a core, non-namespaced tagable model is not supported. Fields are given as command line arguments, or read from a definition file, in the same format as the scaffold generator (see [File Definition of Fields](#file-definition-of-fields) and [Command Line Input of Fields](#command-line-input-of-fields)).

The only option is `--definition`. Definition files live in `lib/generators/project_assistant/scaffold/definitions`, shared with the scaffold generator, and are named without the extension.

Here is an example generate command for an electrical heater:

```bash
rails generate project_assistant:tagable Electrical::Heater heater_type:enum_translated:required application:enum_translated:required ingress_protection:string sheath_temperature_max:float:units="deg C" power_density_min:float power_density_max:float sheath_material:enum_translated insulation_material:enum_translated:keys="insulation_material_other","no_insulation","ceramic","magnesium_oxide","mica","mineral","fluoropolymer","fiberglass" notes:text
```

The same model from a definition file:

```bash
rails generate project_assistant:tagable Electrical::Heater --definition=electrical_heater
```

For a namespaced model, the module (and every level of a nested module) must already exist. Use the module generator first.

#### Files

* A migration: `db/migrate/#{timestamp}_create_#{table_name}.rb`
* A model: `app/models/#{file_path}.rb`, with `include Tagable`, enum declarations (with `prefix: true`), `belongs_to` for reference fields, presence and uniqueness validations, and ransackable attributes and associations, including `:tag, :tag_discipline, :tag_discipline_project`. No policy file is created.
* A controller extension: `app/controllers/#{file_path}_extension.rb`, a singular name directly under the module folder, providing `setup_additional_form_data`, `after_create_hook`, `after_update_hook` and `tagable_params`. It is mixed into the shared `TagablesController`.
* Views: `app/views/#{controller_file_path}/` containing `index`, `_header`, `_row`, `show`, `new`, `edit`, `_form` and `_card`.
* A factory: `test/factories/#{controller_file_path}.rb`, with transient `tag` and `discipline` attributes. A tag is created when none is given.
* A model test: `test/models/#{file_path}_test.rb`, including `TagableModelTests`.
* A controller test: `test/controllers/#{controller_file_path}_controller_test.rb`, including `TagableControllerTests`, with `tests TagablesController` and a `tagable_type` method.
* A system test: `test/system/#{controller_file_path}_system_test.rb`, including `TagableSystemTests`.

Not created: a policy (tagable models are authorized through `TagPolicy`, via their `tag`), a dedicated controller, a helper, or routes. The shared tagable routes already cover every tagable type.

#### Edits

* `config/constants/tagable.yml`: the model's full class name is added directly under its module's comment (e.g. `# Electrical`). If the module has no comment yet, one is added at the end of the list. A type that is already listed is not added again.
* `config/constants/#{module_name}.yml`: a key for the model, with its enum values, as for the scaffold generator.
* Translations: the model and views files for each locale, as for the scaffold generator.
* Routes: none.

### Usage

#### Preparation

Prepare the field list as for the scaffold generator (see [Preparation](#preparation)). In addition:

1. Include a `notes:text` field as the last field. Every tagable model has it, and the shared tagable system tests expect it.

#### Follow Up

1. Open the model file (in our example `app/models/electrical/heater.rb`).
    * For electrical tagable models with load information (most), add `include Electrical::Demandable` directly after `include Tagable`.
    * [TODO future: similar for process module].
    * Apply the same checks as for the scaffold generator (associations, enum prefixes, validations, ransackable lists).
2. Open the extension file (in our example `app/controllers/electrical/heater_extension.rb`), which is mixed into the shared `TagablesController`. There is no dedicated controller to review. Check `tagable_params`, and add any form setup or create and update behaviour to the hooks.
3. Run the migration with `rails db:migrate`, then check `db/schema.rb`.
4. Run the model test and the system test for the new model.
5. In dev, the show view should have a dropdown card for the item's tag. Open it, and navigate to the tag. The tag view should have a dropdown card for the tagable model.

## IMPORT GENERATOR

A generator is provided to retrofit spreadsheet bulk-import support (see [DEVELOPER_NOTES](DEVELOPER_NOTES.md)'s Import section for the underlying `Import::Base`/`Import::Committer`/`Import::BatchesController` framework this generates code against) onto a model that **already exists** - built via the scaffold or tagable generator, or by hand.

The generator itself is reasonably self documented, refer to [import_generator](../lib/generators/project_assistant/import_generator.rb).

### Specification

#### Prerequisites

Before running this generator, the target model must already have:

* For a plain discipline-resource model: a policy class that inherits `DisciplineResourcePolicy`. The generator validates this and aborts with a clear error if it doesn't. A tagable model (`--tagable`) has no policy of its own; it only needs to include `Tagable`.
* For a non-tagable model: an existing controller file, not yet including the `Importable` concern (the generator aborts if it's already there, to avoid double-injecting).
* For a tagable model: nothing controller/routes-wise is required - every tagable type shares the one `TagablesController` and its generic routes, already wired up once for the whole app.

#### Command Line

```bash
rails generate project_assistant:import Document
rails generate project_assistant:import Electrical::Motor --tagable
```

Options:

* `--tagable` (boolean, default false): target is a tagable model (delegated type, includes `Tagable`, no policy of its own). Skips controller and route injection entirely - see Prerequisites above. Without this flag, the generator assumes the plain "discipline resource" shape (policy `< DisciplineResourcePolicy`).
* `--discipline-association=NAME` (default: auto-detected): overrides the `has_many` association name on `Discipline` that points back at this model, for the rare case reflection can't resolve it automatically (e.g. an association name that doesn't match the model's own pluralized name).
* `--nesting=project,discipline` (default: both): comma-separated list of which route contexts to retrofit import into - `project`, `discipline`, or both. Ignored entirely for `--tagable` (no routes are touched either way).

#### Files

The generator shall create these files:

##### Importer Service

* The plugin class every dry-run/commit cycle actually runs, extending `Import::Base` (or `Import::TagableBase` for `--tagable`):
  * `app/services/import/#{import_key}.rb`
* Its `column_definitions` (or `own_column_definitions` for `--tagable`) is auto-derived from the model's own columns intersected with the host controller's own strong-params allowlist - marked with a `REVIEW REQUIRED` comment, since this is a starting point, not a finished mapping. Labels, aliases, and a `:coercer` for anything that isn't a plain string all need a human's judgement afterward.

##### View

* The upload entry-point view, deferring to the shared `import/_upload_form` partial:
  * `app/views/#{controller_file_path}/import.html.erb`

##### Fixture and Tests

* A minimal CSV fixture with the model's required columns, auto-filled with sample values (using each column's own presence/length validators to keep the values plausible):
  * `test/fixtures/files/import/#{import_route_key}.csv`
* Starter tests mirroring the pattern already proven out by hand for `Import::Electrical::Motors` (the reference implementation this generator's own output is verified against):
  * `test/services/import/#{import_key}_test.rb`
  * `test/controllers/#{controller_file_path}_import_test.rb`
  * `test/system/#{controller_file_path}_import_system_test.rb`

#### Edits

##### Controller (skipped entirely for `--tagable`)

* Mixes in `include Importable` right after the controller class line.
* Extends each of `require_project!`/`set_discipline`/`set_swatch`'s existing `before_action` registration to also cover `:import`/`:create_import`, rather than adding a second, independent registration for the same method name - Rails' callback system silently replaces an earlier registration under the same method name, confirmed directly, so a duplicate `before_action` line would never actually run for the new actions.
* Adds two private hook methods the `Importable` concern expects: `importer_key` and `authorize_import!`.

##### Routes (skipped entirely for `--tagable`)

* Inserts a `collection do get :import; post :import, action: :create_import end` block into the model's own `resources :#{plural}` line, in each nesting context selected by `--nesting`. Recognizes both an already-blocked `resources ... do ... end` shape and a bare, comma-combined `resources :a, :b, :c` line (splitting the target model out of the combined list if needed).

##### Locales

* Adds an `import:` block (title/header, or title/header_discipline/header_project for a non-tagable, project-and-discipline-capable model) to each language's views locale file, anchored on the model's own existing top-level key.

##### Index view button

* Adds an Import button next to the existing New button on the model's own `index.html.erb`, conditional on `policy(...).import?`, reusing whatever div class the New button's own column already uses.

### Usage

#### Preparation

1. Commit or otherwise safeguard current work first, same as for the scaffold generator - this generator edits several existing files in place.

2. Confirm the target model already meets the Prerequisites above. Run with `--pretend` first if unsure; every validation step reports a clear error and aborts before touching anything if something's missing.

3. Decide whether the model is a plain discipline-resource or a tagable delegated type, and pass `--tagable` accordingly.

#### Running the Command

Run with `--pretend` first, exactly as for the scaffold generator, to see every file it would create and every edit it would make without touching anything. When the output looks right, run again without `--pretend`.

#### Follow Up

1. Open the importer service file (in our example `app/services/import/documents.rb`).

    * The `own_column_definitions`/`column_definitions` method is only a starting point - review every label, add any `:aliases` a real spreadsheet header might realistically use, and add a `:coercer` for anything that isn't a plain string (see `Import::Electrical::Motors` for a worked example, including an enum coercer that normalizes case/spacing before matching an enum key).
    * If the generator flagged any non-discipline foreign keys as unresolved (printed at the end of the run), decide how each should be resolved - the generator never guesses at natural-key semantics for these.

2. Add the suggested `IMPORTABLE_ATTRIBUTES` constant to the model (the generator prints the exact line to add, derived from the host controller's own strong params).

3. For a non-tagable model, open the controller file and confirm the injected `importer_key`/`authorize_import!` methods are correct, and that the extended `before_action` lists still make sense.

4. Open the generated view file, fixture, and three test files, and run each test file individually (per this project's own testing convention - never combine multiple files in one `rails test` invocation). Adjust the fixture/tests as needed - the generator's own auto-filled sample values are a starting point, not guaranteed to be meaningful for every model's own validations (e.g. an enum column needs a real key, not a generic placeholder string).

5. For `--tagable`, note that `Import::TagableBase` already provides two things for free, with nothing to add here: optional Tag-level columns (Service/Stage/Location/Tag Notes) that can also be set while importing, and an opt-in "create tags that don't exist" checkbox on the mapping page. Just be aware they're available on the generated import form.

6. Test the feature in dev: start the server, sign in, navigate to the model's own index view, and confirm the new Import button reaches the upload form, walks through mapping -> review -> commit, and lands back on the index view with the new/updated record(s) visible.

Congratulations! The model can now be bulk-imported from a spreadsheet.
