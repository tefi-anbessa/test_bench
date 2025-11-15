require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module TestBench
  class Application < Rails::Application
# Autoload module directories
config.autoload_paths += %W(#{config.root}/app/electrical #{config.root}/app/electrical/**/)
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 8.0

    # Handle to_time deprecation warning in Rails 8.1
    config.active_support.to_time_preserves_timezone = :zone

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w[assets tasks])

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
    # config.assets.paths << Rails.root.join('node_modules')
    config.dartsass.builds = { "application.scss" => "application.css" }
    config.assets.pipeline = :propshaft
  end
end
