require "rails/generators/named_base"
require_relative 'field_types'

module ProjectAssistant
  class TagableGenerator < Rails::Generators::NamedBase
    include Rails::Generators::ResourceHelpers
    include FieldTypes
    source_root File.expand_path("tagable/templates", __dir__)
    
    def module_name
      class_path[0].classify  # Module
    end

    def tagable_name
      file_name.classify      # Tagable
    end

    def process_fields
      @fields = args.map do |arg|
        begin
          # Split the argument into parts
          name, type, *options = arg.split(':')
          
          # Validate field name
          unless name&.match?(/^[a-zA-Z_][a-zA-Z0-9_]*$/)
            say_status :error, "Invalid field name: #{name}. Must be a valid Ruby identifier", :red
            next
          end
          
          # Validate field type# Set default type to string if not provided
          type ||= 'string'
          unless VALID_FIELD_TYPES.include?(type)
            say_status :warning, "Unknown field type '#{type}' for #{name}. Defaulting to 'string'", :yellow
            type = 'string'
          end

          # Validate options
          options = options.uniq # Remove duplicates
          invalid_options = options - VALID_OPTIONS
          unless invalid_options.empty?
            say_status :warning, 
              "Unknown option(s) #{invalid_options.inspect} for #{name}. " \
              "Valid options are: #{VALID_OPTIONS.join(', ')}", :yellow
          end
          { name: name, type: type, options: options }
        rescue ArgumentError => e
          say_status :error, "Invalid attribute: #{arg} - #{e.message}", :red
          next
        end
      end.compact
    end

    def create_model_file
      template "model.rb.erb", "app/models/#{file_path}.rb"
    end
    
    def create_factory_file
      template "factory.rb.erb", "test/factories/#{controller_file_path}.rb"
    end

    def create_model_test_file
      template "model_test.rb.erb", "test/models/#{file_path}_test.rb"
    end
    
    def create_migration_file
      migration_name = "create_#{singular_table_name}"
      timestamp = Time.now.utc.strftime("%Y%m%d%H%M%S")
      migration_file = File.join(destination_root, "db/migrate/#{timestamp}_#{migration_name}.rb")
      
      template "migration.rb.erb", migration_file
    end
      
    def create_policy_file
      template "policy.rb.erb", "app/policies/#{file_path}_policy.rb"
    end
    
    def create_policy_test_file
      template "policy_test.rb.erb", "test/policies/#{file_path}_policy_test.rb"
    end
    
    def create_controller_file
      template "controller.rb.erb", "app/controllers/#{controller_file_path}_controller.rb"
    end
    
    def create_view_files
      template "views/index.html.erb", "app/views/#{controller_file_path}/index.html.erb"
      template "views/_header.html.erb", "app/views/#{controller_file_path}/_header.html.erb"
      template "views/_row.html.erb", "app/views/#{controller_file_path}/_row.html.erb"
      template "views/show.html.erb", "app/views/#{controller_file_path}/show.html.erb"
      template "views/edit.html.erb", "app/views/#{controller_file_path}/edit.html.erb"
      template "views/new.html.erb", "app/views/#{controller_file_path}/new.html.erb"
      template "views/_form.html.erb", "app/views/#{controller_file_path}/_form.html.erb"
      template "views/_card.html.erb", "app/views/#{controller_file_path}/_card.html.erb"
    end
    
    def create_controller_test_file
      template "controller_test.rb.erb", "test/controllers/#{controller_file_path}_controller_test.rb"
    end
         
    def update_constants
      # Update tagable.yml
      tagable_file = File.join(destination_root, 'config/constants/tagable.yml')
      if File.exist?(tagable_file)
        content = File.read(tagable_file)
        # Match the module name in the comment and append the class name
        module_name = class_name.split("::")[0]
        content.sub!(/(#\s+#{module_name}\n)/, "\\1  - #{class_name}\n")
        File.write(tagable_file, content)
      else
        say_status :error, "Tagable file not found: #{tagable_file}", :red
      end
    end
  end
end