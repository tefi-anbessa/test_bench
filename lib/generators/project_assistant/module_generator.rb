# lib/generators/project_assistant/module_generator.rb
require "rails/generators/named_base"

module ProjectAssistant
  class ModuleGenerator < Rails::Generators::NamedBase
    desc "Create file structure, templates and config entries for a new module in Project Assistant app"
    source_root File.expand_path('module/templates', __dir__)

    def create_module_structure
      # puts "DEBUG: create_module_structure started"
      # [TODO] These are available from the NamedBase generator so superfluous here.
      # singular_name = name.underscore
      # class_name = name.camelize
      # puts "DEBUG: Module variables set: #{singular_name}, #{class_name}"

      # Check for existing module structure
      # puts "DEBUG: Starting path checks..."
      paths_to_check = [
        # App directories
        *%w[controllers helpers models policies views].map { |dir| "app/#{dir}/#{singular_name}" },
        # Test directories
        *%w[controllers factories models policies system].map { |dir| "test/#{dir}/#{singular_name}" },
        # Module files
        "app/models/#{singular_name}.rb",
        "app/models/#{singular_name}/base.rb",
        # Locales
        "config/locales/#{singular_name}"
      ]
      # puts "DEBUG: #{paths_to_check.length} paths to check"

      paths_to_check.each do |path|
        # puts "DEBUG: Checking path: #{path}"
        if should_abort?(path)
          # puts "DEBUG: Aborting on path: #{path}"
          return
        end
      end
      # puts "DEBUG: All path checks completed"

      # Create app folder structure with module subfolders
      %w[controllers helpers models policies views].each do |dir|
        dir_path = File.join(destination_root, "app", dir, singular_name)
        empty_directory(dir_path)
        keep_file = File.join(dir_path, ".keep")
        create_file(keep_file, verbose: false) 
      end

      # Create test folder structure with module subfolders
      %w[controllers factories models policies system].each do |dir|
        dir_path = File.join(destination_root, "test", dir, singular_name)
        empty_directory(dir_path)
        keep_file = File.join(dir_path, ".keep")
        create_file(keep_file, verbose: false) unless File.exist?(keep_file)
      end

      # Create locales folder
      dir_path = File.join(destination_root, 'config', 'locales', singular_name)
      empty_directory(dir_path)

      # Create locales subfolder for each language
      I18n.available_locales.each do |locale|
        language = locale.to_s
        dir_path = File.join(destination_root, 'config', 'locales', singular_name, language)
        empty_directory(dir_path)
        
        # Create [locale].[singular_name].yml for general translations
        file_path = File.join(dir_path, "#{language}.#{singular_name}.yml")
        create_file(file_path, <<~YAML) unless File.exist?(file_path)
          # General translations for #{singular_name} module in #{language}
          #{language}:
            #{singular_name}:
        YAML

        # Create activerecord translation file
        file_path = File.join(dir_path, "#{language}.#{singular_name}.models.yml")
        create_file(file_path, <<~YAML) unless File.exist?(file_path)
          # #{singular_name} model translations for #{language}
          #{language}:
            activerecord:
              models:           # Insert model name translations here
              attributes:       # Insert model name translations here
              errors:           # Insert custom validation error translations here
        YAML

        # Create views translation file
        file_path = File.join(dir_path, "#{language}.#{singular_name}.views.yml")
        create_file(file_path, <<~YAML) unless File.exist?(file_path)
          # #{singular_name} views translations for #{language}
          #{language}:
            #{singular_name}:
        YAML
      end

      # Base model and module files
      template "base.rb.erb", "app/models/#{singular_name}/base.rb"
      template "module.rb.erb", "app/models/#{singular_name}.rb"

      # Add two routes namespaces 
      # [TODO verify if the first set of routes is really needed. 
      # They arose because of a conflict on index routes, but that may have been a special case]
      # Update routes.rb for both insertion points
      routes_file = Pathname.new(File.join(destination_root, 'config', 'routes.rb'))
      if routes_file.exist?
        # puts "DEBUG: Reading routes file..."
        routes_content = routes_file.read
        # puts "DEBUG: Routes file read successfully"
        
        # First insertion point
        # puts "DEBUG: Processing first insertion point..."
        routes_content.sub!(/(# INSERTION POINT 1 FOR MODULE GENERATOR)/, 
                     "namespace :#{singular_name} do\n" \
                     "      # INSERTION POINT 1 FOR TAGABLE GENERATOR\n" \
                     "    # Add #{singular_name.underscore} routes here with only: [:index, :new, :create]\n" \
                     "  end\n" \
                     "  \\1")
        # puts "DEBUG: First insertion point processed"
        
        # Second insertion point
        # puts "DEBUG: Processing second insertion point..."
        routes_content.sub!(/(# INSERTION POINT 2 FOR MODULE GENERATOR)/,
                         "namespace :#{singular_name} do\n" \
                         "        # INSERTION POINT 2 FOR TAGABLE GENERATOR\n" \
                         "      # Add #{singular_name.underscore} routes here with except: [:index]\n" \
                         "    end\n" \
                         "    \\1")
        # puts "DEBUG: Second insertion point processed"
        
        # puts "DEBUG: Writing routes file..."
        File.write(routes_file, routes_content) unless options[:pretend]
        say_status :update, "#{routes_file.relative_path_from(Rails.root)}: Added module routes", :green
      else
        say_status :error, "#{routes_file.relative_path_from(Rails.root)}: Not found", :red
      end

      # Constants
      template "module.yml.erb", "config/constants/#{singular_name}.yml"
      say_status :update, "Constants file added", :green

      # Update tagable.yml
      tagable_file = Pathname.new(File.join(destination_root, 'config/constants/tagable.yml'))
      if tagable_file.exist?
        content = tagable_file.read
        content.sub!(/^(tagable:\n)/, "\\1  # #{class_name}\n")
        tagable_file.write(content) unless options[:pretend]
        say_status :update, "#{tagable_file.relative_path_from(Rails.root)}: Added #{class_name}", :green
      else
        say_status :error, "#{tagable_file.relative_path_from(Rails.root)}: Not found", :red
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
            say "Module '#{singular_name}' generation aborted.", :red
            return true
          end
        end
      end
      false
    end
  end
end