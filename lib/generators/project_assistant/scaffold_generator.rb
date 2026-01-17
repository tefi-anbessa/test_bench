require "rails/generators/named_base"
require_relative 'field_types'

module ProjectAssistant
  class ScaffoldGenerator < Rails::Generators::NamedBase
    include Rails::Generators::ResourceHelpers
    include FieldTypes
    source_root File.expand_path("scaffold/templates", __dir__)
    
    def initialize(args, *options)
      super
      @namespaced = class_name&.include?('::')
      validate_name
    end
    
    # Additional helper methods to supplement NamedBase methods
    # Comments assume name argument is "ModuleName::SubModule::ClassName"
    def module_name # Equivalent to class_name without the model class part
      if @namespaced
        name.split("::")[0..-2].join("::")  # "ModuleName::SubModule"
      else
        nil
      end
    end

    def module_path # Used for setting directories.
      if @namespaced
        File.join(*class_path)  # "module_name/sub_module"
      else
        nil     
      end
    end

    def model_class
      class_name.split('::').last  # "ClassName"
    end
    
    # Helper methods for path generation
#    def model_path
#      if @namespaced
#        "#{module_name.underscore}/#{class_name.underscore}"
#      else
#        class_name.underscore
#      end
#    end

    def views_path
      if @namespaced
        "#{module_name.underscore}/#{class_name.underscore}"
      else
        class_name.underscore
      end
    end

    def factory_path
      if @namespaced
        "#{module_name.underscore}"
      else
        "."
      end
    end

    def validate_name
      errors = []
      
      # For namespaced names, validate module existence
      if @namespaced
        class_name.split("::")[0..-2].each do |part|
