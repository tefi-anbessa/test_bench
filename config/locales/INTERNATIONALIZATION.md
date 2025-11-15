# Rails Internationalization (i18n) Locales Structure

## Organization Guidelines

### Level 1

- A folder is provided for each functional module in the application.
- The core module is required, others are optional.

### Level 2

- Within each module folder, a folder is provided for each language implemented.

### Level 3

- Language conversion .yml files reside at level 3.
- Filenames should be prefaced by the language code.
- The only exception is that where translations are provided from an external source, they may keep the origin naming convention. (E.g. devise.en.yml, devise.km.yml)

#### Core Functions

- At level 3, the core application provides all translations for the core functions in a file named simply with the language code (e.g. core/en/en.yml, core/km/km.yml). Extension modules should not use these file names.
- Core functions are generally applicable to rails workflow, such as actions, views, menu items, etc.
- The core/xx/ folder also includes files for:
  - views: the views.yml files include all translations that can be short-cut using the i18n system based on the controller name, for the core resources with UI: users, roles, projects, tags.
  - models: the models.yml files include the activerecord translations that rails uses by default for validation messages, labels for fields, field help, etc.
  - a devise.yml file for translations required for the devise gem, externally provided. Translations are available for many languages at github.
  - a rolify.yml file for translations associated with the Role Based Access Control (RBAC) system.
  - a discipline.yml file for translations of some "standard" disciplines, along with translations for the tag prefix schema and parsing system.

#### Extension Modules

- At level 3, extension modules should provide their own translation files for views, models, constants, special messages, and any other resources that require translations.

## Adding a New Module

- Copy and paste the dummy folder config/locales/new_module to locales, and rename it with the name of the new module.
- This simply provides a sub-folder for each language.
- Copy the xx/views.yml and xx/models.yml files from another module base language to set the format.
- Replace the content with the required attributes for the new module for the base language, ensuring the keys are consistent with the new code.
- Ensure that testing covers at least the key selection for the new code.
- Copy and paste the files to the other language folders and replace the translations without affecting the keys.

## Adding a New Language

- Use ISO 639 international language codes from [www.unicode.org/iso15924/iso15924-codes.html](https://en.wikipedia.org/wiki/List_of_ISO_639_language_codes).
- Edit config/application.rb to add the new language code to the I18n.available_locales array.
- Choose a flag for the new language from the flag icons in app/assets/images/flags. This icon is presented in the application header for selecting locale, in case the user does not recognise the language of the text.
- If the new language code is not the same as an appropriate flag code in the flag icons, add the code translation in app/helpers/application_helper.rb flag_code helper.
- Be sensitive around flags, many language groups don't necessarily respect the national flag of the land where they live.
- Add the new language to each core language locale file (core/en.yml etc). under :locales. [HOLD]- there doesn't seem to be much sense in translating language names - users need to recognise their own language when selecting a locale.
- Add the new language folder to each module folder.
- Copy all files from one of the existing languages to the new language, for each module.
- Rename the files with the new language code.
- Translate the content of the files without affecting the keys.
- Add an empty folder to config/locales/new for the new language, so it will be included when a new module is created.

## File Structure

```plaintext
config/locales/
├── core/
│   ├── en/                 # English language
│   │   ├── en.yml          # Core translations (actions, menus, etc.)
│   │   ├── en.models.yml   # ActiveRecord model and attribute translations
│   │   ├── en.views.yml    # View translations - headers, tiles, messages
│   │   ├── en.discipline.yml # Discipline names and codes
│   │   ├── en.rolify.yml   # RBAC role translations
│   │   └── en.discipline.yml      # Discipline translations
│   └── km/                 # Khmer language
│       ├── km.yml
│       ├── km.models.yml
│       ├── km.views.yml
│       └── km.discipline.yml      # Discipline translations
└── [module]/
    ├── en/                         # English language for module
    │   ├── en.[module].yml         # Module-specific translations if required
    │   ├── en.[module].models.yml  # ActiveRecord model and attribute translations
    │   ├── en.[module].views.yml   # View translations - headers, tiles, messages
    │   └── (additional files if required)
    └── km/                         # Khmer language for module
        ├── km.[module].yml
        ├── km.[module].models.yml
        └── etc.
```

## Usage

### Translation Keys

- Use nested namespaces that match the application structure
- Keep keys in snake_case
- Group related translations under common namespaces

### Best Practices

- Keep translations close to where they're used
- Avoid duplication by using YAML references (`<<: *anchor_name`)
- Use descriptive keys that indicate where they're used
- Add comments for context when the meaning isn't obvious

### Maintenance

When updating translations:

1. Be sure to update all language versions.
2. Keep the .yml structure exactly consistent between language files.
3. Never alter keys without thorough retesting, it is not always obvious where translations are used.
4. Update this document if you introduce new organizational patterns.
