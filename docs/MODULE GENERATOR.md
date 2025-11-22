# MODULE GENERATOR

## INTRODUCTION

The application Project Assistant (PA) provides shared functionality for all types of engineering design elements within a project. The tag is the linkage for all pertinent information about the element. The name tags originated because identifying tags containing this core information were physically attached to the element. In this application, the tag model contains the core information about the element, required for all tags across all disciplines. Detailed information about each element is stored in a tagable model, explained below.

### Tags

  * Tag number: it is a compound structure of prefix, serial number, and optional suffix. This structure is not universal but very common in engineering practice.
  * Service description: a brief description of the function of the element.
  * Discipline: the discipline to which the tag belongs.
  * Stage: the stage is a mechanism to allow grouping tags within a project. It can be used at the project's discretion. E.g. a project may use stages for different phases of construction.
  * Location: the physical location field also allows grouping of tags.

### Disciplines

  * Disciplines are unique within a project, and thus provide the connection from a tag to its project.
  * Disciplines are used to group tags.
  * Disciplines provide some built in functionality, by linking to modules (see below).
  * Discipline related functionality includes:
    * Specify the schema of the tag prefixes in the discipline.
    * Specify the colour swatch for forms and tables.
  * Ideally, only standard disciplines would be required. These are defined in the constants file.
  * However, it is possible to create custom disciplines, as required. 
  * Discipline names are one of the very few parts of the application where translation of the application generated user facing text is not presently provided. This is because translation would be required for the database content, not the configuration. Until a content translation solution is implemented, custom disciplines are one option for projects to provide translated discipline names which link back to core disciplines by their module connection.

### Tagables

  * The next level of information for tagged elements is referenced in this application as the tagable data. This is not engineering terminology, it is Rails conventional naming for delegated types (also for polymorphic associations, of which delegated types are a special case). Delegated type is a Rails database concept allowing disparate model types to share common data.
  * A note about spelling: Many sources claim that the correct spelling is taggable, including material written by DHH himself. However, tagable is the convention rails uses for a delegated type from tag, so we have gone with that rather than override convention.
  * Tagables are the first level of separation of information after the tag, as different elements will require different information. E.g. within the electrical discipline, a motor will require different information than a switchboard.
  * The tagable model can be considered to be the datasheet for the element type.
  * As such, the tagable model should incorporate all information required to specify the element for purchase.

### Tagable Types

  * As the application grows to cover more different design elements, the number of tagable types will grow significantly.
  * Although the underlying models for different types of elements may not have much in common, the user actions associated with creating, editing, viewing and deleting them are very consistent.
  * To avoid repetition of development effort, the tagable models have been abstracted where possible.
  * Partial abstraction has been achieved for controllers, policies, and their associated tests.

### Modules

  * To manage the large number of tagable models that are required, they are stored in sub-folders of the main application.
  * In Ruby on Rails terminology, the sub-folders become Ruby modules.
  * Each core discipline has an associated module, which is also the name of the sub-folder.
  * The module provides a "namespace" which is Rails terminology, meaning that names within the module must be unique, but can be the same as names in other modules.
  * A generator is provided for creating all the file structure and edits required for a new module.

## MODULE GENERATOR SPECIFICATION

* General requirements
  * All application generators are namespaced under the application name ProjectAssistant. This prevents name clashes with other gems and rails standard generators.
  * The generator will create the folders, files and edits required to add a new module.
  * The main benefits of using a generator are:
    * Consistent file structure and edits
    * Reduced development time
* Specific requirements
  * The generator itself is reasonably self documented, refer to ```lib/generators/project_assistant/module_generator.rb```.
  * Here is a more detailed explanation:
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
        * config/locales/#{module_name}/#{locale}.#{module_name}.views.yml
    * The edits made are:
      * In ```config/routes.rb```, the following line is added:
        ```ruby
        namespace :#{module_name} do
          # Add your routes here
        end
        ```
      * In ```config/factory_bot.rb```, the following line is added:
        ```ruby
        config.factory_bot.definition_file_paths << Rails.root.join('test', '#{@module_name.underscore}', 'factories')
        ```

### Module Generator Usage

  * The module generator is used as follows:
    * Run the generator with the following command:
      ```bash
      rails g project_assistant:module <module_name>
      ```
    <module_name> should be provided as CamelCase but will be converted to snake_case for file names and CamelCase for class or module names within the generator.
  * If prompted, it means the generator has found an existing folder, and will ask if you want to proceed.
    * If you are sure that the existing folder does not contain anything that needs to be retained, respond with 'y'. 
    * If you are not sure, respond with 'n'. The generator will abort.
  * The generator will create the folders, files and edits required to add a new module. The terminal log will show the files and edits created.
