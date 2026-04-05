# lib/generators/project_assistant/module_generator.rb
require "rails/generators/named_base"

module ProjectAssistant
  class ModuleGenerator < Rails::Generators::NamedBase
    desc "Create file structure, templates and config entries for a new module in Project Assistant app"
    source_root File.expand_path('module/templates', __dir__)
    APP_DIRECTORIES = %w[controllers helpers models policies views]
    TEST_DIRECTORIES = %w[controllers factories models policies system]
    LOCALE_FILES = %w[models views]

    def initialize(args, *options)
      super
      File.write('/tmp/generator_initialize.txt', "Generator initialized with args: #{args.inspect}")
      File.write('/tmp/generator_class_path.txt', "class_path: #{class_path.inspect}, name: #{name.inspect}, singular_name: #{singular_name.inspect}")
      @nested_module = class_path.count > 0
      @parent_directory = @nested_module ? File.join(*class_path) : nil
      @full_path = @nested_module ? File.join(@parent_directory, singular_name) : singular_name
    end

    # If a nested module is specified, check that the parent module folders exist
    def check_parent_modules_exist
      if @nested_module
        paths_to_check = [
          # App directories
          *APP_DIRECTORIES.map { |dir| File.join("app", dir, @parent_directory) },
          # Test directories
          *TEST_DIRECTORIES.map { |dir| File.join("test", dir, @parent_directory) },
          # Locales
          File.join("config", "locales", @parent_directory)
        ]
        paths_to_check.each do |path|
          unless Dir.exist?(path)
            say_status :error, "#{path}: Parent module path does not exist. Aborting.", :red
            exit
          end
        end
      end
    end
    
    def check_existing_structure
      # say_status :skip, "Skipping check_existing_structure method for debugging", :blue
      # return
      # Check for existing module structure to avoid clobbering

      paths_to_check = [
        # App directories
        *APP_DIRECTORIES.map { |dir| File.join("app", dir, @full_path) },
        # Test directories
        *TEST_DIRECTORIES.map { |dir| File.join("test", dir, @full_path) },
        # Module base model file
        File.join("app", "models", @full_path, "base.rb"),
        # Locales
        File.join("config", "locales", @full_path)
      ]

      paths_to_check.each do |path|
        # puts "DEBUG: Checking path: #{path}"
        if should_abort?(path)
          # puts "DEBUG: Aborting on path: #{path}"
          return
        end
      end
    end
      
    def create_module_structure
      # say_status :skip, "Skipping create_module_structure method for debugging", :blue
      # return
      # Create app folder structure with module subfolders
      APP_DIRECTORIES.each do |dir|
        dir_path = File.join(destination_root, "app", dir, @full_path)
        empty_directory(dir_path)
        keep_file = File.join(dir_path, ".keep")
        create_file(keep_file, verbose: false) 
      end

      # Create test folder structure with module subfolders
      TEST_DIRECTORIES.each do |dir|
        dir_path = File.join(destination_root, "test", dir, @full_path)
        empty_directory(dir_path)
        keep_file = File.join(dir_path, ".keep")
        create_file(keep_file, verbose: false) unless File.exist?(keep_file)
      end

      # Create locales folder
      dir_path = File.join(destination_root, 'config', 'locales', @full_path)
      empty_directory(dir_path)

      # Create locales subfolder for each language
      I18n.available_locales.each do |locale|
        language = locale.to_s
        dir_path = File.join(destination_root, 'config', 'locales', @full_path, language)
        empty_directory(dir_path)
        
        # Create [locale].[singular_name].yml for general translations
        general = File.join(dir_path, "#{language}.#{singular_name}.yml")
        create_file(general, <<~YAML) unless File.exist?(general)
          # General translations for #{singular_name} module in #{language}
          #{language}:
            #{singular_name}:
        YAML

        # Create activerecord translation file
        models = File.join(dir_path, "#{language}.#{singular_name}.models.yml")
        create_file(models, <<~YAML) unless File.exist?(models)
