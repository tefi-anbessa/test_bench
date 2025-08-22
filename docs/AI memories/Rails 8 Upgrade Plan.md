# Rails 8 Upgrade Plan - PAUSED

> **Status Update (2025-08-21)**: Upgrade work has been paused. The application is not yet ready for Rails 8 deployment. This document has been updated to reflect completed actions and current status.

## Current Environment
- Rails Version: 7.0.8.4 → 8.0.2.1 (upgraded in development)
- Ruby Version: 3.1.2 → 3.3.5 (upgraded in development)
- Using: importmaps, Turbo, Stimulus, Bootstrap 5.3.5
- Asset Pipeline: Migrated from Sprockets to Propshaft
- **Current Status**: Development environment upgraded, not ready for production

## Phase 1: Preparation ✅ COMPLETED

1. **Create a new git branch**
   ```bash
   git checkout -b rails8
   ```

2. **Update Ruby version** (3.3.5 required for Rails 8)
   ```bash
   # Install Ruby 3.3.5
   rbenv install 3.3.5
   
   # Update .ruby-version and Gemfile
   echo "3.3.5" > .ruby-version
   
   # Set local Ruby version
   rbenv local 3.3.5
   ```

3. **Update Bundler and RubyGems**
   ```bash
   # Install latest Bundler
   gem install bundler
   
   # Update RubyGems
   gem update --system
   ```

## Phase 2: Gem Updates ✅ COMPLETED

Completed on 2025-08-21:
- Updated Rails to 8.0.2.1
- Updated Ruby to 3.3.5
- Updated all dependencies
- Resolved SQLite3 version conflicts
- Updated Puma to 6.6.1

1. **Update Rails and related gems** in Gemfile:
   ```ruby
   # Current: gem "rails", "~> 7.0.8", ">= 7.0.8.4"
   gem "rails", "~> 8.0.0"
   
   # Update these related gems
   gem "importmap-rails", "~> 2.0"
   gem "turbo-rails", "~> 2.0"
   gem "stimulus-rails", "~> 1.3"
   
   # Rails 8 uses Propshaft by default instead of Sprockets
   gem "propshaft"
   
   # Keep sassc-rails if needed, but consider moving to Propshaft
   gem "sassc-rails"
   
   gem "rails-i18n", "~> 8.0"
   ```

2. **Update development/test gems**:
   ```ruby
   group :development, :test do
     # Updated to latest stable version compatible with Rails 8
     gem "factory_bot_rails", "~> 6.5"
     # Update other development/test gems as needed
   end
   ```

3. **Update database gems** as needed (if using PostgreSQL/MySQL)

