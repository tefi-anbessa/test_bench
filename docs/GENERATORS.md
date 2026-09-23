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
* Disciplines are used to group tags.
* Disciplines provide some built in functionality, by linking to modules (see below).
* Discipline related functionality includes:
  * Specify the schema of the tag prefixes in the discipline.
  * Specify the schema for document type codes.
  * Specify the colour swatch for forms and tables.
  * Specifiy required roles for the RBAC system.
* Ideally, only standard disciplines would be required. These are defined in the constants system, which are copied when setting up a project.
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
* The Rails scaffold generator is more comprehensive, providing a full suite of model, migration, controller, routes, views and associated tests.
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
* The generator will create the folders, files and edits required to add a new module. The generator output will show the files and edits created.
* IMPORTANT. The module generator creates a locale file folder, with files for each locale for models, views, and general translations. These files have a namespace key, but no content. If you do not create a model in the new module, the empty locale file (for models at least) will break the translations. Either remove the empty locale file, or add content to it.
* The generator creates a base class for the module, which is used as the parent class for all models in the module. This base class is used to define shared behavior for all models in the module.
* The base class defaults the colour swatch to "app_theme". Set as required.
* The base class defaults the module discpline to the same name as the module. This is used in testing. The user can set any discipline names for each project, they are not constrained to the module name.
* The base class defaults label and long_label methods to inherit from tag. If the module is not used for tagable models, this should be changed to something suitable, or removed.

## TAGABLE GENERATOR

Because the application will require many different tagable types (one for each data sheet), a generator has been provided to create new tagable models, to aid in maintaining consistency with the application look and feel, and general requirements.

### Specification

* This generator shall create the folders, files and edits required to add a new tagable type.
* The generator itself is reasonably self documented, refer to [tagable_generator](../lib/generators/project_assistant/tagable_generator.rb).

#### Command Line

The generator shall be invoked using the rails generate command. The command line must include the generator name project_assistant:tagable, and the module and tagable model name as Ruby class specifier in CamelCase. A list of arguments for the fields to be created can either be provided on the command line, or read from a definition file. Definition files must be YAML or Ruby format. By using a definition file, more complex information is easier to read, check and edit that with a long unformatted command line. Saving the definition file to revision history may be useful later.

Here is an example generate command for an electrical heater (note only one of the enums has keys expounded, this really is a case where a definition file would be clearer):

```bash
rails generate project_assistant:tagable Electrical::Heater heater_type:enum_translated:required application:enum_translated:required ingress_protection:string sheath_temperature_max:float:units="deg C" power_density_min:float power_density_max:float sheath_material:enum_translated insulation_material:enum_translated:keys="insulation_material_other","no_insulation","ceramic","magnesium_oxide","mica","mineral","fluoropolymer","fiberglass" notes:text
```

Here is the alternate command line using a definition file:

```bash
rails generate project_assistant:tagable Electrical::Heater --definition=electrical_heater
```

The name of the tagable type must be prefixed with its namespace module, as shown in the example. (The generator cannot be used to create a tagable type in the core application, and nested modules are not allowed.) The generator will look in folder `lib/generators/project_assistant/tagable/definitions` for a file name as specified, with extension `.yml` or `.rb`.

#### Command Line Input of Fields

When using command line input for fields, following the tagable model name, all fields to be included in the model shall be specified with their type and options, separated by colons with no spaces.

