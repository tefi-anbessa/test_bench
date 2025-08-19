# Testing Best Practices for Internationalized Applications

## Overview
Guidelines for writing system tests in internationalized applications to ensure tests work across all locales.

## Best Practices

### 1. Use Translations Consistently
- Always use `I18n.t()` for any hardcoded text that might be translated
- Reference translations directly in tests rather than hardcoding strings

### 2. Form Interactions
- Use translated label text in `fill_in` for form fields
- Example: `fill_in I18n.t('activerecord.attributes.user.email'), with: 'user@example.com'`

### 3. Button and Link Interactions
- Use translated text in `click_on` or `click_button`
- Example: `click_on I18n.t('helpers.submit.create', model: User.model_name.human)`

### 4. Assertions
- Use translated versions of success/error messages in assertions
- Example: `expect(page).to have_content(I18n.t('devise.registrations.signed_up'))`

### 5. Test Helpers
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

### 6. Test-Specific Selectors
- For frequently interacted elements, add `data-testid` attributes
- Example: `find("[data-testid='user-email']").click`
- This makes tests more resilient to UI text changes

### 7. Locale-Specific Tests
- Test critical paths in all supported locales
- Consider using a shared example group for locale-agnostic tests

### 8. Fixtures and Factories
- Ensure test data respects i18n requirements
- Consider using the `mobility` gem or similar for translated attributes if needed