### Bundle Update Output
```
Installing prettyprint 0.2.0
Installing erb 5.0.2 with native extensions
Installing stringio 3.1.7 (was 3.1.1) with native extensions
Installing io-console 0.8.1 (was 0.7.2) with native extensions
Installing thor 1.4.0 (was 1.3.2)
Installing ffi 1.17.2 (x86_64-darwin) (was 1.17.0)
Installing tilt 2.6.1 (was 2.4.0)
Installing matrix 0.4.3 (was 0.4.2)
Installing regexp_parser 2.11.2 (was 2.9.2)
Installing childprocess 4.1.0
Installing coderay 1.1.3
Installing database_cleaner-core 2.0.1
Installing orm_adapter 0.5.0
Installing rb-fsevent 0.11.2
Installing lumberjack 1.4.0 (was 1.2.10)
Installing nenv 0.3.0
Installing shellany 0.0.1
Installing method_source 1.1.0
Installing guard-compat 1.2.1
Installing redis 4.8.1
Installing ruby-progressbar 1.13.0
Installing pagy 9.4.0 (was 9.1.0)
Installing rexml 3.4.1 (was 3.3.9)
Installing rolify 6.0.1
Installing rubyzip 2.4.1 (was 2.3.2)
Installing websocket 1.2.11
Installing sqlite3 1.7.3 (x86_64-darwin)
Installing i18n 1.14.7 (was 1.14.6)
Installing tzinfo 2.0.6
Installing nokogiri 1.18.9 (x86_64-darwin) (was 1.16.7)
Installing rack-session 2.1.1
Installing rack-test 2.2.0 (was 2.1.0)
Installing rackup 2.2.1
Installing sprockets 4.2.2 (was 4.2.1)
Installing warden 1.2.9
Installing websocket-driver 0.8.0 (was 0.7.6) with native extensions
Installing net-protocol 0.2.2
Installing addressable 2.8.7
Installing autoprefixer-rails 10.4.21.0 (was 10.4.19.0)
Installing puma 5.6.9 with native extensions
Installing pp 0.6.2
Installing sassc 2.4.0 with native extensions
Installing rb-inotify 0.11.1
Installing psych 5.2.6 (was 5.1.2) with native extensions
Installing reline 0.6.2 (was 0.5.10)
Installing bootsnap 1.18.6 (was 1.18.4) with native extensions
Installing notiffany 0.1.3
Installing pry 0.15.2 (was 0.14.2)
Installing guard-minitest 2.4.6
Installing minitest-reporters 1.5.0
Installing selenium-webdriver 4.2.0
Installing faker 3.5.2 (was 3.5.1)
Installing activesupport 8.0.2.1 (was 7.0.8.6)
Installing loofah 2.24.1 (was 2.23.1)
Installing xpath 3.2.0
Installing net-imap 0.5.9 (was 0.5.0)
Installing net-smtp 0.5.1 (was 0.5.0)
Installing listen 3.9.0
Installing formatador 1.2.0 (was 1.1.0)
Installing webdrivers 5.0.0
Installing rdoc 6.14.2 (was 6.7.0)
Installing rails-html-sanitizer 1.6.2 (was 1.6.0)
Installing rails-dom-testing 2.3.0 (was 2.2.0)
Installing globalid 1.2.1
Installing activemodel 8.0.2.1 (was 7.0.8.6)
Installing factory_bot 6.5.5 (was 6.5.4)
Installing pundit 2.5.0 (was 2.4.0)
Installing capybara 3.40.0
Installing mail 2.8.1
Installing guard 2.18.0
Installing irb 1.15.2 (was 1.14.1)
Installing actionview 8.0.2.1 (was 7.0.8.6)
Installing activejob 8.0.2.1 (was 7.0.8.6)
Installing activerecord 8.0.2.1 (was 7.0.8.6)
Installing kredis 1.8.0 (was 1.7.0)
Installing debug 1.11.0 (was 1.9.2) with native extensions
Installing actionpack 8.0.2.1 (was 7.0.8.6)
Installing jbuilder 2.14.1 (was 2.13.0)
Installing database_cleaner-active_record 2.2.2
Installing ransack 4.3.0 (was 4.2.1)
Installing actioncable 8.0.2.1 (was 7.0.8.6)
Installing activestorage 8.0.2.1 (was 7.0.8.6)
Installing actionmailer 8.0.2.1 (was 7.0.8.6)
Installing railties 8.0.2.1 (was 7.0.8.6)
Installing actionmailbox 8.0.2.1 (was 7.0.8.6)
Installing actiontext 8.0.2.1 (was 7.0.8.6)
Installing responders 3.1.1
Installing rails-i18n 8.0.2 (was 7.0.9)
Installing factory_bot_rails 6.5.0
Installing importmap-rails 2.2.2 (was 2.0.3)
Installing stimulus-rails 1.3.4
Installing turbo-rails 2.0.16 (was 2.0.11)
Installing web-console 4.2.1
Installing sprockets-rails 3.5.2
Installing bootstrap_form 5.4.0
Installing propshaft 1.2.1
Installing rails-controller-testing 1.0.5
Installing rails 8.0.2.1 (was 7.0.8.6)
Installing devise 4.9.4
Installing devise-i18n 1.14.0 (was 1.12.1)
Installing sassc-rails 2.1.2
Installing bootstrap 5.1.3
Installing sass-rails 6.0.0
Installing flag-icons-rails 3.4.6.1
```

### SQLite3 and Puma Update

