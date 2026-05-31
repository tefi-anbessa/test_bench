require "rails/generators/named_base"
require_relative 'field_types'

module ProjectAssistant
  class TagableGenerator < Rails::Generators::NamedBase
    include Rails::Generators::ResourceHelpers
    include FieldTypes
    desc "Create scaffolding and config entries for a tagable model"
    source_root File.expand_path("tagable/templates", __dir__)
    
    def initialize(args, *options)
      super
      validate_name
    end
    
    def module_name
      class_name.split("::")[0..-2].join("::")  # "Module::SubModule".
    end

    def tagable_name
      file_name.classify      # "Tagable"
    end

    def validate_name
      errors = []
      
      # Validate that we have a module and class name
      unless class_name.include?("::")
        errors << "Name must include both module and class with '::' separator"
        return errors if errors.any?
      end
      
      # Validate module exists
      # begin
#        module_name.constantize
#      rescue NameError
      folder = File.join(destination_root, "app", "models")
      class_name.split("::")[0..-2].each do |part|
        folder = File.join(folder, part.underscore)
        unless Dir.exist?(folder)
          errors << "Module '#{folder}' does not exist"
        end
      end
      
      # Validate class name format
      unless tagable_name.match?(/^[A-Z][a-zA-Z0-9_]*$/)
        errors << "Class name '#{tagable_name}' is not a valid Ruby identifier"
      end
      
      if errors.any?
        say_status :error, "Name validation failed:", :red
        errors.each { |error| say_status :error, "  - #{error}", :red }
        say_status :info, "Generator aborted. Please fix the name and try again.", :yellow
        exit 1
      end
    end

    def process_fields
      # First pass: collect all validation errors
      errors = []
      valid_fields = []
      
      args.each do |arg|
        begin
          # Split the argument into parts
          name, type, *options = arg.split(':')
          
          # Validate field name
          unless name&.match?(/^[a-zA-Z_][a-zA-Z0-9_]*$/)
            errors << "Invalid field name: #{name}. Must be a valid Ruby identifier"
            next
          end
          
          # Validate field type (no defaults)
          if type.nil?
            errors << "Missing field type for #{name}. Please specify a type"
            next
          end
          
          unless VALID_FIELD_TYPES.include?(type)
            errors << "Unknown field type '#{type}' for #{name}. Valid types are: #{VALID_FIELD_TYPES.join(', ')}"
            next
          end

          # Validate options
          options = options.uniq # Remove duplicates
          invalid_options = options - VALID_OPTIONS
          unless invalid_options.empty?
            errors << "Unknown option(s) #{invalid_options.inspect} for #{name}. Valid options are: #{VALID_OPTIONS.join(', ')}"
            next
          end
          
          valid_fields << { name: name, type: type, options: options }
        rescue ArgumentError => e
          errors << "Invalid attribute: #{arg} - #{e.message}"
        end
      end
      
      # Handle validation results
      if errors.any?
        say_status :error, "Validation errors found:", :red
        errors.each { |error| say_status :error, "  - #{error}", :red }
        
        if valid_fields.any?
          say_status :warning, "Valid fields that could be processed:", :yellow
          valid_fields.each { |field| say_status :info, "  - #{field[:name]}:#{field[:type]}#{field[:options].map { |opt| ":#{opt}" }.join('')}", :blue }
          
          say_status :prompt, "Continue with valid fields only? (Recommended: No) [y/N]", :yellow
          response = $stdin.gets.chomp.downcase
          
          if response == 'y'
            @fields = valid_fields
            say_status :info, "Proceeding with #{valid_fields.length} valid fields.", :green
          else
            say_status :info, "Generator aborted. Please fix the errors and run again.", :yellow
            exit 1
          end
        else
          say_status :error, "No valid fields found. Generator aborted.", :red
          exit 1
        end
      else
        @fields = valid_fields
        say_status :info, "All #{valid_fields.length} fields are valid.", :green
      end
      
      @fields
    end

    def create_model_file
      template "model.rb.erb", File.join('app', 'models', "#{file_path}.rb")
    end
    
    def create_factory_file
      template "factory.rb.erb", File.join('test', 'factories', "#{route_url}.rb")
    end

    def create_model_test_file
      template "model_test.rb.erb", File.join('test', 'models', "#{file_path}_test.rb")
    end
    
    def create_migration_file
      migration_name = "create_#{singular_table_name}"
      timestamp = Time.now.utc.strftime("%Y%m%d%H%M%S")
      migration_file = File.join(destination_root, 'db', 'migrate', "#{timestamp}_#{migration_name}.rb")
      
      template "migration.rb.erb", migration_file
    end
      
    def create_policy_file
      template "policy.rb.erb", File.join('app', 'policies', "#{file_path}_policy.rb")
    end
    
    def create_policy_test_file
      template "policy_test.rb.erb", File.join('test', 'policies', "#{file_path}_policy_test.rb")
    end
    
    def create_controller_file
      template "controller.rb.erb", "app/controllers/#{controller_file_path}_controller.rb"
    end
    
    def create_view_files
      template "views/index.html.erb", "app/views/#{controller_file_path}/index.html.erb"
      template "views/_header.html.erb", File.join('app', 'views', controller_file_path, '_header.html.erb')
      template "views/_row.html.erb", File.join('app', 'views', controller_file_path, '_row.html.erb')
      template "views/show.html.erb", File.join('app', 'views', controller_file_path, 'show.html.erb')
      template "views/edit.html.erb", File.join('app', 'views', controller_file_path, 'edit.html.erb')
      template "views/new.html.erb", File.join('app', 'views', controller_file_path, 'new.html.erb')
      template "views/_form.html.erb", File.join('app', 'views', controller_file_path, '_form.html.erb')
      template "views/_card.html.erb", File.join('app', 'views', controller_file_path, '_card.html.erb')
    end
    
    def create_controller_test_file
      template "controller_test.rb.erb", File.join('test', 'controllers', "#{controller_file_path}_controller_test.rb")
    end
    
    def create_system_test_file
      template "system_test.rb.erb", File.join('test', 'system', "#{controller_file_path}_system_test.rb")
    end
    
    def edit_routes_file
      # Update config/routes.rb
      routes_file = Pathname.new(File.join(destination_root, "config", "routes.rb"))
      if File.exist?(routes_file)
        content = File.read(routes_file)
        
        # Find the first insertion point comment and insert after it
        insertion_pattern = /(namespace\s+:#{module_name.underscore}\s+do.*?# INSERTION POINT 1 FOR TAGABLE GENERATOR)/m
        if content.match?(insertion_pattern)
          content.sub!(insertion_pattern) do
            "#{$1}\n      resources :#{plural_name}, only: [:index, :new, :create]"
          end
        else
          say_status :error, "#{routes_file.relative_path_from(Rails.root)}: Could not find insertion point 1 for tagable generator", :red
          return
        end
        
        # Find the second insertion point comment and insert after it
        insertion_pattern = /(namespace\s+:#{module_name.underscore}\s+do.*?# INSERTION POINT 2 FOR TAGABLE GENERATOR)/m
        if content.match?(insertion_pattern)
          content.sub!(insertion_pattern) do
            "#{$1}\n        resources :#{plural_name}, except: [:index]"
          end
        else
          say_status :error, "#{routes_file.relative_path_from(Rails.root)}: Could not find insertion point 2 for tagable generator", :red
          return
        end
        
        File.write(routes_file, content) unless options[:pretend]
        say_status :update, "#{routes_file.relative_path_from(Rails.root)}: Updated with #{tagable_name.pluralize} resources", :green
      else
        say_status :error, "#{routes_file.relative_path_from(Rails.root)}: Not found", :red
      end
    end
         
    def update_constants
      # Update tagable.yml
      tagable_file = Pathname.new(File.join(destination_root, "config", "constants", "tagable.yml"))
      if File.exist?(tagable_file)
        content = File.read(tagable_file)
        # Match the module name in the comment and append the class name
        content.sub!(/(#\s+#{module_name}\n)/, "\\1  - #{class_name}\n")
        File.write(tagable_file, content) unless options[:pretend]
        say_status :update, "#{tagable_file.relative_path_from(Rails.root)}: Added #{class_name}", :green
      else
        say_status :error, "#{tagable_file.relative_path_from(Rails.root)}: Not found", :red
      end

      # Update module constants with enum definitions
      constants_file = Pathname.new(File.join(destination_root, "config", "constants", "#{class_path[0]}.yml"))
      if File.exist?(constants_file)
        content = File.read(constants_file)
        module_key = class_path.last
        model_key = class_name.demodulize.underscore
        insertion_pattern = /^(?<indent>[ \t]*)(?<key>#{module_key}:)\s*$/
#       insertion_pattern = /^(\s*)(#{module_key}:)/
        # Check that the module key is present
        if found = content.match(insertion_pattern).named_captures
          # Insert model key
          insertion_text = "#{model_key}:\n"
          # Add enum definitions for fields of type :enum or :enum_translated
          enum_fields = @fields.select { |field| field[:type] == 'enum' || field[:type] == 'enum_translated' }
          if enum_fields.any?
            enum_fields.each do |field|
              insertion_text += "#{found["indent"]}  #{field[:name]}:\n#{found["indent"]}    # TODO: Add enum values\n"
            end
          end
          content.sub!(insertion_pattern) do
            "#{found["indent"]}#{found["key"]}\n#{insertion_text}" 
          end
          File.write(constants_file, content) unless options[:pretend]
          say_status :update, "#{constants_file.relative_path_from(Rails.root)}: Added model and enum keys", :green
        else
          say_status :error, "#{constants_file.relative_path_from(Rails.root)}: Key #{module_key}: not found", :red
        end
      else
        say_status :error, "#{constants_file.relative_path_from(Rails.root)}: Not found", :red
      end
    end

    def add_translations
      I18n.available_locales.each do |locale|
        translation_file = Pathname.new(File.join(destination_root, "config", "locales", 
          module_name.underscore, locale.to_s, "#{locale}.#{module_name.underscore}.models.yml"))
        
        if File.exist?(translation_file)
          content = File.read(translation_file)  
          # Prepare model name and attributes sections
          model_section = "      #{file_path}: \"#{human_name}\"\n"
          attributes_section = "      #{file_path}:\n"
          
          @fields.each do |field|
            
            # Use field[:name].humanize as dummy translation
            attributes_section += "        #{field[:name]}: #{field[:name].humanize}\n"
            
            # Add enum translations for enum_translated fields
            if field[:type] == 'enum_translated'
              attributes_section += "          #{field[:name].pluralize}:\n"
              attributes_section += "            other_#{field[:name]}: \"Other #{field[:name].humanize}\"\n"
            end
          end
          
          # Insert model name under models section
          if content.match?(/(\s+models:)/)
            content.sub!(/(\s+models:)/) { "#{$1}\n#{model_section}" }
          end
          
          # Insert attributes under attributes section
          if content.match?(/(\s+attributes:)/)
            content.sub!(/(\s+attributes:)/) { "#{$1}\n#{attributes_section}" }
            File.write(translation_file, content) unless options[:pretend]
            say_status :update, "#{translation_file.relative_path_from(Rails.root)}: Added #{class_name} translations", :green
          else
            say_status :error, "#{translation_file.relative_path_from(Rails.root)}: Attributes key not found", :red
          end
        else
          say_status :error, "#{translation_file.relative_path_from(Rails.root)}: Not found", :red
        end
        
        # Handle views translations
        views_file = Pathname.new(File.join(destination_root, "config", "locales", 
          module_name.underscore, locale.to_s, "#{locale}.#{module_name.underscore}.views.yml"))
        
        if File.exist?(views_file)
          content = File.read(views_file)
          
          # Prepare views translations section
          views_section = "    #{plural_name}:\n" +
            "      index:\n" +
            "        title:            \"#{human_name.pluralize}\"\n" +
            "        header:           \"#{human_name.pluralize} Schedule for %{scope_text}\"\n" +
            "      edit:\n" +
            "        title:            \"Edit #{human_name}\"\n" +
            "        header:           \"Edit #{human_name}: %{label}\"\n" +
            "      new:\n" +
            "        title:            \"New #{human_name}\"\n" +
            "        header:           \"New #{human_name} in %{scope_text}\"\n" +
            "      show:\n" +
            "        title:            \"#{human_name}\"\n" +
            "        header:           \"#{human_name}: %{label}\"\n"
          
          # Append to the end of the file
          content += views_section
          
          File.write(views_file, content) unless options[:pretend]
          say_status :update, "#{views_file.relative_path_from(Rails.root)}: Added #{class_name} views translations", :green
        else
          say_status :error, "#{views_file.relative_path_from(Rails.root)}: Not found", :red
        end
      end
    end
  end
end