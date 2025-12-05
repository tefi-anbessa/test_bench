# lib/generators/project_assistant/module_generator.rb
require "rails/generators/named_base"

module ProjectAssistant
  class ModuleGenerator < Rails::Generators::NamedBase
    desc "Create file structure, templates and config entries for a new module in Project Assistant app"
    source_root File.expand_path('module/templates', __dir__)

    def create_module_structure
      # [TODO] These are available from the NamedBase generator so superfluous here.
      @module_name = name.underscore
      @module_class = name.camelize

      # Check for existing module structure
      paths_to_check = [
        # App directories
        *%w[controllers helpers models policies views].map { |dir| "app/#{dir}/#{@module_name}" },
        # Test directories
        *%w[controllers factories models policies system].map { |dir| "test/#{dir}/#{@module_name}" },
        # Module files
        "app/models/#{@module_name}.rb",
        "app/models/#{@module_name}/base.rb",
        # Locales
        "config/locales/#{@module_name}"
      ]

      paths_to_check.each do |path|
        if should_abort?(path)
          return
        end
      end

      # Create app folder structure with module subfolders
      %w[controllers helpers models policies views].each do |dir|
        dir_path = File.join(destination_root, "app", dir, @module_name)
        empty_directory(dir_path)
        keep_file = File.join(dir_path, ".keep")
        create_file(keep_file, verbose: false) 
      end

      # Create test folder structure with module subfolders
      %w[controllers factories models policies system].each do |dir|
        dir_path = File.join(destination_root, "test", dir, @module_name)
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

      # Base model and module files
      template "base.rb.erb", "app/models/#{@module_name}/base.rb"
      template "module.rb.erb", "app/models/#{@module_name}.rb"

      # Add two routes namespaces 
      # [TODO verify if the first set of routes is really needed. 
      # They arose because of a conflict on index routes, but that may have been a special case]
      # Update routes.rb for first insertion point
      routes_file = File.join(destination_root, 'config/routes.rb')
      if File.exist?(routes_file)
        routes_content = File.read(routes_file)
        routes_content.sub!(/# NAMESPACE INSERTION POINT 1 FOR GENERATOR/, 
                         "namespace :#{@module_name} do\n    # Add #{@module_name.underscore} routes here with only: [:index, :new, :create]\n  end")
        File.write(routes_file, routes_content)
        
        # Second insertion point under tags
        routes_content = File.read(routes_file)
        routes_content.sub!(/# NAMESPACE INSERTION POINT 2 FOR GENERATOR/,
                         "namespace :#{@module_name} do\n      # Add #{@module_name.underscore} routes here with except: [:index]\n    end")
        File.write(routes_file, routes_content)
      end

      # Add FactoryBot configuration
      application "config.factory_bot.definition_file_paths << File.join(destination_root, 'test', '#{@module_name.underscore}', 'factories')"
    
      # Constants
      template "module.yml", "config/constants/#{@module_name}.yml"

      # Update tagable.yml
      tagable_file = File.join(destination_root, 'config/constants/tagable.yml')
      if File.exist?(tagable_file)
        content = File.read(tagable_file)
        content.sub!(/^(tagable:\n)/, "\\1  # #{@module_class}\n")
        File.write(tagable_file, content)
      else
        say_status :error, "Tagable file not found: #{tagable_file}", :red
      end
    end
    
    private
    
    def should_abort?(path)
      full_path = File.join(destination_root, path)
      
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