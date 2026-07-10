require "rails/generators/named_base"
require_relative 'field_types'

module ProjectAssistant
  class TagableGenerator < Rails::Generators::NamedBase
    include Rails::Generators::ResourceHelpers
    include FieldTypes
    desc "Create scaffolding and config entries for a tagable model"
    source_root File.expand_path("tagable/templates", __dir__)
    class_option :definition, type: :string, desc: "Fields definition file name"
    FLOAT_REGEX = /\A-?(?:\d+\.?\d*|\.\d+)(?:[eE][+-]?\d+)?\z/
    INTEGER_REGEX = /\A-?\d+\z/
    IDENTIFIER_REGEX = /\A[a-z][a-z0-9_]*\z/
    
    def initialize(args, *options)
      super
      # validate_name
    end

    def module_name
      class_name.split("::")[0..-2].join("::")  # "Module::SubModule".
    end

    def tagable_name
      file_name.classify      # "Tagable"
    end

    def validate_name
      # $stderr.puts "DEBUG: validating name: #{class_name.inspect}"
      errors = []
      
      # Validate that we have a module and class name
      if !class_name.include?("::")
        errors << "Name must include both module and class with '::' separator"
      else
      
        # Validate module exists (does not work in test environment)
        unless Rails.env.test?
          unless module_name.safe_constantize
            errors << "Module #{module_name} is not defined"
          end
          folder = File.join(destination_root, "app", "models")
          class_name.split("::")[0..-2].each do |part|
            folder = File.join(folder, part.underscore)
            unless Dir.exist?(folder)
              errors << "Module #{module_name} may have incomplete folder structure"
            end
          end
        end
        
        # Validate class name format
        unless tagable_name.match?(/^[A-Z][a-zA-Z0-9_]*$/)
          errors << "'#{tagable_name}' is not a valid Ruby class name"
        end
      end
      
      if errors.any?
        # $stderr.puts "DEBUG: errors: #{errors.inspect}"
        say_status :error, "Name validation failed:", :red
        errors.each { |error| say_status :error, "  - #{error}", :red }
        say_status :info, "Please fix the name and try again.", :yellow
        raise Thor::Error, "Aborting generator"
      end
    end

    def resolve_fields
      # Check for option to load arguments from file
      if options[:definition]
        if args.count > 0
          say_status :error, "Cannot process command line arguments and file input together", :red
          raise Thor::Error, "Aborting generator"
        else
          @input_fields = load_definition(options[:definition])
        end
      else
        @input_fields = process_cli
      end
    end
    
    no_tasks do
        
      def load_definition(name)
        path_yml = Rails.root.join("lib/generators/project_assistant/tagable/definitions/#{name}.yml")
        path_rb  = Rails.root.join("lib/generators/project_assistant/tagable/definitions/#{name}.rb")

        if File.exist?(path_yml)
            # $stderr.puts "DEBUG: reading file: #{path_yml.inspect}"
          data = YAML.load_file(path_yml).deep_symbolize_keys
            # $stderr.puts "DEBUG: normalizing data: #{data.inspect}"
          normalize_fields(data)
        elsif File.exist?(path_rb)
          eval(File.read(path_rb)) # or require safely
        else
          say_status :error, "#{path_yml}: Could not find definition file", :red
          raise Thor::Error, "Aborting generator"
        end
      end

      def normalize_fields(hash)
        hash.map do |name, attrs|
          {
            name: name.to_s,
            type: attrs[:type],
            options: attrs.except(:type)
          }
        end
      end

      def process_cli
        # Split the argument into parts. The cli cannot accept ':' separators in options, 
        # ':' can only be used to separate name, type, and options.
        @input_fields = args.map do |arg|
          name, type, *opts = arg.split(':')
            # $stderr.puts "DEBUG: cli opts: #{opts.inspect}"

          options = opts.to_h do |opt|
            key, value = opt.split('=', 2)

            [key.to_sym, value.nil? ? true : value]
          end

          { name:, type:, options: }
        end
      end

    end # no_tasks

    def process_fields
      errors = []
      valid_fields = []
        # $stderr.puts "DEBUG: input_fields: #{@input_fields.inspect}"
      
      @input_fields.each do |field|
        field => { name:, type:, options: }
          # $stderr.puts "DEBUG: field name: #{name.inspect},  type: #{type.inspect}, options: #{options.inspect}"
        begin
          # Validate field name
          unless name&.match?(IDENTIFIER_REGEX)
            errors << "#{name}: invalid field name. Must be a valid Ruby identifier."
            next
          end
          
          # Validate field type (no defaults)
          if type.nil?
            errors << "#{name}: missing field type. Please specify a valid type."
            next
          end
          
          type = type.to_sym
          unless VALID_FIELD_TYPES.include?(type)
            errors << "#{name}: unknown field type #{type}. Valid types are: #{VALID_FIELD_TYPES.join(', ')}."
            next
          end

          # Validate options
          # set flag
          all_options_valid = true
          options.each do |key, value|
            # $stderr.puts "DEBUG: checking option: key: #{key.inspect}, value: #{value.inspect}"
            case key
            when :required, :index, :uniq, :unique
              value, error = coerce(value, :boolean)
              if error
                errors << "#{name} option #{key}: #{error}"
                # clear flag
                all_options_valid = false
                next
              end
              options[key] = value

            when :valid
              value, error = coerce(value, type)
              if error
                errors << "#{name} option #{key}: #{error}"
                # clear flag
                all_options_valid = false
                next
              end
              options[key] = value

            when :keys
              key_list = coerce_array(value)
              unless key_list.is_a?(Array)
                errors << "Key list for #{name} #{type} could not be formed into a valid array." 
                # clear flag
                all_options_valid = false
                next
              end
              key_list.each do |enum_key|
                unless enum_key.to_s.match?(IDENTIFIER_REGEX)
                  errors << "#{name}: Invalid enum key #{enum_key}, must be valid ruby identifier."
                  # clear flag
                  all_options_valid = false
                end
              end
              options[key] = key_list

            when :precision, :scale
              unless %i[decimal float].include?(type)
                errors << "#{name}: #{key} is not a valid option for #{type}." 
                # clear flag
                all_options_valid = false
              end
              value, error = coerce(value, :integer)
              if error
                errors << "#{name} option #{key}: #{key} value must be :integer."
                # clear flag
                all_options_valid = false
                next
              end
              options[key] = value

            when :units
              unless %i[decimal float].include?(type)
                errors << "#{name}: #{key} is not a valid option for #{type}" 
                # clear flag
                all_options_valid = false
              end
              value, error = coerce(value, :string)
              options[key] = value

            when :si
              unless %i[decimal float].include?(type)
                errors << "#{name}: #{key} is not a valid option for #{type}" 
                # clear flag
                all_options_valid = false
              end
              value, error = coerce(value, :boolean)
              if error
                errors << "#{name} option #{key}: #{error}"
                # clear flag
                all_options_valid = false
                next
              end
              options[key] = value

            when :step
              unless %i[decimal float integer bigint].include?(type)
                errors << "#{name}: #{key} is not a valid option for #{type}" 
                # clear flag
                all_options_valid = false
                next
              end
              value, error = coerce(value, :decimal)
              if error
                errors << "#{name} option #{key}: #{error}"
                # clear flag
                all_options_valid = false
                next
              end
              options[key] = value
            else
              errors << "#{name} option #{key}: not a valid option"
              # clear flag
              all_options_valid = false
              next
            end
          end

          if all_options_valid
            valid_fields << { name:, type:, options: }
              # $stderr.puts "DEBUG: valid field: name: #{name.inspect},  type: #{type.inspect}, options: #{options.inspect}"
          end
        rescue ArgumentError => e
          errors << "Invalid attribute: #{arg} - #{e.message}"
        end
      end
      
      # Handle validation results
      if errors.any?
        say_status :error, "Validation errors found:", :red
        errors.each { |error| say_status :error, "  - #{error}", :red }
        say_status :info, "Please fix the errors and run again.", :yellow
          # $stderr.puts "DEBUG: errors: #{errors.inspect}"
        raise Thor::Error, "Aborting generator"
      else
        @fields = valid_fields
        say_status :info, "All #{valid_fields.length} fields are valid.", :green
      end
      
      @fields
    end

    no_tasks do
      def coerce(value, type)
        str = value.to_s

        coerced =
          case type
          when :integer
            raise ArgumentError unless str.match?(INTEGER_REGEX)
            Integer(str)

          when :float
            raise ArgumentError unless str.match?(FLOAT_REGEX)
            Float(str)

          when :decimal
            raise ArgumentError unless str.match?(FLOAT_REGEX)
            BigDecimal(str)

          when :boolean
            case str.downcase
            when 'true', '1'  then true
            when 'false', '0' then false
            else
              raise ArgumentError
            end

          else
            str
          end

        [coerced, nil]

      rescue ArgumentError, TypeError
        [value, "Invalid #{type} value: #{value.inspect}"]
      end

      def coerce_array(value)
        return value if value.is_a?(Array)

        str = value.to_s.strip

        if str.start_with?("[") && str.end_with?("]")
          str[1..-2].split(",").map(&:strip)
        else
          str.split(",").map(&:strip)
        end
      end

      def options_to_kwargs(options)
        options.except(:valid, :index, :unique).map { |k, v| "#{k}: #{v.inspect}" }.join(", ")
      end

    end # no_tasks

    def setup_field_sets
      @all_field_names = @fields.map { |field| 
          case field[:type]
          when *ProjectAssistant::FieldTypes::ASSOCIATION_TYPES
            "#{field[:name]}_id"
          else
            "#{field[:name]}"
          end
        }
      @index_fields = @fields.select { |field| ProjectAssistant::FieldTypes::INDEX_TYPES.include?(field[:type]) }
      @searchable_fields = @fields.select { |field| ProjectAssistant::FieldTypes::SEARCHABLE_TYPES.include?(field[:type]) }
      @association_fields = @fields.select { |field| ProjectAssistant::FieldTypes::ASSOCIATION_TYPES.include?(field[:type]) }
      @attribute_fields = @fields - @association_fields
      @enum_fields = @fields.select { |field| %i[enum enum_translated].include?(field[:type]) }
      @required_fields = @fields.select { |field| field[:options][:required] == true }
      @unique_fields = @fields.select { |field| field[:options][:unique] == true || field[:options][:uniq] == true }
        # $stderr.puts "DEBUG: field sets:"
        # $stderr.puts "DEBUG: all_field_names #{@all_field_names.inspect}"
        # $stderr.puts "DEBUG: index_fields #{@index_fields.inspect}"
        # $stderr.puts "DEBUG: searchable_fields #{@searchable_fields.inspect}"
        # $stderr.puts "DEBUG: association_fields #{@association_fields.inspect}"
        # $stderr.puts "DEBUG: attribute_fields #{@attribute_fields.inspect}"
        # $stderr.puts "DEBUG: fields #{@fields.inspect}"
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
        
        # Find the first insertion point comment and insert after it
        insertion_pattern = /(namespace\s+:#{class_path.last}\s+do.*?# INSERTION POINT 1 FOR TAGABLE GENERATOR)/m
        if content.match?(insertion_pattern)
          content.sub!(insertion_pattern) do
            "#{$1}\n    resources :#{plural_name}, only: [:index, :new, :create]"
          end
        else
          say_status :error, "#{routes_file.relative_path_from(Rails.root)}: Could not find insertion point 1 for tagable generator", :red
          return
        end
        
        # Find the second insertion point comment and insert after it
        insertion_pattern = /(namespace\s+:#{module_name.underscore}\s+do.*?# INSERTION POINT 2 FOR TAGABLE GENERATOR)/m
        if content.match?(insertion_pattern)
          content.sub!(insertion_pattern) do
            "#{$1}\n      resources :#{plural_name}, except: [:index]"
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
        # Check that the module key is present
        # Add enum keys for fields of type :enum or :enum_translated
        tab = "  "
        found = content.sub!(insertion_pattern) do
          m = Regexp.last_match
          indent = m[:indent]

          text = +"#{indent}#{m[:key]}\n"
          text << "#{indent}#{tab}#{model_key}:\n"

          @enum_fields.each do |field|
            text << "#{indent}#{tab*2}#{field[:name]}:\n"
            field[:options][:keys].each_with_index do |k, i|
              text << "#{indent}#{tab*3}#{k}:#{tab}#{i}\n"
            end
          end
          text
          # $stderr.puts "DEBUG: enum fields text: #{text.inspect}"
        end
        if found
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
          *class_path, locale.to_s, "#{locale}.#{class_path[-1]}.models.yml"))
        
        if File.exist?(translation_file)
          content = File.read(translation_file)  
          # Prepare model name and attributes sections
          tab = "  "
          model_section = +"#{tab*3}#{file_path}:\n"
          model_section += "#{tab*4}one: \"#{human_name}\"\n"
          model_section += "#{tab*4}other: \"#{human_name.pluralize}\"\n"
          attributes_section = +"#{tab*3}#{file_path}:\n"
          @fields.each do |field|
            # Use field[:name].humanize as dummy translation
            attributes_section += "#{tab*4}#{field[:name]}: #{field[:name].humanize}\n"
            
            # Add enum translations for enum_translated fields
            if field[:type] == :enum_translated
              attributes_section += "#{tab*4}#{field[:name].pluralize}:\n"
              field[:options][:keys].each do |key|
                attributes_section += "#{tab*5}#{key}: #{key.humanize}\n"
              end
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

    private

  end
end