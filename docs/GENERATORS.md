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

* Disciplines are unique within a project, and thus provide the connection from a tag to its project.
* Disciplines are used to group tags.
* Disciplines provide some built in functionality, by linking to modules (see below).
* Discipline related functionality includes:
  * Specify the schema of the tag prefixes in the discipline.
  * Specify the colour swatch for forms and tables.
* Ideally, only standard disciplines would be required. These are defined in the constants system, which can be copied when setting up a project.
* However, it is possible to create custom disciplines, as required.
* Discipline names are one of the very few parts of the application where translation of the application generated user facing text is not presently provided. This is because translation would be required for the database content, not the configuration. Until a content translation solution is implemented, custom disciplines are one option for projects to provide translated discipline names which can link back to core discipline functionality by their module connection.

### Tagables

* The next level of information for tagged elements is referenced in this application as the tagable data. This is not engineering terminology, it is Rails conventional naming for delegated types (also for polymorphic associations, of which delegated types are a special case). Delegated type is a Rails database concept allowing disparate models to share common attributes.
* A note about spelling: Many sources claim that the correct spelling is taggable, including material written by DHH himself. However, tagable is the convention rails uses for a delegated type from tag, so we have gone with that rather than override convention.
* Different design element types will require different information. E.g. within the electrical discipline, a motor will require different information than a switchboard. Therefore, the application includes a Motor model and a Switchboard model, but those models both include tagable, so they have all the functionality of the tag model as well.
* The tagable model can be considered as the datasheet for the element type. As such, the tagable model should incorporate all information required to specify the element for purchase.

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
* This applicatio's' bespoke generators are namespaced in the /lib folder under the application name ProjectAssistant. This prevents generator name clashes with other gems and rails standard generators.
* Generators comprise a sequence of instructions to create or edit files and folders. They can also run migrations and all sorts of marvellous things.
* Rails provides the facility to reverse a generator's action using the rails destroy command. Some points to consider about destroy:
  * Destroy bases its actions on the current generator file, so cannot properly destroy actions that are no longer in the generator, if it has been edited.
  * If the generator included a migration (whether run inside the generator or manually), be sure to rollback the migration before running destroy.
  * Destroy is not infallible, particularly on complex generators like those used in this app. Be sure to do a manual check after running destroy.

## MODULE GENERATOR

### Specification

* This generator will create the folders, files and edits required to add a new module.
* Specific requirements
  * The generator itself is reasonably self documented, refer to ```lib/generators/project_assistant/module_generator.rb```.
  * Here is a more detailed specification:
    * The generator expects a single command line parameter, which it receives as the variable ```name``` via its NamedBase inheritance. This is the name of the module to be created.
    * The generator first checks for the existence of the folders it is about to generate. If any of the folders exist, the generator will provide the user with the option to abort, as continuing will clobber any existing content. Abort is overriden in the test environment.
    * The folders created are:
      * ```app/models/#{module_name}```
      * ```app/controllers/#{module_name}```
      * ```app/helpers/#{module_name}```
      * ```app/policies/#{module_name}```
      * ```app/views/#{module_name}```
      * ```test/factories/#{module_name}```
      * ```test/models/#{module_name}```
      * ```test/controllers/#{module_name}```
      * ```test/helpers/#{module_name}```
      * ```test/policies/#{module_name}```
      * ```test/system/#{module_name}```
      * ```config/locales/#{module_name}```
      * ```config/locales/#{module_name}/#{locale}``` for each locale in ```I18n.available_locales```
    * The files created are:
      * from template ```lib/generators/project_assistant/templates/module.rb.erb```, to provide the module table name prefix, and any other functionality the module requires at the top level:
        * ```app/models/#{module_name}.rb```
      * from template ```lib/generators/project_assistant/templates/base.rb.erb```, to provide shared functionality for all models in the module:
        * ```app/models/#{module_name}/base.rb```
      * for each locale in ```I18n.available_locales```, files with no content:
        * ```config/locales/#{module_name}/#{locale}.#{module_name}.yml```
        * ```config/locales/#{module_name}/#{locale}.#{module_name}.models.yml```
        * ```config/locales/#{module_name}/#{locale}.#{module_name}.views.yml```
      * from template ```lib/generators/project_assistant/templates/constants.yml```, to provide constants such as enum options for the module:
        * ```config/constants/#{module_name}.yml```

    * The edits made are:
      * In ```config/routes.rb```, generator looks for a line containing ```# NAMESPACE INSERTION POINT 1 FOR GENERATOR```, and inserts the following code for top level routes:

        ```ruby
        namespace :#{module_name} do
          # Add #{module_name} routes here with only: [:index, :new, :create]
        end
        ```

      * It then looks for a line containing ```# NAMESPACE INSERTION POINT 2 FOR GENERATOR```, and inserts the following code for shallow nested routes under tags:

        ```ruby
        namespace :#{module_name} do
          # Add #{module_name} routes here with except: [:index]
        end
        ```

      * In ```config/factory_bot.rb```, the following line is added:

        ```ruby
        config.factory_bot.definition_file_paths << Rails.root.join('test', '#{@module_name.underscore}', 'factories')
        ```

      * In ```config/constants/tagable.yml```, after the line ```tagable:```the following comment line is added, as the placeholder to define tagable models in the module:

        ```#{module_name}```

