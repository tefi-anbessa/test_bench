###  Create the new app.

`cd /Users/frank/RailsProjects/Rails7`
`rails new [app_name]`
- set up repo on github
- run git initialize baseline and push to remote
- Make a git branch for setting up gemfile

### Gemfile

Edit the gemfile:
Uncomment some rails standard issue lines:
`gem "bcrypt", "~> 3.1.7"
gem "sassc-rails"
gem "redis", "~> 4.0"
gem "kredis"`

Add these gems to core:

___
'
`#### Added gems +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#### Use Bootstrap 5 for formatting:
gem 'bootstrap', '~> 5.1.3'
'
#### Use faker for development seed data:
gem "faker"

#### Use i18n for internationalization:
gem 'rails-i18n', '~> 7.0.0'

#### use gem 'flag-icons-rails' for internationalisation icons (though there may be
#### better options: flags represent countries not languages...)
gem 'flag-icons-rails'

#### Use ransack for search and sort functionality.
gem 'ransack'

#### Use pagy for pagination
gem "pagy", '~> 9.0'

#### Use devise for access control
gem "devise", "~> 4.9"
gem 'devise-i18n'

#### Use bootstrap_form for pretty easy forms.
gem "bootstrap_form", "~> 5.4"

#### Use rolify and Pundit for authorization
gem "rolify"
gem "pundit"

#### add gems to testing:

group :test do
  #### Use system testing [https://guides.rubyonrails.org/testing.html####system-testing]
  gem "capybara"
  gem "selenium-webdriver"
  gem "webdrivers",               "5.0.0"
  gem "rails-controller-testing", "1.0.5"
  gem "minitest",                 "5.15.0"
  gem "minitest-reporters",       "1.5.0"
  gem "guard",                    "2.18.0"
  gem "guard-minitest",           "2.4.6"

#### set database gems in development and testing

group :development, :test do
#### Rails defaults:
  #### Use sqlite3 as the database for Active Record
  gem "sqlite3", "~> 1.4"

#### set production database gem as required, eg:

group :production do
  gem "pg",         "1.3.5"`
___

### Internationalization.

Internationalize the app at this point. Devise should not need much intervention
for forms but error messages not checked yet.  

Copy folder  
`test_bench/config/locales`

Edit  
`test_bench/app/helpers/application_helper.rb` to add:  

    def flag_code(locale)
      codes = {en: :gb, km: :kh}
      flag_code = codes[locale] || locale
    end

###  Devise

Read_me at https://github.com/heartcombo/devise and https://github.com/tigrish/devise-i18n
before deciding how to go about internationalization of devise (users registration process).

Run  
`rails generate devise:install`

Edit  
`project_assistant/config/initializers/devise.rb`: set mailer for each evironment.
Change the keys used for authentication - login is a virtual param.
`config.authentication_keys = [ :login ]`  
`config.case_insensitive_keys = [:email]`  
`config.strip_whitespace_keys = [:name, :email]`

Run  
`rails generate devise User`  

Edit  
`project_assistant/app/models/user.rb`
Include all modules except omniauthorable by moving from the commented out line to the devise line.

Edit  
`project_assistant/db/migrate/20240901093618_devise_create_users.rb`  
Include all modules by uncommenting. Add name field at the top:  
`t.string :name, null: false`

Edit  
`project_assistant/app/controllers/application_controller.rb`  

