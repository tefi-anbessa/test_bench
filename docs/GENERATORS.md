# GENERATORS

## INTRODUCTION

The application Project Assistant (PA) provides shared functionality for all types of engineering design elements within a project. The tag is the linkage for all pertinent information about the element. The name 'tags' originated because identifying tags containing this core information were physically attached to the element. In this application, the tag model contains the core information about the element that is required for all tags across all disciplines. Detailed information about each element is stored in a tagable model, explained below.

### Tags

The tag model has the following database attributes:

* tag_number: it is a compound structure of prefix, serial number, and optional suffix. This structure is not universal but very common in engineering practice.
* service_description: a brief description of the function of the element.
* discipline: the discipline to which the tag belongs.
* stage: the stage is a mechanism to allow grouping tags within a project. It can be used at the project's discretion. E.g. a project may use stages for different phases of construction.
* location: the physical location field also allows grouping of tags.

The tag model provides the following functionality:

* full_tag: the prefix, serial number and suffix are combined to form the full tag, as a virtual field within the database. This enables direct searching of tags by full tag.
* loop_id: This is another virtual field, specifically intended for instrument tags grouping, comprising just the measured value (prefix first character) and serial number.
* prefix_parts: this method parses the prefix into its constituent parts, based on the prefix schema defined in the discipline.

### Disciplines

* Disciplines are unique within a project, and provide the connection from a tag to its project.
* Disciplines are used to group tags.
* Disciplines provide some built in functionality, by linking to modules (see below).
* Discipline related functionality includes:
  * Specify the schema of the tag prefixes in the discipline.
  * Specify the schema for document type codes.
  * Specify the colour swatch for forms and tables.
* Ideally, only standard disciplines would be required. These are defined in the constants system, which can be copied when setting up a project.
* However, it is possible to create custom disciplines, as required, and these can be copied from standard disciplines.
* Discipline names are one of the very few parts of the application where translation of the application generated user facing text is not presently provided. This is because translation would be required for the database content, not the configuration. Until a content translation solution is implemented, custom disciplines are one option for projects to provide translated discipline names which can link back to core discipline functionality by their module connection.

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

### Generators

* A generator is a Rails feature that allows the developer to rapidly build an application based on repeating patterns of files and folders.
* The main benefits of using a generator are:
  * Consistent file structure and naming.
  * Correct initial file content.
  * Reduced development time.
* Rails provides a number of generators for common tasks, such as creating a model, controller, or migration. These are typically very primitive, providing only bare bones of an application.
* The Rails scaffold generator is more comprehensive, providing a full suite of model, migration, controller, routes,views and associated tests.
* This application's bespoke generators are namespaced in the /lib folder under the application name ProjectAssistant. This prevents generator name clashes with other gems and rails standard generators.
* Generators comprise a sequence of instructions to create folders, create files from templates, or edit files. They can also run migrations and all sorts of marvellous things.
* Rails provides the facility to reverse a generator's action using the rails destroy command. Some points to consider about destroy:
  * Destroy bases its actions on the current generator file, so cannot properly destroy actions that are no longer in the generator, if it has been edited.
  * If the generator included a migration (whether run inside the generator or manually), be sure to rollback the migration before running destroy.
  * Destroy is not infallible, particularly on complex generators like those used in this app. Be sure to do a manual check after running destroy.
  * Apparently destroy does not reverse file edits.

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
      * from template `lib/generators/project_assistant/templates/module.rb.erb`, to provide the module table name prefix, and any other functionality the module requires at the top level:
        * `app/models/#{module_name}.rb`
      * from template `lib/generators/project_assistant/templates/base.rb.erb`, to provide shared functionality for all models in the module:
        * `app/models/#{module_name}/base.rb`
      * for each locale in `I18n.available_locales`, files with no content:
        * `config/locales/#{module_name}/#{locale}.#{module_name}.yml`
        * `config/locales/#{module_name}/#{locale}.#{module_name}.models.yml`
        * `config/locales/#{module_name}/#{locale}.#{module_name}.views.yml`
      * from template `lib/generators/project_assistant/templates/constants.yml`, to provide constants such as enum options for the module:
        * `config/constants/#{module_name}.yml`

    * The edits made are:
      * In `config/routes.rb`, generator looks for a line containing `# INSERTION POINT 1 FOR MODULE GENERATOR`, and inserts the following code for top level routes:

        ```ruby
        namespace :#{module_name} do
          # Add #{module_name} routes here with only: [:index, :new, :create]
        end
        ```

      * It then looks for a line containing `# INSERTION POINT 2 FOR MODULE GENERATOR`, and inserts the following code for shallow nested routes under tags:

        ```ruby
        namespace :#{module_name} do
          # Add #{module_name} routes here with except: [:index]
        end
        ```

      * In `config/factory_bot.rb`, the following line is added:

        ```ruby
        config.factory_bot.definition_file_paths << Rails.root.join('test', '#{@module_name.underscore}', 'factories')
        ```

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
* The generator will create the folders, files and edits required to add a new module. The generator will show the files and edits created.