### Usage

* The module generator is used as follows:
  * Run the generator with the following command:

    ```bash
    rails g project_assistant:module <module_name>
    ```

  <module_name> should be provided as CamelCase but will be converted to snake_case for file names and CamelCase for class or module names within the generator.
* If prompted, it means the generator has found an existing folder, and will ask if you want to proceed.
  * If you are sure that the existing folder does not contain anything that needs to be retained, respond with 'y'.
  * If you are not sure, respond with 'n'. The generator will abort.
* The generator will create the folders, files and edits required to add a new module. The generator will show the files and edits created.

## TAGABLE GENERATOR

### Specification

* General requirements
  * This generator will create the folders, files and edits required to add a new tagable type.
  * The generator itself is reasonably self documented, refer to ```lib/generators/project_assistant/tagable_generator.rb```.

#### Arguments

* The generate command for a tagable will typically look like:

  ```bash
  rails g project_assistant:tagable module_name:tagable_name field:type:required field:type:index field:enum field:enum_translated...
  ```

* The name of the tagable type should be prefixed with its namespace module, as shown in the example. (The generator should never be used to create a tagable type in the core application.)
* Following the name, all fields to be included in the model should be specified with their rails type. This mostly follows the standard model or scaffold generator format.
  * The generator is not setup to handle ```:references``` for relationships between models. These should be coded manually, before migrating.
  * Standard rails column types are: :string, :text, :integer, :float, :decimal, :datetime, :timestamp, :time, :date, :binary, :boolean.
  * Use the ```:enum``` type to specify an enumerated field (without translations - such as numeric options or international standard codes). This is not a standard rails generator type. The generator will set integer type in the migration, and will create a framework for the enum in the model, views, and constants files for the module. The allowable values for the enum will need to be set manually. The form will be set to use the constants hash directly as the options for the associated select field, and show views will not translate the field.
  * Use the ```:enum_translated``` type to specify an enumerated field (with translations). This is not a standard rails generator type. The generator will set integer type in the migration, and will create a framework for the enum in the model, views, constants, and locales files for the module. The allowable values and translations for the enum will need to be set manually. The form will be set to use the translated enum values as the options for the associated select field, and show views will translate the field.
  * If a field should be indexed, for frequent or complex searches, it should be specified with the ```:index``` option after the type. This is standard rails generator format.
  * If a field should be unique, it should be specified with the ```:uniq``` option after the type instead of ```:index```. This is standard rails generator format.
  * If a field is required, it should be specified with the ```:required``` option after the type. This is not standard rails generator format but is less ambiguous than the standard ```:null``` option.

#### Folders

* The generator will create the folder:
  ```app/views/#{module_name}/#{tagable_name}```

#### Files

* The generator will create these files:

##### Migration

* A database migration file to build the database table with the requested fields:
  * ```db/migrate/#{timestamp}_create#{module_name}_#{tagable_name}.rb```