# #{singular_name} model translations for #{language}
#{language}:
  activerecord:
    models:
      <%= singular_name %>:        # Insert model name translations here
    attributes:
      <%= singular_name %>:        # Insert attributes translations here
    errors:
      <%= singular_name %>:        # Insert custom validation error translations here
        YAML

        # Create views translation file
        views = File.join(dir_path, "#{language}.#{singular_name}.views.yml")
        create_file(views, <<~YAML) unless File.exist?(views)
# #{singular_name} views translations for #{language}
#{language}:
  #{singular_name}:
        YAML
      end
    end

    def create_module_files
      # Base model and module files
      template "base.rb.erb", "app/models/#{@full_path}/base.rb"
      template "module.rb.erb", "app/models/#{@full_path}.rb"
    end

    def edit_routes_file
      # say_status :skip, "Skipping edit_routes_file method for debugging", :blue
      # return
      # Add two routes namespaces 
      # [TODO verify if the first set of routes is really needed. 
      # They arose because of a conflict on index routes, but that may have been a special case]
      # Update routes.rb for both insertion points
      routes_file = Pathname.new(File.join(destination_root, 'config', 'routes.rb'))
      if routes_file.exist?
        # puts "DEBUG: Reading routes file..."
        routes_content = routes_file.read
        # puts "DEBUG: Routes file read successfully"
        comment = ["member routes here with only: [:index, :new, :create]",
                    "collection routes here with except: [:index]"]
        (1..2).each do |i|
          # If nested module, the insertion point is after the parent namespace
          if @nested_module
            insertion_pattern = /^(?<indent>[ \t]*)(?<key>#{class_path.last}:\s.do\n\s*# INSERTION POINT #{i} FOR SUBMODULES)/
          else
            insertion_pattern = /^(?<indent>[ \t]*)(?<key># INSERTION POINT #{i} FOR MODULE GENERATOR)/
          end
          if match = routes_content.match(insertion_pattern)
            # Insert module namespace after the insertion point comment
            insertion_text = "\n" + \
                      match[:indent] + "namespace :#{singular_name} do\n" + \
                      match[:indent] + "  # INSERTION POINT #{i} FOR TAGABLE GENERATOR\n" + \
                      match[:indent] + "  # Insert #{singular_name} #{comment[i-1]}\n" + \
                      match[:indent] + "end\n"
            routes_content.sub!(insertion_pattern, match[0] + insertion_text)
          else
            say_status :error, "#{routes_file.relative_path_from(Rails.root)}: Insertion point #{i} not found", :red
          end
        end
        
        # puts "DEBUG: Writing routes file..."
        File.write(routes_file, routes_content) unless options[:pretend]
        say_status :update, "#{routes_file.relative_path_from(Rails.root)}: Add module routes", :green
      else
        say_status :error, "#{routes_file.relative_path_from(Rails.root)}: Not found", :red
      end
    end

    def edit_constants_file
      # say_status :skip, "Skipping edit_constants_file method for debugging", :blue
      # return
      # Constants
      if @nested_module
        # Only one layer of nesting is required in constants file names. Sub-modules have their own keys within the file.
        constants_file = Pathname.new(File.join(destination_root, 'config', 'constants',
          "#{@class_path.first}.yml"))
          content = constants_file.read
          match = content.match(/(?<indent>[ \t]*)(#{@class_path[-2]}:s*\n)/)
          if match
            content.sub!(match[0], "#{match[:indent] + '  ' }#{@class_path.last}:\n")
            constants_file.write(content) unless options[:pretend]
            say_status :update, "#{constants_file.relative_path_from(Rails.root)}: Add #{singular_name} key", :green
          else
            say_status :error, "#{constants_file.relative_path_from(Rails.root)}: Key not found: #{@class_path[-2]}", :red
          end
      else
        template "module.yml.erb", "config/constants/#{singular_name}.yml"
      end
    end

    def update_tagable_file
      # say_status :skip, "Skipping edit_tagable_file method for debugging", :blue
      # return
      tagable_file = Pathname.new(File.join(destination_root, 'config', 'constants', 'tagable.yml'))
      if tagable_file.exist?
        content = tagable_file.read
        content.sub!(/^(tagable:\n)/, "\\1  # #{class_name}\n")
        tagable_file.write(content) unless options[:pretend]
        say_status :update, "#{tagable_file.relative_path_from(Rails.root)}: Add #{class_name}", :green
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