Follow the [devise wiki](https://github.com/heartcombo/devise/wiki/How-To:-Allow-users-to-sign-in-using-their-username-or-email-address) to allow both name and email as keys for sign in:  
Edit  
`project_assistant/app/controllers/application_controller.rb`

    class ApplicationController < ActionController::Base
      before_action :configure_permitted_parameters, if: :devise_controller?

      protected

      def configure_permitted_parameters
        added_attrs = [:name, :email, :password, :password_confirmation, :remember_me]
        devise_parameter_sanitizer.permit :sign_up, keys: added_attrs
        devise_parameter_sanitizer.permit :sign_in, keys: [:login, :password]
        devise_parameter_sanitizer.permit :account_update, keys: added_attrs
      end
    end

Edit:  
`project_assistant/app/models/user.rb`

    attr_writer :login

    def login
      @login || self.name || self.email
    end

    def self.find_for_database_authentication(warden_conditions)
      conditions = warden_conditions.dup
      if (login = conditions.delete(:login))
        where(conditions.to_h).where(["name = :value OR lower(email) = lower(:value)",
          { :value => login }]).first
      elsif conditions.has_key?(:name) || conditions.has_key?(:email)
        where(conditions.to_h).first
      end
    end

Devise config is already edited earlier to use login as key.

Run  
`rails db:migrate`  
and fix the errors :-)

Run  
`rails generate devise:views`

Copy  
`test_bench/app/helpers/users_helper.rb`  
for gravatars.

Copy folder  
`test_bench/app/views/users`  
and copy files  
`test_bench/app/controllers/users_controller.rb`   
`test_bench/test/controllers/users_controller_test.rb`  
for bespoke show and index views.

###  Static Pages

Set up site static pages as required.  
`rails g controller site home help about contact`

### Resources

Add a resource model to start the app. Eg:  
`rails g scaffold Project code:string title:string description:text
rails db:migrate`

Build views, controllers, validations, tests.
Start build of the application home page (stub).

###  Layout

Copy from test_bench:  
`test_bench/app/views/layouts/application.html.erb`
`test_bench/app/views/layouts/_header.html.erb`
`test_bench/app/views/layouts/_footer.html.erb`
`test_bench/app/views/layouts/_shim.html.erb`
`test_bench/app/views/shared/_error_messages.html.erb`

Build additional navigation into the header and footer as required,
including link in to the resource already created.

### Build tests for navigation.

###  Bootstrap 5 icons.

Run command from project directory:  
`npm i bootstrap-icons`

Edit `/config/initializers/assets.rb`, add:
`Rails.application.config.assets.paths << Rails.root.join("node_modules/bootstrap-icons/font")`

Edit `/app/assets/stylesheets/application.scss`, add:
`@import "bootstrap-icons";
@import "rails_bootstrap_forms.css";
@font-face {
  font-family: "bootstrap-icons";
  src: font-url("fonts/bootstrap-icons.woff2") format("woff2"),
    font-url("/fonts/bootstrap-icons.woff") format("woff");`

Copy `test_bench/app/helpers/bootstrap_icon_helper.rb`.

### Constants

Copy folder `test_bench/lib/constant`.
Copy file `test_bench/config/initializers/constants.rb`.
Copy folder `test_bench/config/constants`, edit files in this folder to add constants.

### Pagy