##### Model

* A model definition file with presence validations for the required fields, including tagable module, and ransackable attributes and associations for searching and sorting:
  * ```app/models/#{module_name}/#{tagable_name}.rb```

##### Policy

* A policy file matching the module pattern (typically defers all policy checks to the tag policy):
  * ```app/policies/#{module_name}/#{tagable_name}_policy.rb```

##### Controller

* A controller file with the standard RESTful actions deferring to the tagables controller, and safe parameters set to the defined fields:
  * ```app/controllers/#{module_name}/#{tagable_name.pluralize}_controller.rb```

##### Helper

* A helper file with module defined but no content:
  * ```app/helpers/#{module_name}/#{tagable_name.pluralize}_helper.rb```

##### Views

* A full suite of views built from templates and the specified fields:
  * ```app/views/#{module_name}/#{tagable_name.pluralize}/_form.html.erb```
  * ```app/views/#{module_name}/#{tagable_name.pluralize}/new.html.erb```
  * ```app/views/#{module_name}/#{tagable_name.pluralize}/edit.html.erb```
  * ```app/views/#{module_name}/#{tagable_name.pluralize}/index.html.erb```
  * ```app/views/#{module_name}/#{tagable_name.pluralize}/show.html.erb```
  * ```app/views/#{module_name}/#{tagable_name.pluralize}/_#{tagable_name}.html.erb```
  * ```app/views/#{module_name}/#{tagable_name.pluralize}/_#{tagable_name}_header.html.erb```
  * ```app/views/#{module_name}/#{tagable_name.pluralize}/_#{tagable_name}_row.html.erb```

##### Factories

* A factory file with fields defined (but no default values):
  * ```test/factories/#{module_name}/#{tagable_name.pluralize}.rb```

##### Model Tests

* A model test file with tests for ensuring the tagable link is correct, and for presence of required fields:
  * ```test/models/#{module_name}/#{tagable_name}_test.rb```

##### Policy Tests

* A policy test file with setup, which defers tests to the resource_policy_test helper:
  * ```test/policies/#{module_name}/#{tagable_name}_policy_test.rb```

##### Controller Tests

* A controller test file with setup, which defers tests to the tagable_test_patterns helper:
  * ```test/controllers/#{module_name}/#{tagable_name.pluralize}_controller_test.rb```

##### System Tests

* A system test file with template content:
  * ```test/system/#{module_name}/#{tagable_name.pluralize}_system_test.rb```

#### Edits

* The generator will make the following edits:

##### Routes

* In ```config/routes.rb```, two sets of routes are added.

1. The generator will look under the first occurrence of ```namespace:#{module_name}```
for a line ending```only: [:index, :new, :create]```, and insert ```#{tagable_name.pluralize}```
to the list of resources. If the line does not exist, the generator will log an error message.
2. The generator will then look for the occurrence of ```resources :tags, shallow: true do```, and under this will look for ```namespace :#{module_name}``` again. In the subsequent line ending ```except: [:index]```, the generator will again insert ```#{tagable_name.pluralize}``` to the list of resources. If the line does not exist, the generator will log an error message.

##### Constants

* If any enum fields have been specified (either :enum or :enum_translated), the generator will look for the file ```config/constants/#{module_name}.yml```. If found, a placeholder will be added for each enum requiring to be defined. If not found, a warning will be output.

##### Translations

* For each locale in I18n.available_locales, the generator will edit the files ```config/locales/#{module_name}/#{locale}/#{locale}.#{module_name}.models.yml```, inserting the model name at the end of the models section, and the attributes at the end of the attributes section. All translations will be set to null or "".
  * If any :enum_translated fields have been specified, the generator will include a plural of the translated enum attribute name after the attribute name in the attributes section, with a "# placeholder" comment.
  * The help and errors sections are not modified, these must be done manually if required.

* For each locale in I18n.available_locales, the generator will edit the files ```config/locales/#{module_name}/#{locale}/#{locale}.#{module_name}.views.yml```, appending the model name at the end of the file, with the standard actions translations. All translations will be set to null or "".