## TAGABLE GENERATOR

### Specification

General requirements.

* This generator will create the folders, files and edits required to add a new tagable type.
* The generator itself is reasonably self documented, refer to `lib/generators/project_assistant/tagable_generator.rb`.

#### Command Line

The generator shall be invoked using the rails generate command, the generator name project_assistant:tagable, the module and tagable model name as Ruby class specifier in CamelCase, and a list of arguments for the fields to be created. Here is an example generate command for an electrical heater:

  ```bash
  rails generate project_assistant:tagable Electrical::Heater heater_type:enum_translated:required application:enum_translated:required ingress_protection:string sheath_temperature_max:float power_density_min:float power_density_max:float sheath_material:enum_translated insulation_material:enum_translated 
  ```

The name of the tagable type must be prefixed with its namespace module, as shown in the example. (The generator cannot be used to create a tagable type in the core application.)

Following the tagable model name, all fields to be included in the model shall be specified with their type and options, separated by colons with no spaces.

* Names must be valid ruby symbols.
* Types implemented shall be the standard rails types as used by the scaffold generator, with custom additions for this generator as listed below.
* The generator is not required to handle `:references` for relationships between models. 
* Standard rails column types are: `:string, :text, :integer, :bigint, :float, :decimal, :datetime, :timestamp, :time, :date, :binary, :boolean, jsonb`.
* The generator shall implement the custom `:enum` type to create an enumerated field. The generator shall set integer type in the migration, and shall create a framework for the enum in the model, views, and constants files for the module. The allowable values for the enum will need to be set manually after generation.
* The generator shall implement the custom `:enum_translated` type to specify an enumerated field (with translations). The generator shall set integer type in the migration, and shall create a framework for the enum in the model, views, and constants as for `:enum` type. In addition, the locales files for the module shall be edited with placeholders for the field name and option translations. The allowable values and translations for the enum will need to be set manually after generation.
* The generator shall respond to the `:index` option after the type. This is standard rails generator format. This option shall result in an index being added in the migration.
* The generator shall respond to the `:uniq` option after the type instead of `:index`. This option shall result in a unique index being added in the migration.
* The generator shall respond to the `:required` option after the type. This is not standard rails generator format but is less ambiguous than the `:null` option.

The generator shall first parse all arguments. If invalid names, types, or options are provided, a warning shall be issued listing the invalid arguments. The user shall be provided with the option to proceed with the remaining valid fields, or to abort the generation and correct the errors.

#### Folders

The generator shall create the views folder:
  `app/views/#{module_name}/#{tagable_name}`

#### Files

The generator shall create these files:

##### Migration

* A database migration file to build the database table with the requested fields:
  * `db/migrate/#{timestamp}_create#{module_name}_#{tagable_name}.rb`

##### Model

