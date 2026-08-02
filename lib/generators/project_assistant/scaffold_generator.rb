require "rails/generators/named_base"
require_relative 'shared/scaffold_helper'

module ProjectAssistant
  class ScaffoldGenerator < Rails::Generators::NamedBase
    include Rails::Generators::ResourceHelpers
    include ProjectAssistant::Shared::ScaffoldHelper
    source_root File.expand_path("scaffold/templates", __dir__)
    class_option :definition, type: :string, desc: "Fields definition file name"
    class_option :nesting, type: :string, desc: "Parent class, options: none (default), project, discipline, tag, tagable)"

    def validate_name
      # $stderr.puts "DEBUG (Generator): args #{args}"
      @namespaced = class_path.any?
      errors = []
      # $stderr.puts "DEBUG (GENERATOR): validating name: #{class_name.inspect}"
      
      # Validate that we have a module and class name for tagables
      if @nesting == :tagable && !class_name.include?("::")
        errors << "Name for tagable must include both module and class with '::' separator"
      # Check for existence of module paths required
      elsif @namespaced
        # Validate module/sub-module exists
        paths_to_check(folder).each do |path|
          unless Dir.exist?(path)
            errors << "#{path} not found, module #{module_name} has incomplete folder structure"
          end
        end
      end
        
      # Validate class name format
      unless model_class_name&.match?(/^[A-Z][a-zA-Z0-9_]*$/)
        errors << "'#{model_class_name}' is not a valid Ruby class name"
      end
      
      if errors.any?
        # $stderr.puts "DEBUG (GENERATOR): validating name: errors: #{errors.inspect}"
        say_status :error, "Name validation failed:", :red
        errors.each { |error| say_status :error, "  - #{error}", :red }
        say_status :info, "Please fix the name and try again.", :yellow
        raise Thor::Error, "Aborting generator"
      else
        if @namespaced
          say_status :info, "Generating model #{model_class_name} in module #{module_name}", :green
        else
          say_status :info, "Generating model #{model_class_name} in core application", :green
        end
      end
    end
    
    def validate_nesting
      # $stderr.puts "DEBUG (GENERATOR): options[:nesting]: #{options[:nesting].inspect} (#{options[:nesting].class})"
      errors = []
      if options[:nesting].present?
        unless options[:nesting].in? %w[project discipline tag document issue tagable none]
          errors << "Invalid nesting option #{options[:nesting]}"
        end
        @nesting = options[:nesting].to_sym
      else
        @nesting = :none
      end
      
      if errors.any?
        # $stderr.puts "DEBUG (GENERATOR): nesting errors: #{errors.inspect}"
        say_status :error, "Nesting option validation failed:", :red
        errors.each { |error| say_status :error, "  - #{error}", :red }
        say_status :info, "Please use valid nesting option and try again.", :yellow
        raise Thor::Error, "Aborting generator"
      end
      say_status :info, "Running generator with nesting option #{@nesting}", :green
      # $stderr.puts "DEBUG (GENERATOR): nesting: #{@nesting.inspect} (#{@nesting.class})"
      # $stderr.puts "DEBUG (GENERATOR): errors: #{@errors.inspect}"
    end


    def resolve_fields
      # Check for option to load arguments from file
      if options[:definition]
        if args.count > 1
          say_status :error, "Cannot process command line arguments and file input together", :red
          raise Thor::Error, "Aborting generator"
        else
          input_fields = load_definition(options[:definition])
        end
      else
        input_fields = prepare_cli(args || [])
      end
      @fields, errors = process_fields(input_fields)
          
      # Handle validation results
      if errors.any?
        say_status :error, "Validation errors found:", :red
        errors.each { |error| say_status :error, "  - #{error}", :red }
        say_status :info, "Please fix the errors and run again.", :yellow
          # $stderr.puts "DEBUG (GENERATOR): errors: #{errors.inspect}"
        raise Thor::Error, "Aborting generator"
      else
        say_status :info, "All #{@fields.length} fields are valid.", :green if @fields.any?
        # spit(@fields)
      end
      # Set up field sets convenience variables
      field_sets
      $stderr.puts "DEBUG: GENERATOR: fields: #{@fields} \nnesting: #{@nesting}\nenum_fields: #{@enum_fields}"
    end

    def create_model_file
      @ransack_attributes = (@searchable_fields.map { |f| f[:name].to_sym } + %i[created_at updated_at]).uniq
      @ransack_associations = (@association_fields.map { |f| f[:name].to_sym } ).uniq
      if @nesting == :tagable
        @ransack_associations += [:tag, :tag_discipline, :tag_discipline_project]
      elsif @nesting.in?(%i[project discipline tag])
        @ransack_associations += [@nesting]
      end
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
      @params = [@attribute_fields.map { |field| ":#{field[:name]}" }, 
                @association_fields.map { |field| ":#{field[:name]}_id" } ].join(', ')
      template "controller.rb.erb", File.join('app', 'controllers', "#{controller_file_path}_controller.rb")
    end
    
    def create_view_files
      @form_variables, @scope = set_form_variables(@nesting)
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
      tab = "  "
      routes_file = Pathname.new(File.join(destination_root, "config", "routes.rb"))
      if File.exist?(routes_file)
        content = File.read(routes_file)
        
        if @namespaced
          # Find the insertion point
          insertion_pattern = /^(\s*)(namespace\s+:#{class_path.last}\s+do)$/
          if content.match?(insertion_pattern)
            content.sub!(insertion_pattern) do
              # $1 is the captured indentation, $2 is the namespace line
              "#{$1}#{$2}\n#{$1}#{tab}resources :#{plural_name}\n"
            end
          else
            say_status :error, "#{routes_file.relative_path_from(Rails.root)}: Could not find namespace for #{class_path.last}", :red
            return
          end
        else
          # Non-namespaced case - insert before root path route
        insertion_pattern = /# Insertion point for non-nested routes/
          if content.match?(insertion_pattern)
            content.sub!(root_pattern) do
              "\n  resources :#{plural_name}\n\n#{$1}"
            end
          else
            say_status :error, "#{routes_file.relative_path_from(Rails.root)}: Could not find insertion point for non-nested routes", :red
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
              "\n#{$1}#{$2}#{$1}#{model_key}"
            end
          else
            say_status :error, "#{constants_file.relative_path_from(Rails.root)}: Could not find module key #{module_key}", :red
            return
          end
        else
          # Non-namespaced case - add at root level
          model_key = "\n#{singular_name}:"
          content += "#{model_key}\n"
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
        if @namespaced
          translation_file = Pathname.new(File.join(destination_root, "config", "locales", 
          folder, locale.to_s, "#{locale}.#{class_path[-1]}.models.yml"))
        else 
          translation_file = Pathname.new(File.join(destination_root, "config", "locales", 
          "core", locale.to_s, "#{locale}.models.yml"))
        end
        tab = "  "
        if File.exist?(translation_file)
          content = File.read(translation_file)
          # Prepare model name and attributes sections
          model_section = tab*(2 + class_path.count) + "#{singular_name}: #{human_name}"
          attributes_section = tab*(2 + class_path.count) + "#{singular_name}:\n"
          
          @fields.each do |field|
            # Use field[:name].humanize as dummy translation
            attributes_section += tab*(3 + class_path.count) + "#{field[:name]}: \"#{field[:name].humanize}\"\n"
            
            # Add enum translations for enum_translated fields
            if field[:type] == 'enum_translated'
              attributes_section += tab*(3 + class_path.count) + "#{field[:name].pluralize}:\n"
              attributes_section += tab*(4 + class_path.count) + "other_#{field[:name]}: \"Other #{field[:name].humanize}\"\n"
            end
          end
          
          model_insertion_regex = /models:\n/
          attributes_insertion_regex = /attributes:\n/
          # Insert model name under models section
          if content.match?(model_insertion_regex)
            content.sub!(model_insertion_regex) { "models:\n#{$1}#{$2}:\n#{model_section}\n" }
          else
            say_status :error, "#{translation_file.relative_path_from(Rails.root)}: Models key not found", :red
            return
          end
          
          # Insert attributes under attributes section
          if content.match?(attributes_insertion_regex)
            content.sub!(attributes_insertion_regex) { "attributes:\n#{$1}#{$2}:\n#{attributes_section}" }
            File.write(translation_file, content) unless options[:pretend]
            say_status :update, "#{translation_file.relative_path_from(Rails.root)}: Added #{class_name} translations", :green
          else
            say_status :error, "#{translation_file.relative_path_from(Rails.root)}: Attributes key not found", :red
          end
        else
          say_status :error, "#{translation_file.relative_path_from(Rails.root)}: Not found", :red
        end
        
        # Handle views translations
        if @namespaced
          views_file = Pathname.new(File.join(destination_root, "config", "locales", 
          folder, locale.to_s, "#{locale}.#{class_path[-1]}.views.yml"))
        else
          views_file = Pathname.new(File.join(destination_root, "config", "locales", 
          "core", locale.to_s, "#{locale}.views.yml"))
        end
        if File.exist?(views_file)
          content = File.read(views_file)
          tab = "  "
          # Prepare views translations section
          views_section = "\n" + tab*2 + "#{plural_name}:\n" +
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
            "        header:           \"#{human_name}: %{label}\""
          
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