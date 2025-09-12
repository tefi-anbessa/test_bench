source "https://rubygems.org"
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby "3.3.5"

# Rails defaults:
# Bundle edge Rails instead: gem "rails", github: "rails/rails", branch: "main"
gem "rails", "~> 8.0.0"

# Use Propshaft for the asset pipeline [https://github.com/rails/propshaft]
gem "propshaft"

# Use the Puma web server [https://github.com/puma/puma]
gem "puma", ">= 6.0.0"

# Use JavaScript with ESM import maps [https://github.com/rails/importmap-rails]
gem "importmap-rails", "~> 2.0"

# Hotwire's SPA-like page accelerator [https://turbo.hotwired.dev]
gem "turbo-rails", "~> 2.0"

# Hotwire's modest JavaScript framework [https://stimulus.hotwired.dev]
gem "stimulus-rails", "~> 1.3"

# Build JSON APIs with ease [https://github.com/rails/jbuilder]
gem "jbuilder"

# Use Redis adapter to run Action Cable in production
gem "redis", "~> 4.0"

# Use Kredis to get higher-level data types in Redis [https://github.com/rails/kredis]
gem "kredis"

# Use Active Model has_secure_password [https://guides.rubyonrails.org/active_model_basics.html#securepassword]
# Inactive by default:
gem "bcrypt", "~> 3.1.7"

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem "tzinfo-data", platforms: %i[ mingw mswin x64_mingw jruby ]

# Reduces boot times through caching; required in config/boot.rb
gem "bootsnap", require: false

# CSS processing is handled by Propshaft

# Use Active Storage variants [https://guides.rubyonrails.org/active_storage_overview.html#transforming-images]
# Inactive by default:
# gem "image_processing", "~> 1.2"

# Address Ruby 3.3+ deprecation warnings
gem "ostruct"
gem "mutex_m"

# Added gems +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
gem 'bootstrap', '~> 5.3.0'
gem "faker"
gem 'rails-i18n', '~> 8.0'

# use gem 'flag-icons-rails' for internationalisation
gem 'flag-icons-rails'

# Use ransack for search and sort functionality.
gem 'ransack'

# Use pagy for pagination
gem "pagy", '~> 9.0'

# Use devise for access control
gem "devise", "~> 4.9"
gem 'devise-i18n'

# Use bootstrap_form for pretty easy forms.
gem "bootstrap_form", "~> 5.4"

# Use bootstrap_icons.
gem 'bootstrap-icons-helper'

# Using order_query for previous and next items in complex sort order.
# gem 'order_query', '~> 0.2.0'

# Use gems "rolify" and "pundit" for authorization
gem "rolify"
gem "pundit"

# End of added gems +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

group :development, :test do
# Rails defaults:
  # Use sqlite3 as the database for Active Record
  gem "sqlite3", "~> 2.0", ">= 2.1.0"

  # See https://guides.rubyonrails.org/debugging_rails_applications.html#debugging-with-the-debug-gem
  gem "debug", platforms: %i[ mri mingw x64_mingw ]

  # Test factories for generating test data and development fixtures
  gem 'factory_bot_rails', '~> 6.5'
end

group :development do
# Rails defaults:
  # Use console on exceptions pages [https://github.com/rails/web-console]
  gem "web-console"

  # Add speed badges [https://github.com/MiniProfiler/rack-mini-profiler]
  # gem "rack-mini-profiler"

  # Speed up commands on slow machines / big apps [https://github.com/rails/spring]
  # gem "spring"
end

group :test do
  # System testing [https://guides.rubyonrails.org/testing.html#system-testing]
  gem "capybara", "~> 3.39"
  gem "selenium-webdriver", "~> 4.10"
  gem "webdrivers", "~> 5.3"

  # Test database management
  gem "database_cleaner-active_record"

  # Testing framework
  gem "minitest", "~> 5.15"
  gem "minitest-reporters", "~> 1.5"
  gem "rails-controller-testing", "~> 1.0"

  # Test automation
  gem "guard", "~> 2.18"
  gem "guard-minitest", "~> 2.4"
end

# Added gems
group :production do
  gem "pg",         "1.3.5"
end
