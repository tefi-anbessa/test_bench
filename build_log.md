rails new [app_name]
set up repo on github
run git initialize baseline and push to remote
git branch for setting up gemfile
gemfile: uncomment some rails standard issue lines:
gem "bcrypt", "~> 3.1.7"
gem "sassc-rails"
gem "redis", "~> 4.0"
gem "kredis"



add gems to core:

# Added gems +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
gem 'bootstrap', '~> 5.1.3'
gem "faker"
gem 'rails-i18n', '~> 7.0.0'

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

# Use rolify and Pundit for authorization
gem "rolify"

add gems to testing:

group :test do
  # Use system testing [https://guides.rubyonrails.org/testing.html#system-testing]
  gem "capybara"
  gem "selenium-webdriver"
  gem "webdrivers",               "5.0.0"
  gem "rails-controller-testing", "1.0.5"
  gem "minitest",                 "5.15.0"
  gem "minitest-reporters",       "1.5.0"
  gem "guard",                    "2.18.0"
  gem "guard-minitest",           "2.4.6"

set database gems in development and testing

group :development, :test do
# Rails defaults:
  # Use sqlite3 as the database for Active Record
  gem "sqlite3", "~> 1.4"

set production database gem as required, eg:

group :production do
  gem "pg",         "1.3.5"

gem devise:
gem devise_i18n

Read both Read_me files at https://github.com/heartcombo/devise and https://github.com/tigrish/devise-i18n
before deciding how to go about internationali9zation.

rails g controller site home help about contact

Internationalize the app at this point. Devise should not need much intervention
for forms but error messages not checked yet.

Add a resource model to start the app. Eg:
rails g scaffold Project code:string title:string description:text
rails db:migrate
Build views, controllers, validations, tests.

Start build of the application home page (stub).
Build /app/views/layouts/application.html.erb with header, footer and shim partials.
Build navigation into the header and footer as required,
including link in to the resource already created.
Build tests for navigation.

gem rolify:
https://github.com/RolifyCommunity/rolify

add rolify to users controller
rails g rolify Role User
edit /config/initializers/rolify.rb: uncomment lines

# Dynamic shortcuts for User class (user.is_admin? like methods). Default is: false
config.use_dynamic_shortcuts

# Configuration to remove roles from database once the last resource is removed. Default is: true
config.remove_role_if_empty = false

add resourcify to all modules: project, tag, document, asset etc
rails g scaffold_controller Roles
copy in controller code
add allowed role names to /config/application.rb:

# List of approved role names for Rolify
config.role_names = %w[reader author editor checker approver admin owner]

Add role_names helper to /app/helpers/roles_helper.rb

Add required translations for the approved role names in /config/locales/rolify.en.yml
At present, must at least have a translation for your default locale.

add roles new view: /app/views/roles/new.html.erb
add roles shared partial: /app/views/shared/_role_assignment.html.erb
add render partial to the edit view for all resources with roles, eg:

<%= render 'shared/role_assignment', object: @project %>

gem pundit:
Read https://github.com/varvet/pundit?tab=readme-ov-file
rails g pundit:install
rails g pundit:policy project
