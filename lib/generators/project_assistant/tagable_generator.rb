require "rails/generators/named_base"
require_relative 'shared/scaffold_helper'

module ProjectAssistant
  class TagableGenerator < Rails::Generators::NamedBase
    include Rails::Generators::ResourceHelpers
    include ProjectAssistant::Shared::ScaffoldHelper
    source_root File.expand_path("tagable/templates", __dir__)
    class_option :definition, type: :string, desc: "Fields definition file name"

    def validate_name
      @nesting = :tagable
      @namespaced = class_path.any?
      errors = []
      unless @namespaced
        errors << "#{class_name} must be module-prefixed (e.g. Electrical::#{class_name}) - " \
          "every tagable model belongs to a discipline's module"
      else
        paths_to_check(folder).each do |path|
          unless Dir.exist?(path)
            errors << "#{path} not found, module #{module_name} has incomplete folder structure"
          end
        end
      end

      unless model_class_name&.match?(/^[A-Z][a-zA-Z0-9_]*$/)
        errors << "'#{model_class_name}' is not a valid Ruby class name"
      end

      if errors.any?
        say_status :error, "Name validation failed:", :red
        errors.each { |error| say_status :error, "  - #{error}", :red }
        say_status :info, "Please fix the name and try again.", :yellow
        raise Thor::Error, "Aborting generator"
      else
        say_status :info, "Generating tagable model #{model_class_name} in module #{module_name}", :green
      end
    end

    def resolve_fields
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

      if errors.any?
        say_status :error, "Validation errors found:", :red
        errors.each { |error| say_status :error, "  - #{error}", :red }
        say_status :info, "Please fix the errors and run again.", :yellow
        raise Thor::Error, "Aborting generator"
      else
        say_status :info, "All #{@fields.length} fields are valid.", :green if @fields.any?
      end
      field_sets
    end

    def create_model_file
      @ransack_attributes = (@searchable_fields.map { |f| f[:name].to_sym } + %i[created_at updated_at]).uniq
      # Every tagable model ransacks through its tag the same way - no
      # per-model policy to vary this, unlike scaffold_generator's nesting
      # options (see app/models/instrument/pressure_gauge.rb for a real,
      # confirmed example of this exact set).
      @ransack_associations = (@association_fields.map { |f| f[:name].to_sym } + %i[tag tag_discipline tag_discipline_project]).uniq
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

    # Named <model>_extension.rb, singular, directly under the discipline's
    # module folder (e.g. app/controllers/electrical/heater_extension.rb) -
    # NOT controller_file_path, which is the pluralized views/tests path.
    # Confirmed against every real tagable extension file.
    def create_controller_extension_file
      template "controller_extension.rb.erb", File.join('app', 'controllers', *class_path, "#{singular_name}_extension.rb")
    end

    def create_view_files
      @form_variables, @scope = set_form_variables(:tagable)
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

    # Register the new type in config/constants/tagable.yml - the registry
    # delegated_type :tagable on Tag reads via Constants.tagable (see
    # app/models/tag.rb) to know every valid tagable_type. No per-model
    # route to add - tagable routes are entirely generic (see
    # config/routes.rb's "Tagable routes" section), so this registry
    # entry, not a route, is what makes the new type real to the app.
    def update_tagable_registry
      registry_file = Pathname.new(File.join(destination_root, "config", "constants", "tagable.yml"))
      if File.exist?(registry_file)
        content = File.read(registry_file)
        entry_pattern = /^[ \t]*-[ \t]*#{Regexp.escape(class_name)}[ \t]*$/
        if content.match?(entry_pattern)
          say_status :info, "#{registry_file.relative_path_from(Rails.root)}: #{class_name} already registered", :yellow
        else
          content = content.sub(/\n*\z/, "\n")
          content += "  - #{class_name}\n"
          File.write(registry_file, content) unless options[:pretend]
          say_status :update, "#{registry_file.relative_path_from(Rails.root)}: Registered #{class_name} as a tagable type", :green
        end
      else
        say_status :error, "#{registry_file.relative_path_from(Rails.root)}: Not found", :red
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
