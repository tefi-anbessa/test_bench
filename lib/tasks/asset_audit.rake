namespace :assets do
  desc "Audit current asset configuration"
  task audit: :environment do
    puts "=== Asset Audit ==="
    puts "Sprockets version: #{Sprockets::VERSION}"
    puts "Asset paths: #{Rails.application.config.assets.paths}"
    puts "Precompiled assets: #{Rails.application.config.assets.precompile}"
    puts "\n=== File Inventory ==="

    asset_types = {
      javascript: Dir.glob("app/assets/javascripts/**/*.{js,coffee}").count,
      stylesheets: Dir.glob("app/assets/stylesheets/**/*.{css,scss,sass}").count,
      images: Dir.glob("app/assets/images/**/*").count
    }

    asset_types.each { |type, count| puts "#{type}: #{count} files" }
  end
end