[Readme for pagy: ](https://github.com/ddnexus/pagy)

Download config file (https://ddnexus.github.io/pagy/gem/config/pagy.rb)
and save in folder `project_assistant/config/initializers`.

Uncomment bootstrap extra helpers:
`require 'pagy/extras/bootstrap'`

Uncomment overflow extra helpers:
`require 'pagy/extras/overflow'
# default  (other options: :last_page and :exception)require 'pagy/extras/overflow'
Pagy::DEFAULT[:overflow] = :empty_page'`

Edit `project_assistant/app/controllers/application_controller.rb`
Add:
`include Pagy::Backend`
Edit
`project_assistant/app/helpers/application_helper.rb`
Add:
`include Pagy::Frontend`

### Rolify

[Readme for rolify](https://github.com/RolifyCommunity/rolify)

Add rolify to users controller:
rails g rolify Role User

Edit `/config/initializers/rolify.rb`, uncomment lines:

`# Dynamic shortcuts for User class (user.is_admin? like methods). Default is: false
config.use_dynamic_shortcuts`

`# Configuration to remove roles from database once the last resource is removed. Default is: true
config.remove_role_if_empty = false`

Add resourcify to all resource like models that need authorisation applied:
project, tag, document, asset etc.

Run  
`rails db:migrate`  

Build user interface for role assignment.
`rails g controller Roles new create destroy`  

Copy in controller code from  
`test_bench/app/controllers/roles_controller.rb`.

Edit allowed role names in constants if required:
`test_bench/config/constants/role.yml`

Copy role_names helper to /app/helpers:
`test_bench/app/helpers/roles_helper.rb `

Add translations for the approved role names in
`/config/locales/rolify.en.yml`
and all other required languages.
These are pick list values.
At present, must at least have a translation for your default locale.

Copy roles new view: `test_bench/app/views/roles/new.html.erb`
Copy roles index view: `test_bench/app/views/roles/index.html.erb`
Copy roles shared partial: `test_bench/app/views/shared/_role_assignment.html.erb`

Edit the edit views for all resources with roles, to add the partial allowing
assignment of roles at the instance level. E.g.:
`test_bench/app/views/projects/edit.html.erb`
Add:
`<%= render 'shared/role_assignment', object: @project %>`
at the end.

### Pundit:

[Read_me: ](https://github.com/varvet/pundit?tab=readme-ov-file)
Run:
`rails g pundit:install`

Run:
`rails g pundit:policy project`
for each resource.

#Ref for virtual columns
https://www.mintbit.com/blog/creating-virtual-columns-in-rails-7-a-step-by-step-guide

# Bootstrap icons
# Include into
# test_bench/app/assets/stylesheets/application.scss  
  @import "bootstrap-icons";
  @import "rails_bootstrap_forms.css";
  @font-face {
    font-family: "bootstrap-icons";
    src: font-url("fonts/bootstrap-icons.woff2") format("woff2"),
      font-url("/fonts/bootstrap-icons.woff") format("woff");
# Copy:
test_bench/app/helpers/bootstrap_icon_helper.rb

Electrical

rails g migration AddTagableToTags tagable:references, polymorphic: true
Check the migration file:
    add_reference :tags, :tagable, polymorphic: true, null: true, index: true

Make tags the superclass for delegated types such as cable, load.
Edit the tag model:
  delegated_type :tagable, types: %w[ Cable Load ], optional: true
and add module at the bottom:
  module Tagable
    extend ActiveSupport::Concern

    included do
      has_one :tag, as: :tagable, touch: true
    end
  end
# That doesn't work, module not found???

rails g scaffold electrical/cable_type conductor_material:string conductor_makeup:string csa:float neutral_csa:float earth_csa:float insulation:string bedding:string armour:string sheath:string bedding_od:decimal overall_od:decimal temperature_rating:integer
Edit migration for decimals, add: , precision: 3, scale: 1
Copy the fixtures and model tests. Run.
Copy the controller tests, views. Run. Check the app.

rails g scaffold electrical/load circuit:integer basis:integer basis_notes:string supply:float phases:integer power:float vector:float power_factor:float current:float duty:float
Edit the migration to add the polymorphic reference to loadable.
rails g scaffold electrical/cable cable_type:references from:integer to:integer route_length:decimal vertical_allowance:decimal termination_allowance:decimal start_mark:integer end_mark:integer

rails g scaffold electrical/protection electrical_loads:references device:integer poles:integer curve:integer rating:float elcb:integer notes:text

Edit the migrations to add the delegated_type indices.
Edit the models to add the relationships.
Edit the cable type model to add enum for csa.

Dir[Rails.root.join('electrical', 'electrical_constants', '**/*.{rb,yml}').to_s]

Set up global constants. Follow
https://dev.to/vladhilko/say-goodbye-to-messy-constants-a-new-approach-to-moving-constants-away-from-your-model-58i1
and copy electrical.yml into config.

Add human_enum_name to ApplicationRecord.rb for i18n translation of enum fields:
https://gist.github.com/repoles/e798a915a0df49e3bcce0b7932478728
