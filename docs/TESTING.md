# Testing Guide

## Table of Contents
- [Test Driven Development (TDD)](#test-driven-development-tdd)
- [Testing Setup](#testing-setup)
  - [Models](#models)
  - [Factories](#factories)
  - [Controllers](#controllers)
  - [Policies](#policies)
  - [System Tests](#system-tests)
  - [Test Framework](#test-framework)
- [Best Practices](#best-practices)
  - [When to Test](#1-when-to-test)
  - [Using Translations](#2-using-translations)
  - [Form Interactions](#3-form-interactions)
  - [Button and Link Interactions](#4-button-and-link-interactions)
  - [Assertions](#5-assertions)
  - [Test Helpers](#6-test-helpers)
  - [Test-Specific Selectors](#7-test-specific-selectors)
  - [Locale-Specific Tests](#8-locale-specific-tests)
  - [Fixtures and Factories](#9-fixtures-and-factories)

## Test Driven Development (TDD)

This project prefers Test Driven Development (TDD) principles. Follow these guidelines:

1. Write a precis of how the module should behave in an appropriate file, e.g. `docs/DEVELOPER_NOTES.md`
2. Create necessary test data factories, if justified
3. Write the test code with specific data setup
4. Implement the feature to pass the tests
5. Refactor while keeping tests passing

During TDD:
- Aim to keep the test design unchanged while modifying the implementation
- Be prepared to recognize when:
  - There are syntax or implementation errors
  - The test doesn't meet the design objective
- Know when TDD might not be appropriate

## Testing Setup

### Models

- **Location**: `app/models/`
- **Test Location**: `test/models/`
- **Testing Guidelines**:
  - Test all model validations (both model and database level)
  - Test all associations and relationships
  - Test any custom methods and scopes
  - Include testing of validation error messages
  - Keep test data setup specific to each test case

### Factories

- **Location**: `test/factories/`
- **Guidelines**:
  - Use FactoryBot for test data generation
  - Each model should have a corresponding factory
  - Define the minimum valid set of attributes for each factory
  - Use traits for common variations of models
  - Avoid testing validations through factory traits
  - Keep factories simple and maintainable
  - Test test/factories_test.rb will test all found factories and traits automatically.
  - Add any specialized model tests to test/models_test.rb if required.

### Controllers

- **Location**: `app/controllers/`
- **Test Location**: `test/controllers/`
- **Testing Approach**:
  - Test each action's happy path
  - Test devise authentication failure
  - Test pundit authorization success and failure paths
  - Test controller scope where it differs from pundit scope or no pundit scope provided
  - Test response formats (HTML, JSON, etc.)
  - Test redirections and status codes
  - Test flash messages

- **Don't Test**:
  - Model behavior (test in model tests)
  - Permission detail (test in policy tests)
  - View rendering details (test in system tests)
  - Complex business logic (test in service objects)

### Policies

- **Location**: `app/policies/`
- **Test Location**: `test/policies/`
- **Testing Guidelines**:
  - Test each permission method (e.g., `show?`, `update?`)
  - Test with different user roles
  - Test with different resource states
  - Include both positive and negative test cases
  - Keep policy tests focused on authorization logic

### System Tests

- **Location**: `test/system/`
- **Testing Approach**:
  - Test complete user workflows
  - Test all available paths through the application
  - Don't try to exhaustively test failure paths, they should be difficult to initiate from system tests if the application is well designed. Rely on controller tests for that.
  - Test JavaScript interactions
  - Test responsive design (if applicable)
  - Test across different browsers (if needed)

- **TODO**:
  - Add more detailed guidelines for system testing
  - Include examples of common test patterns
  - Document best practices for dealing with async behavior

### Test Framework

This project uses the following testing tools:

- **Minitest** - Core testing framework
- **Minitest Reporters** - Enhanced test output
- **Minitest Colorize** - Color-coded test results
- **Minitest Parallel** - Parallel test execution
- **Capybara** - Integration testing
- **Selenium WebDriver** - Browser automation
- **Webdrivers** - Browser driver management
- **SimpleCov** - Code coverage (TODO: Configure)
- **Mocha** - Mocking framework
- **Guard** and **Guard-minitest** - Automatic test runner

**Example Test Run Command**:
```bash
# Run all tests
rails test

# Run specific test file
rails test test/models/user_test.rb

# Run specific test method
rails test test/models/user_test.rb:15
```

## Best Practices

### 1. Using Guard

- Guard is configured by Guardfile to automatically run relevant tests when files change.
- Basic configuration looks at the name of the file that has changed, and runds the corresponding test file. For example, if you modify either `app/models/user.rb` or `test/models/user_test.rb`, Guard will run `test/models/user_test.rb`.
- Advanced configuration in this application includes:
  - Any change to test/test_helper.rb will run the full test suite, so take care!
  - Any change to test/helpers/tagable_test_patterns.rb or app/controllers/concerns/tagables_controller.rb will run all tagable controller tests.
- Guard is best run in its own terminal window. It can be started with `bundle exec guard` and stopped with `quit` or `exit`.
- If Guard gets unresponsive, you can recover it with ctrl c, make sure to exit and restart.
- Keep guard running and visible most of the time when developing models, controllers and views. Save frequently, thereby incrementally checking that you have not introduced errors.
- When working with system tests, it is best to deactivate Guard, as system testing is very time consuming. When Guard is deactivated, you can run system tests incrementally with `rails test test/system/test/system/projects_system_test.rb:30`, for example.

### 1. When to Test

- After modifying any factory, run:
  rails test test/factories_test.rb

- After modifying any model or model test, run:
  rails test test/models_test.rb

### 2. Using Translations

- Always use `I18n.t()` for any user-facing messages
- Reference translations directly in tests rather than hardcoding strings
- Example:
  ```ruby
  # Good
  assert_text I18n.t('activerecord.errors.messages.blank')
  
  # Bad
  assert_text "can't be blank"
  ```

### 3. Form Interactions

- Use translated label text in `fill_in` for form fields
- Example:
  ```ruby
  fill_in I18n.t('activerecord.attributes.user.email'), with: 'user@example.com'
  ```

### 4. Button and Link Interactions

- Use translated text in `click_on` or `click_button`
- Example:
  ```ruby
  click_on I18n.t('helpers.submit.create', model: User.model_name.human)
  ```

### 5. Assertions

- Use translated versions of success/error messages in assertions
- Example:
  ```ruby
  assert_text I18n.t('devise.registrations.signed_up')
  ```

### 6. Test Helpers

Consider adding test helpers for common patterns:

```ruby
# Switch locale for a block of tests
def switch_locale(locale)
  I18n.locale = locale
  yield
ensure
  I18n.locale = I18n.default_locale
end

# Sign in as a specific user
def sign_in_as(user)
  post user_session_path, params: {
    user: {
      email: user.email,
      password: 'password'
    }
  }
  follow_redirect!
end
```

### 7. Test-Specific Selectors

- Add `data-testid` attributes for frequently interacted elements
- Example:
  ```erb
  <!-- In view -->
  <div data-testid="user-email"><%= user.email %></div>
  
  <!-- In test -->
  find("[data-testid='user-email']").click
  ```
- This makes tests more resilient to UI text changes

### 8. Locale-Specific Tests

- Test critical paths in all supported locales
- Use shared examples for locale-agnostic tests:
  ```ruby
  shared_examples 'a localized page' do |locale|
    before { I18n.locale = locale }
    
    it 'displays the correct title' do
      expect(page).to have_title(I18n.t('home.index.title'))
    end
  end
  
  describe 'home page' do
    context 'in English' do
      it_behaves_like 'a localized page', :en
    end
    
    context 'in Spanish' do
      it_behaves_like 'a localized page', :es
    end
  end
  ```

### 9. Fixtures and Factories

- Ensure test data respects i18n requirements
- [TODO] For translated attributes, use the `mobility` gem or similar
- Example with Mobility:
  ```ruby
  # In factory
  trait :with_translations do
    transient do
      title_en { 'English Title' }
      title_es { 'Título en español' }
    end
    
    after(:build) do |record, evaluator|
      record.title_en = evaluator.title_en
      record.title_es = evaluator.title_es
    end
  end
  ```