* Names must be valid ruby identifiers.
* Types implemented shall be the standard rails types as used by the scaffold generator, with custom additions for this generator as listed below.
* Standard rails column types are: `:string, :text, :integer, :bigint, :float, :decimal, :datetime, :timestamp, :time, :date, :binary, :boolean, jsonb`.
* The generator shall implement `:references` or `:belongs_to` types as associations between models. These should only be used on the belongs_to model. They shall add the foreign key field to the migration, and provide appropriate view links.
* The generator shall implement the custom `:enum` type to create an enumerated field. The generator shall set integer type in the migration, and shall create a framework for the enum in the model, views, and constants files for the module. The allowable values for the enum should be included as a list of keys as strings in the command line option, or in the definition file.
* The generator shall implement the custom `:enum_translated` type to specify an enumerated field (with translations). The generator shall set integer type in the migration, and shall create a framework for the enum in the model, views, and constants as for `:enum` type. In addition, the locales files for the module shall be edited with placeholders for the field name and option translations. The translations for the enum will need to be set manually after generation.
* "Flag options" don't require a value, their presence implies true and absence implies false. However, they do accept a valid boolean (true or "1", false or "0") as a value.
* The generator shall respond to the `:index` flag option. This is standard rails generator format. This option shall result in an index being added in the migration.
* The generator shall respond to the `:uniq` or `unique` flag option, instead of `:index`. This option shall result in a unique index being added in the migration.
* The generator shall respond to the `:required` flag option after the type. This is not standard rails generator format but is less ambiguous than the `:null` option. It shall result in a presence validation in the model, and an associated model test. IMPORTANT: The :required option for association types is significant. With rails, :belongs_to defaults to required, but in the generator it will be set to optional unless the :required is true.
* Value options require a value. In the command line, the option and value are separated by '='. In a definition file, the syntax must coform to the selected language.
* The generator shall respond to the :valid option for all types. The value provided must be valid for the field's type. The value will be used to default the test factory, and also in controller tests.
* The generator shall respond to the :keys option, but only for :enum and :enum_translated field types. The value shall be an array of strings. On the command line, there must not be any spaces between elements (space is the separator between fields). The array elements shall be used as the enum keys by adding them to the Constants structure. For :enum_translated type, they shall also be added to the model translation files.
* The generator shall respond to the :precision and :scale value options, but only for :decimal and :float types. The values provided must be valid integers. The options shall be passed to the migration for :decimal types. They shall be passed to view helpers for display formatting (not presently implemented).
* The generator shall respond to the :units option, but only for :float and :decimal types. The value shall be coerced to string class, and passed to display helpers for formatting.
* The generator shall respond to the :si option, but only for :float and :decimal types. The value shall be a valid boolean. The value shall be passed to display helpers for formatting (not yet implemented).
* The generator shall respond to the :step option, but only for numeric types :integer, :bigint, :float, and :decimal. The value must be a valid decimal. The value shall be passed to form field helpers for impplementing the step option on number_field tags.

The generator shall first parse all arguments. If invalid names, types, or options are provided, a warning shall be issued listing the invalid arguments. The generator shall abort unless all names, fields and options are valid.

#### File Definition of Fields

The rules for fields defined in a file are the same as for the command line. Fields shall be defined in a YAML file as in this [example](../lib/generators/project_assistant/tagable/definitions/electrical_test.yml), or as a valid Ruby hash (to be implemented).

Differences from command line options are as follows:

* The "flag" options index, uniq/unique, and required shall be specified with a value true, rather than just be present.

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
  * include tagable concern
  * enum declarations for any enum fields
  * belongs to association declaration for any assocition fields
  * presence validations for any required fields
  * uniqueness validations for any unique fields
  * ransackable attributes for searching and sorting all attributes
  * ransackable associations for :tag, :tag_discipline, :tag_discipline_project, and any  fields of type :references
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

* A model test file with tests for required fields, unique fields and enum declarations:
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

* If any enum fields have been specified (either :enum or :enum_translated), the generator shall insert a key for each required field name, followed by the list of key values, each with numeric index:

```ruby
    #{field[:name]}:
      value0: 0
      value1: 1
      ...
```

The generator shall issue a success message if the file edit is completed. If the file is not found, the generator shall log an error message.

##### Translations

