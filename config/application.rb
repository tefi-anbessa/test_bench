require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module TestBench
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.0

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")

    # Added for i18n installation
      # Path to search for translation files
      config.i18n.load_path += Dir[Rails.root.join('config', 'locales', '**', '*.{rb,yml}')]

      # Permitted locales available for the application
      I18n.available_locales = [:en, :km ,:th, :cn]
    # end i18n

    config.active_record.verify_foreign_keys_for_fixtures = false
    
    # Include FactoryBot methods in console
    console do
      # Make FactoryBot methods available without the FactoryBot prefix
      include FactoryBot::Syntax::Methods
      
      # Optional: Load all factories for autocompletion
      # FactoryBot.find_definitions if Rails.env.development?
    end
  end
end