# This code is crashing the generator. TODO: Fix it.
#          unless Module.const_defined?(part)
#            errors << "#{part} is not a valid module"
#          end
        end
      end
        
      # Validate class name format
      unless model_class.match?(/\A[A-Z][a-zA-Z0-9_]*\z/)
        errors << "Model name '#{model_class}' is not a valid Ruby identifier"
      end
       
      if errors.any?
        say_status :error, "Name validation failed:", :red
        errors.each { |error| say_status :error, "  - #{error}", :red }
        say_status :info, "Generator aborted. Please fix the name and try again.", :yellow
        exit 1
      end
    end

    def process_fields
      puts "DEBUG: Starting process_fields with args: #{args.inspect}"
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
      
      puts "DEBUG: Found #{errors.length} errors and #{valid_fields.length} valid fields"
      
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
            say_status :info, "Generator aborted. Please fix errors and run again.", :yellow
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
      
      puts "DEBUG: Final @fields: #{@fields.inspect}"
      @fields
    end

    def create_model_file
      template "model.rb.erb", File.join('app', 'models', "#{file_path}.rb")
    end
    
    def create_factory_file
      template "factory.rb.erb", File.join('test', 'factories', "#{controller_file_path}.rb")
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
      template "controller.rb.erb", File.join('app', 'controllers', "#{controller_file_path}_controller.rb")
    end
    
    def create_view_files
      template "views/index.html.erb", File.join('app', 'views', controller_file_path, 'index.html.erb')
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
        
        if class_path.any?
          # Find the insertion point
          insertion_pattern = /^(\s*)(namespace\s+:#{class_path.last}\s+do)$/
          if content.match?(insertion_pattern)
            content.sub!(insertion_pattern) do
              # $1 is the captured indentation, $2 is the namespace line
              "#{$1}#{$2}\n#{$1}  resources :#{plural_name}\n"
            end
          else
            say_status :error, "#{routes_file.relative_path_from(Rails.root)}: Could not find namespace for #{class_path.last}", :red
            return
          end
        else
          # Non-namespaced case - insert before root path route
          root_pattern = /(# Defines the root path route)/
          if content.match?(root_pattern)
            content.sub!(root_pattern) do
              "\nresources :#{plural_name}\n\n#{$1}"
            end
          else
            say_status :error, "#{routes_file.relative_path_from(Rails.root)}: Could not find root path route", :red
            return
          end
        end
        
        File.write(routes_file, content) unless options[:pretend]
        say_status :update, "#{routes_file.relative_path_from(Rails.root)}: Updated with #{plural_name} resources", :green
      else
        say_status :error, "#{routes_file.relative_path_from(Rails.root)}: Not found", :red
      end
    end
         
    def update_constants
      # Update module constants with enum definitions
      constants_file = @namespaced ? "#{class_path[0]}.yml" : "core.yml"
      constants_file = Pathname.new(File.join(destination_root, "config", "constants", constants_file))
      if File.exist?(constants_file)
        content = File.read(constants_file)
        
        # Add the model key
        if @namespaced
          module_key = "#{class_path.last}:"
          # Find the module key and capture its indentation
          insertion_pattern = /^(\s*)(#{module_key})/
          model_key = "#{singular_name}:"
          
          # Insert after the module key
          if content.match?(insertion_pattern)
            content.sub!(insertion_pattern) do
              # $1 is the captured indentation, $2 is the module key
              "#{$1}#{$2}\n#{$1}#{model_key}\n"
            end
          else
            say_status :error, "#{constants_file.relative_path_from(Rails.root)}: Could not find module key #{module_key}", :red
            return
          end
        else
          # Non-namespaced case - add at root level
          model_key = "#{singular_name}:"
          content += "\n#{model_key}\n"
        end
        
        # Add enum fields if they exist
        enum_fields = @fields.select { |field| field[:type] == 'enum' || field[:type] == 'enum_translated' }
        enum_fields.each do |field|
          field_name = field[:name]
          field_indent = " " * ((class_path.count) * 2)
          content += "#{field_indent}#{field_name}:\n"
          content += "#{field_indent}  #{field_name}_other: 0  # TODO: Add enum values\n"
        end
        
        File.write(constants_file, content) unless options[:pretend]
        say_status :update, "#{constants_file.relative_path_from(Rails.root)}: Added #{singular_name} key", :green
      else
        say_status :error, "#{constants_file.relative_path_from(Rails.root)}: Not found", :red
      end
    end

    def add_translations
      I18n.available_locales.each do |locale|
        translation_file = Pathname.new(File.join(destination_root, "config", "locales", 
          @namespaced ? module_path : "core", locale.to_s, "#{locale}.#{class_path[-1]}.models.yml"))
        
        if File.exist?(translation_file)
          content = File.read(translation_file)  
          # Prepare model name and attributes sections
          model_section = "      #{file_path}: \"#{human_name}\"\n"
          attributes_section = "      #{file_path}:\n"
          
          @fields.each do |field|
            # Use field[:name].humanize as dummy translation
            attributes_section += "        #{field[:name]}: \"#{field[:name].humanize}\"\n"
            
            # Add enum translations for enum_translated fields
            if field[:type] == 'enum_translated'
              attributes_section += "          #{field[:name].pluralize}:\n"
              attributes_section += "            other_#{field[:name]}: \"Other #{field[:name].humanize}\"\n"
            end
          end
          
          # Insert model name under models section
          if content.match?(/(\s+models:)/)
            content.sub!(/(\s+models:)/) { "#{$1}\n#{model_section}" }
          else
            say_status :error, "#{translation_file.relative_path_from(Rails.root)}: Models key not found", :red
            return
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
          @namespaced ? module_path : "core", locale.to_s, "#{locale}.#{class_path[-1]}.views.yml"))
        
        if File.exist?(views_file)
          content = File.read(views_file)
          
          # Prepare views translations section
          views_section = "    #{plural_name}:\n" +
            "      index:\n" +
            "        title:            \"#{human_name.pluralize}\"\n" +
            "        header:           \"#{human_name.pluralize} Schedule for %{project}\"\n" +
            "      edit:\n" +
            "        title:            \"Edit #{human_name}\"\n" +
            "        header:           \"Edit #{human_name}: %{label}\"\n" +
            "      new:\n" +
            "        title:            \"New #{human_name}\"\n" +
            "        header:           \"New #{human_name}\"\n" +
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