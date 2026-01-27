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

Because the application will require many different tagable types (one for each data sheet), a generator has been provided to create new tagable models, to aid in maintaining consistency with the application look and feel, and general requirements.

### Specification

General requirements.

* This generator will create the folders, files and edits required to add a new tagable type.
* The generator itself is reasonably self documented, refer to `lib/generators/project_assistant/tagable_generator.rb`.


#### Command Line

The generator shall be invoked using the rails generate command, the generator name project_assistant:tagable, the module and tagable model name as Ruby class specifier in CamelCase, and a list of arguments for the fields to be created. Here is an example generate command for an electrical heater:

  ```bash
  rails generate project_assistant:tagable Electrical::Heater heater_type:enum_translated:required application:enum_translated:required ingress_protection:string sheath_temperature_max:float power_density_min:float power_density_max:float sheath_material:enum_translated insulation_material:enum_translated notes:text
  ```
The name of the tagable type must be prefixed with its namespace module, as shown in the example. (The generator cannot be used to create a tagable type in the core application, and nested modules are not allowed.)

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

* In `config/routes.rb`, two sets of routes shall be added.

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

* The generator shall look for the file `config/constants/#{module_name}.yml`. If found, a key shall be appended for defining any required model constants. Primarily, these are expected to be enum key definitions.

```ruby
  #{singular_name}:
```

* If any enum fields have been specified (either :enum or :enum_translated), the generator shall insert a key for each required field name:

```ruby
    #{field[:name]}:
      # TODO: Add enum values
```

