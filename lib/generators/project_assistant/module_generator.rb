# lib/generators/project_assistant/module_generator.rb
require "rails/generators/named_base"

module ProjectAssistant
  class ModuleGenerator < Rails::Generators::NamedBase
    source_root File.expand_path("templates", __dir__)

    def create_module_structure
      @module_name = name.underscore
      @module_class = name.camelize

      # Check for existing module structure
      if should_abort?("app/#{@module_name}") || 
         should_abort?("test/#{@module_name}") ||
         should_abort?("app/models/#{@module_name}.rb") ||
         should_abort?("config/locales/#{@module_name}")
        return
      end

      # Create app folder structure
      %w[controllers helpers models policies views].each do |dir|
        dir_path = File.join(destination_root, "app", @module_name, dir)
        empty_directory(dir_path)
        keep_file = File.join(dir_path, ".keep")
        create_file(keep_file, verbose: false) unless File.exist?(keep_file)
      end

      # Create test folder structure
      %w[controllers factories models policies system].each do |dir|
        dir_path = File.join(destination_root, "test", @module_name, dir)
        empty_directory(dir_path)
        keep_file = File.join(dir_path, ".keep")
        create_file(keep_file, verbose: false) unless File.exist?(keep_file)
      end

      # Create locales folder
      dir_path = File.join(destination_root, 'config', 'locales', @module_name)
      empty_directory(dir_path)

      # Create locales subfolder for each language
      I18n.available_locales.each do |locale|
        lang = locale.to_s
        dir_path = File.join(destination_root, 'config', 'locales', @module_name, lang)
        empty_directory(dir_path)
        
        # Create [locale].[module_name].yml for general translations
        general_file = File.join(dir_path, "#{lang}.#{@module_name}.yml")
        create_file(general_file, <<~YAML) unless File.exist?(general_file)
          # General translations for #{@module_name} module in #{lang}
          #{lang}:
            #{@module_name}:
        YAML

        # Create translation files
        %w[models views].each do |file_type|
          file_path = File.join(dir_path, "#{lang}.#{@module_name}.#{file_type}.yml")
          create_file(file_path, <<~YAML) unless File.exist?(file_path)
            # #{@module_name} #{file_type} translations for #{lang}
            #{lang}:
              #{@module_name}:
          YAML
        end
      end

      # Base model
      template "base.rb.erb", "app/#{@module_name}/base.rb"
      template "module.rb.erb", "app/models/#{@module_name}.rb"

      # Autoload paths
      inject_into_file "config/application.rb", 
        after: "class Application < Rails::Application\n" do
        <<~RUBY
          # Autoload module directories
          config.autoload_paths += %W(\#{config.root}/app/#{@module_name} \#{config.root}/app/#{@module_name}/**/)
        RUBY
      end

      # Routes
      route "namespace :#{@module_name} do\n    # Add your routes here\n  end"
    end
    
    private
    
    def should_abort?(path)
      full_path = Rails.root.join(path)
      if File.exist?(full_path)
        if Rails.env.test?
          puts "[TEST] Would prompt to overwrite: #{full_path}"
          return false  # In test environment, always proceed without asking
        else
          unless yes?("#{full_path} already exists. Overwrite? [y/N]")
            say "Module '#{@module_name}' generation aborted.", :red
            return true
          end
        end
      end
      false
    end
  end
end