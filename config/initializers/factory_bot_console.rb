# Make FactoryBot methods available in the console without the FactoryBot prefix
if defined?(Rails::Console) && defined?(FactoryBot)
  include FactoryBot::Syntax::Methods

  # Optional: Uncomment the next line to preload all factories for autocompletion
  # FactoryBot.find_definitions if Rails.env.development?

  puts "\n\u001b[32mFactoryBot methods (build, create, etc.) are now available in the console\u001b[0m\n\n"
end