The enum keys can be completed using the enum generator, but a reminder comment is inserted in case this is left to be completed manually. (Don't remove the reminder then try to use the enum generator, because the enum generator uses the reminder as a placemarker.)

The generator shall issue a success message if the file edit is completed. If the file is not found, the generator shall log an error message.

##### Translations

1. For each locale in I18n.available_locales, the generator shall edit the file `config/locales/#{module_name}/#{locale}/#{locale}.#{module_name}.models.yml`. This shall be done by using the `attributes` key as a marker, inserting the model name prior to the key, and the attributes after. For the attributes, the generator shall append a line for each field, with the field name and a dummy translation of "#{field[:name].humanize}". If a field is type :enum_translated, additional lines shall be appended with the plural of the field name as a key, and a placeholder translation for the first option. Example:

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

1. Before running this complex generator, it is strongly recommended to commit all changes to git, so there is a safe return point if things get messy. Generators can be partly reversed with destroy action, but this does not undo the edits made (in fact destroy repeats the edits), nor does it remove migrations because they are timestamped. The safest way for recovering is to use git.

1. The second and most important step in creating a tagable is to make a list of all the fields that will be on the data sheet, and determine their types. Include all the necessary fields required to specify items of the new tag type. [TODO] If additional fields may be optionally required, they can be added as user defined jsonb extensions.

Field names must be valid ruby identifiers.

Each field requires a valid type, separated by a colon with no space, selected from:

* string: use for short definitive text information, but always prefer an enum (see below) if the text should be constrained to accepted values.
* text: use for descriptive information, not requiring any format or checking.
* integer and bigint: use integer for most applications, bigint for huge numbers. (Bigint should be used for any foreign keys, but the generator does not provide these.)
* float: use for floating point numbers, typically attributes that may be involved in calculations. The form has a number field with default 0.00 and step 0.01.
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
* enum_translated: this is as for :enum type, but with translations for the options. the generator will look for translated option keys in forms and display them in views.

Fields may also have options, specified after the type, separated by a colons with no spaces. Available options are:

* index: use this option if the field will be subject to frequent search and sort operations, or used to link to other resources.
* uniq: use this option instead of :index, if the field must be unique. (Don't use both :index and :uniq.)
* required: use this option for fields that must have a value set. Use carefully, a record cannot be saved if it has a missing required field. (This is not a standard rails option, but is less ambiguous than null: false.)

1. For each enum and enum_translated field, list the field options.  
Note that enum field option keys became class methods for the model, so have to be unique across the whole class, and may not include Ruby method names. "None" is an easy trap to fall into, but is a standard class method so cannot be used as an option. The solution is to use the prefix or suffix options, this is explained in the usage section.  

1. Include a field notes:text at the end of the list. All tagables have this field, and the system test expects it to be there.

1. The generator has dependencies, which should automatically be met if the module generator has been used for setting up the module. Refer to the model generator documentation to see what is expected, and check that all requirements are in place.

1. With all the fields ready, it's time to draft the command line.

#### Command

You can type the command directly into a terminal, but if you are building a large complex model, it may be worth typing into an editor first, and paste it from there into the terminal window. This way, errors are more easily corrected.

Run the generator command line using the --pretend option (or simply -p). This will run through the generator methods and report all the actions, without actually creating or editing files and folders. If there are errors in the name or field specifications, they should get caught here. When everything is clean, run the generator without the --pretend option.

Here again is our example command line:

  ```bash
  rails generate project_assistant:tagable Electrical::Heater heater_type:enum_translated:required application:enum_translated:required ingress_protection:string sheath_temperature_max:float power_density_min:float power_density_max:float sheath_material:enum_translated insulation_material:enum_translated notes:text
  ```

#### Follow Up

1. If using guard for testing, it is probably better to exit before completing follow up, as some edits will trigger lots of failing tests.

1. Open the model file (in our example app/models/electrical/heater.rb).
   * For electrical models with load information required (most), after
     `include Tagable`
     add the line:
     `include Electrical::Demandable`.
   * [TODO future: similar for process module].
   * Check that any required :enum and :enum_translated type fields are specified as enum.
   * Check that the fields with :required option have presence validations.
   * Add any other validations required, such as range limits, numericality, format, etc.
   * If the `ransackable_attributes` line is too long, split it after a comma for ease of reading.

1. Open the module constants file (in our example config/constants/electrical.yml). [HOLD revise after enum generator working.]
   * For each enum field, there should be a line with the field name as key.
   * Give each option key a unique integer value.
   * Delete the placeholder comments, and add your own comments if required.
   * Go back to the model file, and delete the reminder comments for each :enum field to complete the enum values, as you have just completed this.
   * Check all of the enum options for all enum fields in the model. If there are any duplications, they must be made unique. The usual way to to this is to add a prefix in the model definition. In our heater example, sheath material and insulation material both have the option `fluoropolymer`, so we have edited the heater.rb file:

     ```ruby
     enum :sheath_material, Constants.electrical.heater.sheath_material.to_h, prefix: true
     enum :insulation_material, Constants.electrical.heater.insulation_material.to_h, prefix: true
     ```

   * Note this prefix only affects the class method names, it doesn't change the values that are displayed in forms or views.
   * Save the model file and the module constants file.

1. Open the default locale file for models (in our example config/locales/en/electrical/models.yml).
   * Check that the model translation and all field translations are included as expected. The translations have been defaulted using Rails `humanize` method, but they can be edited as required.
   * For any enum_translated fields, there should be a key for the options as plural of the field name, and a default "other" option. Edit this as required to exactly match the option keys that are in Constants. Add a translation key/value pair for each option.
   * Copy the attributes section for the new model, and paste it into the models file for all other locales, overwriting the generator defaults.
   * Edit the translations for all locales (this can be deferred and passed to translators).
   * Save and close all the model translation files.

1. Open the default locale file for views (in our example config/locales/en/electrical/views.yml).
   * Check that the view translations are included as expected. The translations have been defaulted using Rails `humanize` method, but they can be edited as required.
   * In particular, the header for the index page should be checked to match expectations for the model. For example, cables use schedule, instruments typically use index, others may use list, catalog, etc.
   * Edit the translations for all locales (this can be deferred and passed to translators).
   * Save and close all the view files.

1. Open the migration file (which should be the last migration created), in our example db/migrate/20251226040639_create_electrical_heater.rb.
   * Check all fields are included as expected.
   * If there are any decimal fields, add the required precision. For example, a dollar currency field might require
     `t.decimal :amount, precision: 5, scale: 2`.
   * If the model has a reference to an existing table, you can add the reference at this point. For example, an electrical cable belongs_to electrical_cable_type, and the migration includes the line
     `t.references :electrical_cable_type, null: false, foreign_key: true`
     However, if the referenced table does not exist yet, it will be better to create a new migration to add the reference later.
   * Other options are available, but not usually required. Refer to [http://api.rubyonrails.org/classes/ActiveRecord/ConnectionAdapters/SchemaStatements.html#method-i-add_column]
   * Save and close the migration file, then in a terminal, run `rails db:migrate`.

1. Open the factory file (in our example test/factories/electrical/heaters.rb).
   * Check all fields are included as expected.
   * Enter a valid value for each field, which will be used in testing (and console, if factory_bot is enabled for console). Enter string values for enum keys, copied from the constants file but with string quotes added. Be sure to include a decimal point for float types.
   * Save the factory file.
   * In the terminal, run `rails test test/factories_test.rb` and ensure there are no errors related to the present model.
   * Close the factory file.

1. Open the model test file (in our example `test/models/electrical/heater_test.rb`).
   * Check that validations are tested for required fields.
   * Add tests for any other validations added.
   * For electrical models, add tests for linkage with the demand model by copying from another model test.
   * Add tests for any other model functionality required.
   * Save the model test file.
   * In the terminal, run the test (in our example `rails test test/models/electrical/heater_test.rb`).
   * Clear any errors before proceeding, then close the model test file.

1. Unless the new model has special permissions requirements, the policy and policy_test files should not need editing.

   * Run the policy test (in our test `test/policies/electrical/heater_policy_test.rb`).

1. Open the controller file (in our example `app/controllers/electrical/heaters_controller.rb`).

   * If the safe params line is too long, insert new lines after commas as required so it is readable.
   * Usually, that will be the only controller edit required at this stage. If the model has related entities, as for example electrical switchboards has circuits, this will usually need to be built before the controller requirements are known.
   * Add any required additional functionality for form setup, such as specialised option select lists, in the `setup_additional_form_data` section.
   * Add any required additional functionality for the create action in the `after_create_hook` section.
   * Add any required additional functionality for the update action in the `after_update_hook` section.
   * Save and close the controller file.

1. Open the routes file config/routes.rb.
   * The generator should have added two lines for tagable routes for the new model: one under the module namespace alone, and another nested under the tags resources, then the module namespace. These routes can be included more simply by including the new model along with the other models in the comma separated lists for the same module. (The generator finds it hard to locate the correct place, so it is easier to create new lines for each route. It will work perfectly as is, but the file grows faster.) If this edit is made, remove the lines added by the generator, then save and close the routes file.

1. Open the controller test file (in our example `test/controllers/electrical/heaters_controller_test.rb`).

   * The controller test has a method called `valid_resource_params` which sets the minimum required params for testing. There should already be an entry for each field that had the :required option. Set valid values for each field, and remove the reminder comments.
   * The controller test has a method called `invalid_resource_params` which sets up a failing test, to test controller validations failure paths. Set one parameter to an invalid state here. It could be setting a required field to nil, or out of range, or an enum to a value not included in the enum options.
   * The controller test has two methods called `update_attribute_name` and `updated_attribute_value` which are used for testing the controller update action. Set update attribute name to any suitable attribute, and set updated attribute value to anything valid other than the value set in the factory.
   * The controller test has a method called `setup_model_specific_data`. This is where setup code is placed for any additional testing outside the tagable functions. For example, the electrical switchboards controller test has a setup for a switchboard with child circuits, part of the additional functionality of this controller. Leave the method empty if no additional setup is required.
   * After the updated_attribute_value method, insert any additional tests for additional controller functionality.
   * Save the controller test file, then run the controller tests (in our example `rails test test/controllers/electrical/heaters_controller_test.rb`).
   * Clear any errors before proceeding, then save and close the controller test file.

1. Open the layout header file `app/views/layouts/_header.html.erb` and locate the navbar section for the module where the new model is to be added. Locate the insertion point required, and insert the following code (substituting the module and model names):

    ```ruby

                <% if policy(Module::Model).index? %>
                  <li>
                    <%= link_to t('model', scope: 'activerecord.models').pluralize,
                      module_models_path,
                      class: "dropdown-item" %>
                  </li>
                <% end %>
    ```

1. Go to the views folder, and open the show, card, form and row files (in our example `app/views/electrical/heaters/show.html.erb`, `app/views/electrical/heaters/_card.html.erb`, `app/views/electrical/heaters/_form.html.erb` and `app/views/electrical/heaters/_row.html.erb`). These should work out of the box, but any numeric fields may need engineering units added. In our example, the show view has default code:

    ```ruby
                <%= number_to_human(@heater.power_density_min, 
                  precision: 4, 
                  units: { unit: "x" , thousand: "kx", million: "Mx" }) || '-' %>
    ```

   Edit this to be:

    ```ruby
                <%= number_to_human(@heater.power_density_min, 
                  precision: 4, 
                  units: { unit: "W/m²" , thousand: "kW/m²", million: "MW/m²" }) || '-' %>
    ```

   Repeat for all numeric fields, in all four views (forms don't have provision for thousands, millions etc.). If units are not required, delete the option. After editing, delete the comment to show others that the units have already been set, it is not in default state.

1. Open the system test file (in our example `test/system/electrical/heaters_test.rb`).
   * In console, run `Module::ModelName.column_names` to list the fields for the model. Copy this list (without id, and without the timestamp fields unless there is a particular requirement for them), then paste it into each of the field lists in `setup_model_specific_data`. For each list, consider if any of the fields should be removed.
   * Save and close the system test file.

## SCAFFOLD GENERATOR

A scaffold generator is provided as an alternative to the rails standard scaffold generator. This generator is based on the tagable generator, but without the tag linkage aspects. Because it is so similar, the documentation here is primarily a list of differences from the tagable generator. Use the tagable generator specification and usage instructions, while referencing the differences listed here.

The scaffold generator differs from the tagable generator in allowing models to be created in nested modules, or at the core level. All module levels must exist, with the associated folders and files, before running the generator. Always use the module generator to ensure that folders and files are in the expected state.

### Specification.

#### Command Line

The scaffold generator shall be invoked using the rails generate command, the generator name project_assistant:scaffold, the module and tagable model name as a Ruby class specifier in CamelCase, and a list of arguments for the fields to be created.  Here is an example generate command for a document control object:

  ```bash
  rails generate project_assistant:scaffold Docment::Issue document:references code:string user:references{by} user:references{checked} user:references{approved}
  ```

Rules for arguments are the same.

#### Folders and Files

The generator creates the same folders and files as the tagable generator.

#### Edits

The generator only inserts one set of routes under the first module namespace. If there is no namespace, the routes are inserted ahead of the home routes comment.

The generator does not edit the tagable constants file.

Module constants and translation edits are the same as for tagable.

