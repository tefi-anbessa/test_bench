require "rails/generators/named_base"
require_relative 'shared/scaffold_helper'

module ProjectAssistant
  class ScaffoldGenerator < Rails::Generators::NamedBase
    include Rails::Generators::ResourceHelpers
    include ProjectAssistant::Shared::ScaffoldHelper
    source_root File.expand_path("scaffold/templates", __dir__)
    class_option :definition, type: :string, desc: "Fields definition file name"
    class_option :nesting, type: :string, desc: "Parent class, options: none (default), project, discipline, tag, document, issue"
    
    def validate_nesting
      # $stderr.puts "DEBUG (GENERATOR): options[:nesting]: #{options[:nesting].inspect} (#{options[:nesting].class})"
      errors = []
      if options[:nesting].present?
        unless options[:nesting].in? %w[project discipline tag document issue none]
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

    def validate_name
      # $stderr.puts "DEBUG (Generator): args #{args}"
      @namespaced = class_path.any?
      errors = []
      # $stderr.puts "DEBUG (GENERATOR): validating name: #{class_name.inspect}"
      
      if @namespaced
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
      # $stderr.puts "DEBUG: GENERATOR: fields: #{@fields} \nnesting: #{@nesting}\nenum_fields: #{@enum_fields}"
    end

    def create_model_file
      @ransack_attributes = (@searchable_fields.map { |f| f[:name].to_sym } + %i[created_at updated_at]).uniq
      @ransack_associations = (@association_fields.map { |f| f[:name].to_sym } ).uniq
      if @nesting.in?(%i[project discipline tag])
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
        if @nesting == :none
          insertion_pattern = /^(\s*)(# Insertion point for non-nested routes)$/
        else
          insertion_pattern = /^(\s*)(end # #{@nesting.to_s} nested routes)$/
        end
        if content.match?(insertion_pattern)
          content.sub!(insertion_pattern) do
            # $1 is the captured indentation, $2 is the end comment line
            "#{$1}#{tab}resources :#{plural_name}\n#{$1}#{$2}"
          end
        else
          say_status :error, "#{routes_file.relative_path_from(Rails.root)}: Could not find routes section for #{@nesting.to_s}", :red
          return
        end
        
        File.write(routes_file, content) unless options[:pretend]
        say_status :update, "#{routes_file.relative_path_from(Rails.root)}: Updated with #{plural_name} resources", :green
      else
        say_status :error, "#{routes_file.relative_path_from(Rails.root)}: Not found", :red
      end
    end
         
    def update_constants
      insert_enum_constants
    end

    def add_translations
      insert_translations
    end
  end
end