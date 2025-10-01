# Rails Internationalization (i18n) Structure

This directory contains all translation files for the application. As the application grows, we're gradually reorganizing translations for better maintainability.

## Current Structure

```
config/locales/
├── views.en.yml        # General view translations (English)
├── views.kh.yml        # General view translations (Khmer)
├── models/            # Model-specific translations
│   ├── user.en.yml
│   ├── user.kh.yml
│   └── ...
└── electrical/        # Electrical domain-specific translations
    ├── en.yml
    └── kh.yml
```

## Organization Guidelines

### For New Features
1. **Domain-Specific Translations** (e.g., electrical, mechanical) should go in their own subdirectories.
   ```
   config/locales/
   └── [domain]/
       ├── en.yml
       └── kh.yml
   ```

2. **Model-Specific Translations** should go in the `models/` directory.
   ```
   config/locales/models/
   ├── user.en.yml
   ├── user.kh.yml
   ├── project.en.yml
   └── project.kh.yml
   ```

3. **General View Translations** can remain in the root locale files if they don't fit elsewhere.

### Translation Keys
- Use nested namespaces that match the application structure
- Keep keys in snake_case
- Group related translations under common namespaces

### Adding a New Language
1. Create corresponding `.yml` files in each directory
2. Update `config/application.rb` if the language requires special loading
3. Add the language to the language selector if needed

## Best Practices
- Keep translations close to where they're used
- Avoid duplication by using YAML references (`<<: *anchor_name`)
- Use descriptive keys that indicate where they're used
- Add comments for context when the meaning isn't obvious

## Maintenance
When updating translations:
1. Update both English and Khmer versions
2. Keep the structure consistent between language files
3. Update this README if you introduce new organizational patterns