* A model definition file including:
  * include tagable module
  * enum declarations for any enum fields
  * presence validations for any required fields
  * ransackable attributes for searching and sorting all attributes
  * ransackable associations for :tag, :tag_discipline, :tag_discipline_project
  * `app/models/#{module_name}/#{tagable_name}.rb`

##### Policy

* A policy file matching the module pattern (typically defers all policy checks to the tag policy):
  * `app/policies/#{module_name}/#{tagable_name}_policy.rb`

##### Controller

* A controller file with the standard RESTful actions deferring to the tagables controller, and safe parameters set to the defined fields:
  * `app/controllers/#{module_name}/#{tagable_name.pluralize}_controller.rb`

##### Helper

* A helper file with module defined but no content:
  * `app/helpers/#{module_name}/#{tagable_name.pluralize}_helper.rb`

##### Views

* A full suite of views built from templates and the specified fields:
  * `app/views/#{module_name}/#{tagable_name.pluralize}/_form.html.erb`
  * `app/views/#{module_name}/#{tagable_name.pluralize}/new.html.erb`
  * `app/views/#{module_name}/#{tagable_name.pluralize}/edit.html.erb`
  * `app/views/#{module_name}/#{tagable_name.pluralize}/index.html.erb`
  * `app/views/#{module_name}/#{tagable_name.pluralize}/show.html.erb`
  * `app/views/#{module_name}/#{tagable_name.pluralize}/_#{tagable_name}.html.erb`
  * `app/views/#{module_name}/#{tagable_name.pluralize}/_#{tagable_name}_header.html.erb`
  * `app/views/#{module_name}/#{tagable_name.pluralize}/_#{tagable_name}_row.html.erb`

##### Factories

* A factory file with fields defined (but no default values):
  * `test/factories/#{module_name}/#{tagable_name.pluralize}.rb`

##### Model Tests

* A model test file with tests for ensuring the tagable link is correct, and for presence of required fields:
  * `test/models/#{module_name}/#{tagable_name}_test.rb`

##### Policy Tests

* A policy test file with setup, which defers tests to the resource_policy_test helper:
  * `test/policies/#{module_name}/#{tagable_name}_policy_test.rb`

##### Controller Tests

* A controller test file with setup, which defers tests to the tagable_test_patterns helper:
  * `test/controllers/#{module_name}/#{tagable_name.pluralize}_controller_test.rb`

##### System Tests

* A system test file with template content, which defers tests to the tagable_system_test_patterns helper:
  * `test/system/#{module_name}/#{tagable_name.pluralize}_system_test.rb`

#### Edits

* The generator shall make the following edits:

##### Routes

* In `config/routes.rb`, two sets of routes are added.

1. The generator shall find the text:

```ruby
namespace :#{module_name} do
# INSERTION POINT 1 FOR TAGABLE GENERATOR
```

and insert after it:

```ruby
resources :#{plural_name}, only: [:index, :new, :create] 
```

If the line does not exist, the generator shall log an error message.

1. The generator shall then find the text:

```ruby
namespace :#{module_name} do
# INSERTION POINT 2 FOR TAGABLE GENERATOR
```

and insert after it:

```ruby
resources :#{plural_name}, except: [:index] 
```

Again, if the line does not exist, the generator shall log an error message.

The generator shall provide a success message if the file edit is completed.

##### Constants

* If any enum fields have been specified (either :enum or :enum_translated), the generator shall look for the file `config/constants/#{module_name}.yml`. If found, a section shall be appended for defining the enum options:

```ruby
  #{singular_name}:
```

followed by an entry for each enum field:

```ruby
    #{field[:name]}:
      #{field[:name]}_other: 0  # Placeholder for other #{field[:name]}
      # TODO: Add enum values
```

The generator shall provide a success message if the file edit is completed. If the file is not found, the generator shall log an error message.

##### Translations

