require "rails/generators/named_base"

module ProjectAssistant
  class TagableGenerator < Rails::Generators::NamedBase
    include Rails::Generators::ResourceHelpers
    source_root File.expand_path("tagable/templates", __dir__)
    RAILS_FIELD_TYPES = %w[ string text integer bigint float decimal datetime timestamp time date binary boolean primary_key jsonb ].freeze
    SPECIAL_FIELD_TYPES = %w[enum enum_translated].freeze
    VALID_FIELD_TYPES = (RAILS_FIELD_TYPES + SPECIAL_FIELD_TYPES).freeze
    VALID_OPTIONS = %w[required index uniq].freeze

    def module_name
      class_path[0].classify
    end

    def tagable_name
      file_name.classify
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
    
    def create_migration_file
      migration_name = "create_#{singular_table_name}"
      timestamp = Time.now.utc.strftime("%Y%m%d%H%M%S")
      migration_file = File.join(destination_root, "db/migrate/#{timestamp}_#{migration_name}.rb")
      
      template "migration.rb.erb", migration_file
    end
    
    def create_policy_file
      template "policy.rb.erb", "app/policies/#{file_path}_policy.rb"
    end
    
    def create_factory_file
      template "factory.rb.erb", "test/factories/#{controller_file_path}.rb"
    end

  end
end