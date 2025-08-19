# Testing Best Practices for Internationalized Applications

## Overview
Guidelines for writing system tests in internationalized applications to ensure tests work across all locales.

## Best Practices

### 1. When to Test
- After modifying any factory, run `test/factories_test.rb`
- After modifying any model or model test, run `test/models_test.rb`

### 2. Use Translations Consistently
- Always use `I18n.t()` for any hardcoded text that might be translated
- Reference translations directly in tests rather than hardcoding strings

### 3. Form Interactions
- Use translated label text in `fill_in` for form fields
- Example: `fill_in I18n.t('activerecord.attributes.user.email'), with: 'user@example.com'`

### 4. Button and Link Interactions
- Use translated text in `click_on` or `click_button`
- Example: `click_on I18n.t('helpers.submit.create', model: User.model_name.human)`

### 5. Assertions
- Use translated versions of success/error messages in assertions
- Example: `expect(page).to have_content(I18n.t('devise.registrations.signed_up'))`

### 6. Test Helpers
- Consider adding a test helper to switch locales if needed
- Example:
  ```ruby
  def switch_locale(locale)
    I18n.locale = locale
    yield
  ensure
    I18n.locale = I18n.default_locale
  end
  ```

### 7. Test-Specific Selectors
- For frequently interacted elements, add `data-testid` attributes
- Example: `find("[data-testid='user-email']").click`
- This makes tests more resilient to UI text changes

### 8. Locale-Specific Tests
- Test critical paths in all supported locales
- Consider using a shared example group for locale-agnostic tests

### 9. Fixtures and Factories
- Ensure test data respects i18n requirements
- Consider using the `mobility` gem or similar for translated attributes if needed