1. For each locale in I18n.available_locales, the generator shall edit the file `config/locales/#{module_name}/#{locale}/#{locale}.#{module_name}.models.yml`. This shall be done by using the `attributes` key as a marker, inserting the model name prior to the key, and the attributes after. For the attributes, the generator shall append a line for each field, with the field name and a dummy translation. If a field is type :enum_translated, additional lines shall be appended with the plural of the field name as a key, and a placeholder translation for the first option. Example:

```yml
en:
  activerecord:
    models:
      ...
      electrical/heater: "Heater"
    attributes:
      electrical/heater:
        heater_type: "Heater type"
          heater_types:
            other_heater_type: "Other"
        application: "Application"
          applications:
            other_application: "Other"
        sheath_temperature_max: "Sheath temperature max"
        ...
```

The help and errors sections shall not be modified, these must be done manually if required.

The generator shall provide a success message if the file edit is completed. If the file is not found, the generator shall log an error message.

1. For each locale in I18n.available_locales, the generator shall edit the files `config/locales/#{module_name}/#{locale}/#{locale}.#{module_name}.views.yml`, appending the model name at the end of the file, with the standard actions translations. All translations shall be set to null or "". Example:

```yml
    heaters:
      index:
        title:            "Heaters"
        header:           "Heaters Schedule for %{project}"
      edit:
        title:            "Edit Heater"
        header:           "Edit Heater: %{label}"
      new:
        title:            "New Heater"
        header:           "New Heater"
      show:
        title:            "Heater"
        header:           "Heater: %{label}"
```

The generator shall provide a success message if the file edit is completed. If the file is not found, the generator shall log an error message.

### Usage

#### Preparation

Usage is explained using the example mentioned in the command line section of the specification. This will be followed by further details for field types not covered by this example.

The first and most important step in creating a tagable is to make a list of all the fields that will be on the data sheet, and determine their types. Only include the necessary fields for all items of the type. [TODO] If additional fields may be optionally required, they can be added as user defined jsonb extensions.

Field names must be valid ruby identifiers.

Each field requires a valid type, separated by a colon with no space, selected from:

* string: use for short definitive text information, but always prefer an enum (see below) if the text should be constrained to accepted values.
* text: use for descriptive information, not requiring any format or checking.
* integer and bigint: use integer for most applications, bigint for huge numbers. (Bigint should be used for any foreign keys, but the generator does not provide these.)
* float: use for floating point numbers, typically attributes that may be involved in calculations. form has a number field with default 0.00 and step 0.01.
* decimal: use for fixed point numbers, typically currency. database is set to type decimal, but the generator does not set precision. The form has a number field with default 0.00 and step 0.01.
* [HOLD] [Date time fields not tested as yet.]
* datetime:
* timestamp:
* time:
* date:
* binary: [HOLD] [Binary fields not tested as yet.]
* boolean: use for switches. The form has a check box.
* jsonb: use for additional user defined data fields, stored as JSONB in the database. The form provides a text area. [TODO] Form should provide json editor but we couldn't get it working.
* enum: use for selection options. This is not a standard rails type, it is used by the generator to create an integer field in the datbase, with drop down select in the form.
* enum_translated: this is as for :enum type, but with translations for the options. the generator will look for translated option keys and values in forms and views.

Fields may also have options, specified after the type, separated by a colons with no spaces. Available options are:

* index: use this option if the field will be subject to frequent search and sort operations.
* uniq: use this option instead of :index, if the field must be unique. (Don't use both :index and :uniq.)
* required: use this option for fields that must have a value set. Use carefully, a record cannot be saved if it has a missing required field. (This is not a standard rails option, but is less ambiguous than null: false.)

With all the fields ready, it's time to draft your command line.

#### Command

You can type the command directly into a terminal, but if you are building a large complex model, it may be worth typing into an editor first, and paste it from there into the terminal window. This way, any errors are more easily corrected.

For the first run, use the --pretend option. This will run through the generator and report all the actions, without actually creating files and folders. If there are errors in the field specification, they should get caught here. When everything is clean, run the generator without the --pretend option.

