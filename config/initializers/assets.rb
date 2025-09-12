# This file is intentionally left empty as we're using Propshaft for asset management.
# All assets in app/assets are automatically included by Propshaft.
# For more information, see: https://github.com/rails/propshaft

# If you need to add additional asset paths, you can do so in config/application.rb
# using config.assets.paths << Rails.root.join('path/to/assets')
# Add Bootstrap Icons path
Rails.application.config.assets.paths << Rails.root.join("node_modules")

# Precompile Bootstrap Icons assets
=begin
 Rails.application.config.assets.precompile += %w(
  bootstrap-icons/font/fonts/bootstrap-icons.woff2
  bootstrap-icons/font/fonts/bootstrap-icons.woff
)
=end