1. **Updated sqlite3** to version 2.1.0+ for Ruby 3.3.5 compatibility
   ```ruby
   # In Gemfile
   gem "sqlite3", "~> 2.0", ">= 2.1.0"
   ```

2. **Updated Puma** to version 6.6.1 for Rails 8 compatibility
   ```ruby
   # In Gemfile
   gem "puma", ">= 6.0.0"
   ```

3. **Ran Rails update task**
   ```bash
   bin/rails app:update
   ```
   This updated several configuration files including:
   - config/application.rb
   - config/puma.rb
   - config/environments/*.rb
   - config/initializers/*.rb
   - bin/setup
   - Public error pages (400.html, 404.html, etc.)

4. **Resolved SQLite3 version conflict**
   - Updated SQLite3 to version 3.50.3
   - Ran `bundle clean --force && bundle install` to clean up old gem versions
   - Verified SQLite3 version with `rails runner 'puts "SQLite3 version: #{ActiveRecord::Base.connection.select_value("SELECT sqlite_version()")}'`

## Phase 3: Configuration Updates ✅ COMPLETED

Completed on 2025-08-21:
- Ran `bin/rails app:update`
- Updated configuration files
- Added new framework defaults in `config/initializers/new_framework_defaults_8_0.rb`
- Updated Active Storage configuration
- Successfully ran migrations

1. **Run the update task**:
   ```bash
   bundle update rails
   bin/rails app:update
   rails active_storage:update
   ```
   
   When running `rails app:update`, you'll be prompted to overwrite several files. Here are the key files that were updated:
   - `config/application.rb`
   - `config/puma.rb`
   - `config/environments/development.rb`
   - `config/environments/production.rb`
   - `config/environments/test.rb`
   - `config/initializers/*.rb`
   - `bin/setup`
   - Public error pages (400.html, 404.html, etc.)

2. **Review and update**:
   - New initializers in `config/initializers/`
   - Updated configuration in `config/application.rb`
   - New framework defaults in `config/initializers/new_framework_defaults_8_0.rb`

3. **Update database configuration** if needed

### Active Storage Migrations

Run the following command to update Active Storage:

```bash
rails active_storage:update
```

Run the migrations to update the database schema:

```bash
bin/rails db:migrate
```

Successfully executed migrations:
1. `20250821044642_add_service_name_to_active_storage_blobs.active_storage.rb`
   - Added service_name column to active_storage_blobs
2. `20250821044643_create_active_storage_variant_records.active_storage.rb`
   - Created active_storage_variant_records table
3. `20250821044644_remove_not_null_on_active_storage_blobs_checksum.active_storage.rb`
   - Removed NOT NULL constraint from checksum column in active_storage_blobs

### Terminal Output from Rails Update

```
$ bin/rails app:update

    conflict  config/initializers/filter_parameter_logging.rb
Overwrite /Users/frank/RailsProjects/Rails7/test_bench/config/initializers/filter_parameter_logging.rb? (enter "h" for help) [Ynaqdhm] Y
       force  config/initializers/filter_parameter_logging.rb
   identical  config/initializers/inflections.rb
      create  config/initializers/new_framework_defaults_8_0.rb
      remove  config/initializers/cors.rb
       exist  bin
      create  bin/dev
   identical  bin/rails
   identical  bin/rake
    conflict  bin/setup
Overwrite /Users/frank/RailsProjects/Rails7/test_bench/bin/setup? (enter "h" for help) [Ynaqdhm] Y
       force  bin/setup
       exist  public
      create  public/400.html
    conflict  public/404.html
Overwrite /Users/frank/RailsProjects/Rails7/test_bench/public/404.html? (enter "h" for help) [Ynaqdhm] Y
       force  public/404.html
      create  public/406-unsupported-browser.html
    conflict  public/422.html
Overwrite /Users/frank/RailsProjects/Rails7/test_bench/public/422.html? (enter "h" for help) [Ynaqdhm] Y
       force  public/422.html
    conflict  public/500.html
Overwrite /Users/frank/RailsProjects/Rails7/test_bench/public/500.html? (enter "h" for help) [Ynaqdhm] Y
       force  public/500.html
      create  public/icon.png
      create  public/icon.svg
   identical  public/robots.txt

$ rails active_storage:update
   identical  active_storage/config/routes.rb
   identical  config/storage.yml
   identical  config/initializers/active_storage.rb
   identical  config/environments/development.rb
   identical  config/environments/production.rb
   identical  config/environments/test.rb
   identical  db/migrate/20250221114800_create_active_storage_tables.active_storage.rb
```

2. **Review and update**:
   - New initializers in `config/initializers/`
   - Updated configuration in `config/application.rb`
   - New framework defaults in `config/initializers/new_framework_defaults_8_0.rb`

3. **Update database configuration** if needed

## Phase 4: Code Updates ⏸️ PARTIALLY COMPLETED

### Completed:
- Updated Bootstrap to 5.3.5
- Configured importmap for local node modules
- Updated JavaScript dependencies
- Removed Bootstrap icons from assets, reinstalled bootstrap-icons in node_modules with npm.
- Installed bootstrap-icons-helper gem.

### Pending:
- Review and update deprecated methods
- Update view helpers if needed
- Complete full codebase audit for Rails 8 compatibility

1. **Update JavaScript Dependencies**:
   - Install required npm packages locally:
     ```bash
     npm install bootstrap@5.3.5 @popperjs/core
     ```
   - Configure importmap to use local node modules:
     ```ruby
     # config/importmap.rb
     pin "bootstrap", to: "bootstrap/dist/js/bootstrap.bundle.min.js"
     pin "@popperjs/core", to: "@popperjs/core/dist/umd/popper.min.js"
     ```
   - Update application.js to use local imports
   - Run importmap update:
     ```bash
     bin/importmap update
     ```
   - Check Stimulus controllers for compatibility

2. **Update Bootstrap** (required for Rails 8):
   ```ruby
   # Gemfile
   gem 'bootstrap', '~> 5.3.5'  # Updated to latest 5.3.x version
   ```
   - Run bundle update bootstrap

3. **Address deprecations**:
   - Update any deprecated methods
   - Check for `ActiveSupport::Dependencies` changes
   - Update view helpers if needed

## Phase 4.5: Address Deprecation Warnings and Test Updates ✅ COMPLETED

Completed on 2025-08-21:
- Added required gems for Ruby 3.3+ compatibility
- Resolved all deprecation warnings
- Fixed minitest-reporters configuration in `test/test_helper.rb` to be compatible with Rails 8:
  - Updated reporter initialization to use `Minitest::Reporters::DefaultReporter`
  - Added proper error handling for test output

1. **Added required gems** to address Ruby 3.3+ deprecation warnings:
   ```ruby
   # In Gemfile
   gem "ostruct"  # For Ruby 3.5+ compatibility
   gem "mutex_m"   # For Ruby 3.4+ compatibility
   ```

2. **Updated dependencies**:
   ```bash
   bundle install
   ```

3. **Verified resolution** by running Rails commands without deprecation warnings.

## Phase 5: Testing ⏸️ NOT STARTED

### Next Steps (When Resuming):
1. **Run test suite**:
   ```bash
   bin/rails test
   bin/rails test:system
   ```

2. **Manual testing**:
   - Test all major workflows
   - Check JavaScript functionality
   - Verify file uploads if using Active Storage

## Phase 6: Deployment ⏸️ ON HOLD

### Deployment is currently on hold. When ready to proceed:
1. **Update deployment configuration** if needed
2. **Update CI/CD pipelines**
3. **Deploy to staging** first for testing

## Phase 7: Post-Upgrade ⏸️ ON HOLD

### To be completed after successful testing and when ready for deployment:
1. **Monitor application** for issues
2. **Update documentation** with new requirements
3. **Clean up** any temporary code

## Current Status: PAUSED

### Time Spent So Far: ~4-6 hours
### Remaining Work: ~4-6 hours (estimated)

## Notes
- Created: 2025-08-20
- Last Updated: 2025-08-21
- Status: Development upgrade completed, deployment on hold