1. For each locale in I18n.available_locales, the generator shall edit the file `config/locales/#{module_name}/#{locale}/#{locale}.#{module_name}.models.yml`. This shall be done by using the `models` key as a marker, inserting the model name following the key, with an entry for one and other (plural). After the `attributes` key, the generator shall append a line for each field, with the field name and a dummy translation of "#{field[:name].humanize}". If a field is type :enum_translated, additional lines shall be appended with the plural of the field name as a key, and a line for each key. Example:

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
          heater_type_other: Other heater type
          cast_in: Cast-In Heater
          ...
        application: "Application"
        applications:
          application_other: Other application
          annealing_heat_treating: Annealing _ Heat Treating
          ...
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
        header:           "Heaters Schedule for %{scope_text}"
      edit:
        title:            "Edit Heater"
        header:           "Edit Heater %{label}"
      new:
        title:            "New Heater"
        header:           "New Heater in %{scope_text}"
      show:
        title:            "Heater"
        header:           "Heater %{label}"
```

The generator shall provide a success message if the file edit is completed. If the file is not found, the generator shall log an error message.

### Usage

#### Preparation

Usage is explained using the example used by the generator test, which covers all types and options. The generator can be run entirely from the command line, or using a definitions file. The choice is largely down to complexity of the target datasheet. Using a definition file provides the added benefit of recording the "starting point" in git history.

1. Before running this complex generator, it is strongly recommended to commit all changes to git, so there is a safe return point if things get messy. Generators can be partly reversed with destroy action, but this does not undo the edits made (in fact destroy repeats the edits), nor does it remove migrations because they are timestamped. The safest way for recovering is to use git.

1. The second and most important step in creating a tagable is to make a list of all the fields that will be on the data sheet, determine their types, and record the options required. Include all the necessary fields required to specify items of the new tag type. Unless the tagable is a very simple model, it is recommended to use an editor to prepare a definition file.

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
  * jsonb: use for additional user defined data fields, stored as JSONB in the database. The form provides a text area. [TODO] Form should provide json editor but we couldn't get it working.
  * enum: use for selection options. This is not a standard rails type, it is used by the generator to create an integer field in the datbase, with drop down select in the form. The generator accepts an array of allowed values.
  * enum_translated: this is as for :enum type, but also with translations for the options. The controller generated will build translated option key lists for form selectors, and the views will present translations rather than keys or database values.
  * references: or belongs_to: use for associations. This type sets up the framework of an association.

* Fields may also have options. Options are "flag options" or "value options". Flag options are boolean, and their presence determines the value of the boolean. Value options are of many types, but they are specified as a key/value pair. Available options are:

  * Flag options:
    * :index: use this option to implement a database index. This will greatly improve search and sort operations.
    * :uniq: or :unique: use one of these options instead of :index, if the field must be unique. It will ensure uniqueness at the database level, as well as in validation. [TODO: allow scope to be provided with unique]
    * :required: use this option for fields that must have a value set. Use carefully, as a record cannot be saved if it has a missing required field, which may degrade the user experience.

  * Value options:
    * :valid is available to all types but is ignored for enum types. The value provided must match the field type.
    * :keys is only available for :enum and :enum_translated field types. The value must be an array of strings.
    * :precision and :scale are available for :float and :decimal types. The value must be a valid integer. They correspond to rails' options of the same name, and for :decimal types are enforced in the database.
    * :units is only available for :float and :decimal types. The value must be a string. It is used for presentation only.
    * :si is only available for :float and :decimal types. The value must be a boolean. It is for future use in presentation only.
    * :step is only available for number types (:integer, :bigint, :float, :decimal). The value must be a decimal. It is used for number fields on forms only.

1. Note that enum field option keys became class methods for the model, so have to be unique across the whole class, and may not include Ruby method names. "None" is an easy trap to fall into, but is a standard class method so cannot be used as an option. The solution is to use the prefix or suffix options, see the "Follow Up" section.  

1. Include a field notes:text at the end of the list. All tagables have this field, and the system test expects it to be there.

1. The generator has dependencies, which should automatically be met if the module generator has been used for setting up the module. Refer to the module generator documentation to see what is expected, and check that all requirements are in place.

1. The generator uses [field_types.rb](../lib/generators/project_assistant/field_types.rb) to make assumptions on how to present the various field types. Only field types in `SEARCHABLE_TYPES` will have search fields on the index view. Only fields in `INDEX_TYPES` will appear in the index view. If these assumptions don't suit the model being generated, it is acceptable to edit `field_types.rb` temporarily, but ensure it is restored when complete. If this is a regular occurrence, consider adding named versions of this file.

1. With all the fields ready, it's time to prepare the command line.

#### Command with Definition File

If you have prepared a definition file, the command line is of the form:

```bash
rails generate project_assistant:tagable Electrical::Test --definition=electrical_test
```

By convention, the file should be named as the snake case of the new model's class name, but this is not presently enforced. The generator will look for the file name provided, with .yml or .rb extension.

#### Command Line Arguments

You can type the command directly into a terminal, but if you are building a large complex model, it may be worth typing into an editor first, and paste it from there into the terminal window. This way, errors are more easily corrected.

Here is the example command line tweaked using the generator test arguments:

  ```bash
  rails generate project_assistant:tagable Electrical::Heater name:string:required:valid="Test_name" description:text:valid="Factory_generated_description" selector:enum:keys=["s1","s2","s3"] status:enum_translated:keys=["draft","published","archived"] sort_order:integer:index:valid=100 power:float:precision=4:units=m:si=true:valid=5.555 money:decimal:precision=5:scale=2:valid=1.55 switch:boolean birthday:date created:datetime flex_field:jsonb code:string:uniq parent:references owner:belongs_to:required=true
  ```

Note the limitations of the command line: no spaces allowed. This mainly affects strings: you cannot have multi-word valid values. Also be sure there are no spaces in the enum value arrays.

#### Running the Command

If using guard for testing, it is probably better to exit before running the generator, as generation will trigger lots of failing tests.

Run the generator command using the --pretend option (or simply -p) first. This will run through the generator checks and methods and report all the actions, without actually creating or editing files and folders. If there are errors in the name or field specifications, they should get caught here. Insect the output to ensure it is what you are expecting. When everything is clean, run the generator without the --pretend option.

#### Follow Up

1. If using guard for testing, it is probably better to exit before completing follow up, as some edits will trigger lots of failing tests.

2. Open the model file (in our example app/models/electrical/test.rb).

* For electrical models with load information required (most), after
  `include Tagable`
  add the line:
  `include Electrical::Demandable`.
* [TODO future: similar for process module].
* Check that associations are correctly defined for :references fields. The generator adds `belongs_to` statements, but no options. These must be added if required. The generator assumes that the referenced class is in the same module/sub-module as the generated model. Add the inverse relation (has_many or has_one) to the referenced model.
* Check that any required :enum and :enum_translated type fields are specified as enum with reference to the constants defining the field options.
* Check that the fields with :required option have presence validations.
* Add any other validations required, such as range limits, numericality, format, etc.
* If the `ransackable_attributes` line is too long, split it after a comma for ease of reading.
* Check that `ransackable_associations` meet requirements.

3. Open the module constants file (in our example config/constants/electrical.yml).

* There should be a new key for the tagable model (test: in our example)
* For each enum field, there should be a line with the field name as key.
* Indented under the field name, each option key should have a unique integer value.
* Check all of the enum options for all enum fields in the model. If there are any duplications, they must be made unique. The usual way to to this is to add a prefix in the model definition. For example, Electrical::Heater has sheath material and insulation material both having the option `fluoropolymer`, so we have edited the heater.rb file:

     ```ruby
     enum :sheath_material, Constants.electrical.heater.sheath_material.to_h, prefix: true
     enum :insulation_material, Constants.electrical.heater.insulation_material.to_h, prefix: true
     ```

  * Note this prefix only affects the class method names, it doesn't change the values that are displayed in forms or views.
* Save the model file and the module constants file.

4. Open the default locale file for models (in our example config/locales/en/electrical/models.yml).

* Check that the model translation and all field translations are included as expected. The translations have been defaulted using Rails' `humanize` method, but they can be edited as required.
* For any enum_translated fields, there should be a key for the options as plural of the field name, and a line for each option. Again, the translations are defaulted using Rails' humanize method.
* Edit the translations for all locales (this can be deferred and passed to translators).
* Save and close all the model translation files.

5. Open the default locale file for views (in our example config/locales/en/electrical/views.yml).

* Check that the view translations are included as expected. The translations have been defaulted using Rails `humanize` method, but they can be edited as required.
* In particular, the header for the index page should be checked to match group noun expectations for the model. For example, cables use schedule, instruments typically use index, others may use list, catalog, etc.
* Edit the translations for all locales (this can be deferred and passed to translators).
* Save and close all the view files.

6. Open the migration file (which should be the last migration created), in our example db/migrate/20251226040639_create_electrical_test.rb.

* Check all fields are included as expected.
* Check index and uniq/unique options have been correctly implemented.
* If there are any decimal fields, check the required precision and scale options are present.
* Check that any references to existing tables are to the correct table name. For example, an electrical cable belongs_to electrical_cable_type, and the migration includes the line
  `t.references :electrical_cable_type, foreign_key: true`
  However, if the referenced table does not exist yet, it will be better to create a new migration to add the reference later.
* Other options are available, but not usually required. Refer to [http://api.rubyonrails.org/classes/ActiveRecord/ConnectionAdapters/SchemaStatements.html#method-i-add_column]
* Save and close the migration file, then in a terminal, run `rails db:migrate`.

7. Open the factory file (in our example test/factories/electrical/tests.rb).

* Check all fields are included as expected.
* Ensure a valid value has been provided for any required fields, as the factory setup is used in testing and tests will fail if no value is entered.
 * Enter string values for enum keys, copied from the constants file but with string quotes added. Be sure to include a decimal point for float types. Note the factory template is a bit clever and if no valid option is provided for an enum type field, it defaults to the first key.
* Save the factory file.
* In the terminal, run `rails test test/factories_test.rb` and ensure there are no errors related to the present model.
* Close the factory file.

8. Open the model test file (in our example `test/models/electrical/test_test.rb`).

* Check that validations are tested for required fields.
* Add tests for any other validations that have been added.
* For electrical models, if it is a demandable type (has load information), add `test_demandable_association`.
* Add tests for any other model functionality required.
* Save the model test file.
* In the terminal, run the test (in our example `rails test test/models/electrical/test_test.rb`).
* Clear any errors before proceeding, then close the model test file.

9. Unless the new model has special permissions requirements, the policy and policy_test files should not need editing.

* Run the policy test (in our example `test/policies/electrical/test_policy_test.rb`).

10. Open the controller file (in our example `app/controllers/electrical/test_controller.rb`).

* If the safe params line is too long, insert new lines after commas as required so it is readable.
* Usually, that will be the only controller edit required at this stage. If the model has related entities, as for example electrical switchboards has circuits, this will usually need to be built before the controller requirements are known.
* Add any required additional functionality for form setup, such as specialised option select lists, in the `setup_additional_form_data` section.
* Add any required additional functionality for the create action in the `after_create_hook` section.
* Add any required additional functionality for the update action in the `after_update_hook` section.
* Save and close the controller file.

11. Open the routes file config/routes.rb.

* The generator should have added two lines for tagable routes for the new model: one under the module namespace alone, and another nested under the tags resources, then the module namespace. These routes can be included more simply by including the new model along with the other models in the comma separated lists for the same module. (The generator finds it hard to locate the correct place, so it is easier to create new lines for each route. It will work perfectly as is, but the file grows faster.) If this edit is made, remove the lines added by the generator, then save and close the routes file.

12. Open the controller test file (in our example `test/controllers/electrical/tests_controller_test.rb`).

* The controller test has a method called `valid_resource_params` which sets the expected params from a form submission for testing. There should be an entry for each field. Ensure that any field with the :required option has a valid value set. 
* The controller test has a method called `invalid_resource_params` which sets up a failing test, to test controller validation failure paths. Set one parameter to an invalid state here. It could be setting a required field to nil, or out of range, or an enum to a value not included in the enum options.
* The controller test has two methods called `update_attribute_name` and `updated_attribute_value` which are used for testing the controller update action. Set update attribute name to any suitable attribute, and set updated attribute value to anything valid other than the value set in the factory.
* The controller test has a method called `setup_model_specific_data`. This is where setup code is placed for any additional testing outside the tagable functions. For example, the electrical switchboards controller test has a setup for a switchboard with child circuits, part of the additional functionality of this controller. Leave the method empty if no additional setup is required.
* After the updated_attribute_value method, insert any additional tests for additional controller functionality.
* Save the controller test file, then run the controller tests (in our example `rails test test/controllers/electrical/tests_controller_test.rb`).
* Clear any errors before proceeding, then save and close the controller test file.

13. If the model is electrical and has load information, edit the [electrical constants file](../config/constants/electrical.yml).

* Under the key `loadable:` add a new line with the new model class.
* Save and close the electrical constants file.

14. With the controller tests working, it is time to test the model in dev.

* Start the dev server.
* Open a browser and navigate to local_host:3000.
* Sign in as admin.
* Navigate to an existing project.
* Navigate to the discipline representing the module of the new model. The new model should appear on the discipline dashboard.
* Navigate to the index view and check it is in order.
* Navigate to the new form and build a new tag and associated model.
* Save the item, and you should be redirected to the show view.
* The show view should include a dropdown card for the item's tag. Open it, and navigate to the tag.
* The tag view should include a dropdown card for the tagable model. Open it, and check the contents.
* Throughout this process, there may have been errors raised. Log them, and build a correction process.
* Also through the process, there may have been parts of the model that didn't meet expectations. Log them, and build a correction process.

15. When any necessary corrections are complete, open the system test file (in our example `test/system/electrical/tests_test.rb`).

* Tagable system tests are abstracted, so all models follow the same basic tests.
* The field sets in the system test are set up by the generator according to the [field_types.rb](../lib/generators/project_assistant/field_types.rb) file. Any special field types will need to be coded in the provided hooks. For example, electrical circuits model has a rating field that is a float value but the form uses a select field. The generator doesn't know how this works, so the system test has to set that field specially.
* If the model has features not tested by the standard tests, add tests for them in the system test file. For example, electrical switchboards are integrated with circuits, so have a number of related tests.
* Save and close the system test file.
* Run the system test. Clear any errors.

Congratulations! The new model is on line.

## SCAFFOLD GENERATOR

A scaffold generator is provided as an alternative to the rails standard scaffold generator. This generator is based on the tagable generator, but without the tag linkage aspects. Because it is so similar, the documentation here is primarily a list of differences from the tagable generator. Use the tagable generator specification and usage instructions, while referencing the differences listed here.

The scaffold generator differs from the tagable generator in allowing models to be created in nested modules, or at the core level. All module levels must exist, with the associated folders and files, before running the generator. Always use the module generator to ensure that folders and files are in the expected state.

### Specification

#### Command Line

The scaffold generator shall be invoked using the rails generate command, the generator name project_assistant:scaffold, the module and tagable model name as a Ruby class specifier in CamelCase, and a list of arguments for the fields to be created.  Here is an example generate command for a document control object:

  ```bash
  rails generate project_assistant:scaffold DocumentControl::Issue document:references code:string user:references{by} user:references{checked} user:references{approved}
  ```

Rules for arguments are the same.

#### Folders and Files

The generator creates the same folders and files as the tagable generator.

#### Edits

The generator only inserts one set of routes under the first module namespace. If there is no namespace, the routes are inserted ahead of the home routes comment.

The generator does not edit the tagable constants file.

Module constants and translation edits are the same as for tagable.

### Usage

#### Preparation
