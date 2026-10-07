# frozen_string_literal: true
# lib/generators/project_assistant/shared/scaffold_helpers.rb
module ProjectAssistant
  module Shared
    module ScaffoldHelper
      # Constants

      # Don't edit these unless rails introduces new types.
      RAILS_FIELD_TYPES = %i[
        string text integer bigint float decimal 
        datetime timestamp time date binary boolean primary_key jsonb
      ].freeze

      # Types can be added, but you will have to write the generator and test code to implement them.
      SPECIAL_FIELD_TYPES = %i[references belongs_to enum enum_translated].freeze

      # Don't edit this.
      VALID_FIELD_TYPES = (RAILS_FIELD_TYPES + SPECIAL_FIELD_TYPES).freeze

      # Options can be added, but you will have to write the generator and test code to implement them.
      VALID_OPTIONS = %i[required index uniq unique valid precision scale units si step max min].freeze
      # required will add a validation to the model and a null: false in the migration.
      # index will add an index to the migration.
      # uniq or unique will add a unique index to the migration.
      # valid will provide the given value as a default to the test factory
      # precision and scale will provide those options to decimal and float types
      # units and si (boolean) will be used in presentation of decimal or float numbers.
      # step, max and min will be used in number fields for forms.
      
      # These types (remaining after the subtraction) will include a searchable field in the index view.
      # You can tweak the list as required before generation, leave it as you found it.
      # Number fields are not really searchable for content, they generally require comparison operators. 
      # You can write your own search fields for ransack in the index view.
      SEARCHABLE_TYPES = (VALID_FIELD_TYPES - %i[
        references belongs_to integer bigint float decimal 
        datetime timestamp time date binary boolean primary_key
      ]).freeze
        
      # These types (remaining after the subtraction) will include a column in the index view.
      # The index view should only include fields that will easily tabulate.
      # You can tweak the list as required before generation, leave it as you found it.
      INDEX_TYPES = (VALID_FIELD_TYPES - %i[primary_key binary]).freeze

      # These types will generate an associated drop down card in show view.
      ASSOCIATION_TYPES = %i[references belongs_to]

      APP_DIRECTORIES = %w[controllers helpers models policies views]
      TEST_DIRECTORIES = %w[controllers factories models policies system]
      FLOAT_REGEX = /\A-?(?:\d+\.?\d*|\.\d+)(?:[eE][+-]?\d+)?\z/
      INTEGER_REGEX = /\A-?\d+\z/
      IDENTIFIER_REGEX = /\A[a-z][a-z0-9_]*\z/

      private
      
        # Additional helper methods to supplement NamedBase methods
        # Comments assume name argument is "ModuleName::SubModule::ClassName"
        def module_name # Equivalent to class_name without the model class part
          class_name.split("::")[0..-2].join("::")  # "ModuleName::SubModule"
        end

        def folder
          File.join(*@class_path) # "existing_module/sub_module"
        end

        def model_class_name
          class_name.split('::').last # "NewModel"
        end

        def i18n_model_scope
          @namespaced ? "#{folder}/#{singular_name}" : singular_name
        end

        def name_setup_for_test
          # Generator::NamedBase methods not available in test environment
          # @class_name examples: ModuleName::SubModule::NewModel; ModuleName::NewModel; NewModel
          @module_name = @class_name.split("::")[0..-2].join("::")  # "ModuleName::SubModule"; "ModuleName"; ""
          @model_class_name = @class_name.split('::').last # "NewModel"
          @singular_name = @model_class_name.underscore # "new_model"
          @plural_name = @singular_name.pluralize # "new_models"
          @human_name = @singular_name.humanize # "New model"
          @class_path = @module_name.split('::').to_a.map(&:underscore) # ["existing_module", "sub_module"]; ["existing_module"]; []
          @namespaced = @class_path.any?
          @table_name = [*@class_path, @singular_name.pluralize].join"_" # "existing_module_sub_module_new_models"; "existing_module_new_models"; "new_models"
          @singular_table_name = @table_name.singularize # "existing_module_sub_module_new_model"; "existing_module_new_model"; "new_model"
          @folder = File.join(*@class_path) # "existing_module/sub_module"; "existing_module"; ""
          # @i18n_scope mimics NamedBased but is inaptly named. It is used for Constants.
          @i18n_scope = [*@class_path, @singular_name].join('.') # "existing_module.sub_module.new_model"; "existing_modulenew_model"; "new_model"
          # @i18n_model_scope actually matches the keys required for activerecord translations.
          @i18n_model_scope = @namespaced ? "#{@folder}/#{@singular_name}" : @singular_name # "existing_module/sub_module/new_model"; "existing_module/new_model"; "new_model"
        end
      
        # Helper methods for path generation
        def i18n_views_insertion_point
          if @namespaced
            "#{class_path[-1]}:"
          else
            class_name.underscore
          end
        end

        def index_path(nesting)
          case nesting
          when :tagable
            "discipline_tagables_path(@discipline, tagable_type: '#{class_name}')"
          when :none
            "#{table_name}_path"
          else
            "#{nesting.to_s}_#{table_name}_path(@#{nesting.to_s})"
          end
        end

        def new_path(nesting)
          case nesting
          when :tagable
            # Generic, shared route (see index_path's :tagable case for
            # the same pattern) - there's no per-type route since the
            # "retire per-type tagable routes" refactor.
            "new_discipline_tagable_path(@discipline, tagable_type: '#{class_name}')"
          when :none
            "new_#{singular_table_name}_path"
          else
            "new_#{nesting.to_s}_#{singular_table_name}_path(@#{nesting.to_s})"
          end
        end

        def new_build(nesting)
          case nesting
          when :tagable
            # Used for the nav_button's record: (labeling/path purposes
            # only - the actual policy check target for tagable models is
            # a new Tag, hardcoded separately in index.html.erb, since
            # every tagable type shares the generic tags association).
            # See app/views/electrical/switchboards/index.html.erb for
            # the same pattern in a real, working view.
            "#{class_name}.new"
          when :none
            "#{class_name}.new"
          else
            "@#{nesting.to_s}.#{table_name}.build"
          end
        end

        def policy_resource_class
          case @nesting
          when :project, :discipline, :tag
            "#{@nesting.to_s.camelize}ResourcePolicy"
          when :tagable
            "#{@nesting.to_s.camelize}Policy"
          when :none
            "ApplicationPolicy"
          end
        end

        def policy_test_class
          case @nesting
          when :project, :discipline, :tag
            "#{@nesting.to_s.camelize}ResourcePolicyTest"
          when :tagable
            "TagablePolicyTest"
          else
            nil
          end
        end

        def controller_mixin
          case @nesting
          when :tagable
            "TagablesController"
          when :none
            ""
          else
            "#{@nesting.to_s.camelize}ResourcesController"
          end
        end

        def paths_to_check(parent)
          [
          # App directories
          *APP_DIRECTORIES.map { |dir| File.join(destination_root, "app", dir, parent) },
          # Test directories
          *TEST_DIRECTORIES.map { |dir| File.join(destination_root, "test", dir, parent) },
          # Locales
          File.join(destination_root, "config", "locales", parent)
          ]
        end

        def prepare_cli(input_args)
          # Split the argument into parts. The cli cannot accept ':' separators in options, 
          # ':' can only be used to separate name, type, and options.
          @input_fields = input_args.map do |arg|
            name, type, *opts = arg.split(':')
              # $stderr.puts "DEBUG (HELPER): cli opts: #{opts.inspect}"

            options = opts.to_h do |opt|
              key, value = opt.split('=', 2)

              [key.to_sym, value.nil? ? true : value]
            end

            { name:, type:, options: }
          end
        end
        
        # Convert YAML format to array of { name: type: options: }
        def load_definition(name)
          path_yml = Rails.root.join("lib/generators/project_assistant/scaffold/definitions/#{name}.yml")
          path_rb  = Rails.root.join("lib/generators/project_assistant/scaffold/definitions/#{name}.rb")

          if File.exist?(path_yml)
              # $stderr.puts "DEBUG (HELPER): reading file: #{path_yml.inspect}"
            data = YAML.load_file(path_yml).deep_symbolize_keys
              # $stderr.puts "DEBUG (HELPER): normalizing data: #{data.inspect}"
            normalize_fields(data)
          # TODO: implement safe load of ruby definition file
          elsif File.exist?(path_rb)
            data = eval(File.read(path_rb)) # or require safely
            normalize_fields(data)
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

        # Debug helper
        def spit(fields)
          cl = +""
          fields.each do |field|
            options = +""
            field[:options].each do |key, value|
              options << ":#{key}=#{value}"
            end
            cl << ("#{field[:name]}:#{field[:type]}#{options} ")
          end
          $stderr.puts cl.inspect
        end
        
        # Test field arguments for validity
        def process_fields(inputs)
          errors = []
          valid_fields = []
            # $stderr.puts "DEBUG (HELPER): input_fields: #{@input_fields.inspect}"
          
          inputs.each do |field|
            @valid = true
            field => { name:, type:, options: }
              # $stderr.puts "DEBUG (HELPER): field name: #{name.inspect},  type: #{type.inspect}, options: #{options.inspect}"
            begin
              # Validate field name
              
              unless name&.match?(IDENTIFIER_REGEX)
                errors << "#{name}: invalid field name. Must be a valid Ruby identifier."
                @valid = false
              end
              
              # Validate field type (no defaults)
              if type.nil?
                errors << "#{name}: missing field type. Please specify a valid type."
                @valid = false
              else
                type = type.to_sym
                unless VALID_FIELD_TYPES.include?(type)
                  errors << "#{name}: unknown field type #{type}. Valid types are: #{VALID_FIELD_TYPES.join(', ')}."
                  @valid = false
                end
              end

              # Validate options
              options.each do |key, value|
                # $stderr.puts "DEBUG (HELPER): checking option: key: #{key.inspect}, value: #{value.inspect}"
                case key
                when :required, :index, :uniq, :unique
                  value, error = coerce(value, :boolean)
                  if error
                    errors << "#{name} option #{key}: #{error}"
                    # clear flag
                    @valid = false
                    next
                  end
                  options[key] = value

                when :valid
                  value, error = coerce(value, type)
                  if error
                    errors << "#{name} option #{key}: #{error}"
                    # clear flag
                    @valid = false
                    next
                  end
                  options[key] = value

                when :keys
                  key_list = coerce_array(value)
                  unless key_list.is_a?(Array)
                    errors << "Key list for #{name} #{type} could not be formed into a valid array." 
                    # clear flag
                    @valid = false
                    next
                  end
                  key_list.each do |enum_key|
                    unless enum_key.to_s.match?(IDENTIFIER_REGEX)
                      errors << "#{name}: Invalid enum key #{enum_key}, must be valid ruby identifier."
                      # clear flag
                    @valid = false
                    end
                  end
                  options[key] = key_list

                when :precision, :scale
                  unless %i[decimal float].include?(type)
                    errors << "#{name}: #{key} is not a valid option for #{type}." 
                    # clear flag
                    @valid = false
                  end
                  value, error = coerce(value, :integer)
                  if error
                    errors << "#{name} option #{key}: #{key} value must be :integer."
                    # clear flag
                    @valid = false
                    next
                  end
                  options[key] = value

                when :units
                  unless %i[decimal float].include?(type)
                    errors << "#{name}: #{key} is not a valid option for #{type}" 
                    # clear flag
                    @valid = false
                  end
                  value, error = coerce(value, :string)
                  options[key] = value

                when :si
                  unless %i[decimal float].include?(type)
                    errors << "#{name}: #{key} is not a valid option for #{type}" 
                    # clear flag
                    @valid = false
                  end
                  value, error = coerce(value, :boolean)
                  if error
                    errors << "#{name} option #{key}: #{error}"
                    # clear flag
                    @valid = false
                    next
                  end
                  options[key] = value

                when :step
                  unless %i[decimal float integer bigint].include?(type)
                    errors << "#{name}: #{key} is not a valid option for #{type}" 
                    # clear flag
                    @valid = false
                    next
                  end
                  value, error = coerce(value, :decimal)
                  if error
                    errors << "#{name} option #{key}: #{error}"
                    # clear flag
                    @valid = false
                    next
                  end
                  options[key] = value
                else
                  errors << "#{name} option #{key}: not a valid option"
                  # clear flag
                  @valid = false
                  next
                end
              end

              if @valid
                valid_fields << { name:, type:, options: }
                  # $stderr.puts "DEBUG (HELPER): valid field: name: #{name.inspect},  type: #{type.inspect}, options: #{options.inspect}"
              end
            rescue ArgumentError => e
              errors << "Invalid attribute: #{arg} - #{e.message}"
            end
          end
          [valid_fields, errors]
        end

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

        def field_sets
          @index_fields = @fields.select { |field| INDEX_TYPES.include?(field[:type]) }
          @searchable_fields = @fields.select { |field| SEARCHABLE_TYPES.include?(field[:type]) }
          @association_fields = @fields.select { |field| ASSOCIATION_TYPES.include?(field[:type]) }
          @attribute_fields = @fields - @association_fields
          @required_fields = @fields.select { |field| field[:options][:required] == true }
          @enum_fields = @fields.select { |field| field[:type].in?(%i[enum enum_translated]) }
          @unique_fields = @fields.select { |field| field[:options][:unique] == true || field[:options][:uniq] == true }      
          @all_field_names = @fields.map { |field| field[:name].to_sym } 
          @index_field_names = @index_fields.map { |field| "#{field[:name]}" } 
          @searchable_field_names = @searchable_fields.map { |field| "#{field[:name]}" } 
          @attribute_names = @attribute_fields.map { |field| "#{field[:name]}" } 
          @association_names = @association_fields.map { |field| "#{field[:name]}" } 
          @params = (@attribute_fields.map { |field| ":#{field[:name]}" } +
                @association_fields.map { |field| ":#{field[:name]}_id" }).join(', ')
        end

        # Set variables for new and edit templates to pass into form
        def set_form_variables(nesting)
          form_variables = ["#{singular_name}: @#{singular_name},\n\t" + "swatch: @swatch"]
          scope = nil
          case nesting
          when :tagable
            form_variables << "tag: @tag"
            form_variables << "parent: @parent"
            # @discipline, not @tag - on the "fresh tag + fresh resource"
            # path (the common case), @tag is a brand new, unpersisted Tag
            # with no prefix/serial yet, so @tag.long_label would be blank
            # or misleading in the new page's header. Confirmed against
            # every real tagable new.html.erb (e.g.
            # electrical/heaters/new.html.erb), which all use
            # @discipline.long_label here instead.
            scope = "scope_text: @discipline.long_label"
          when :none
            scope = "scope_text: @#{singular_name}.long_label"
          else
            form_variables << "#{nesting}: @#{nesting}"
            scope = "scope_text: @#{nesting}.long_label"
          end
          @association_fields.each do |field|
            form_variables << "#{field[:name].pluralize}: @#{field[:name].pluralize}"
          end
          [form_variables, scope]
        end

        def form_model
          case @nesting
          when :none, :tagable
            "#{singular_name}"
          else
            "[#{@nesting}, #{singular_name}]"
          end
        end

        def form_url
          case @nesting
          when :tagable
            "polymorphic_path([parent, :tagable])"
          else
            nil
          end
        end

        def form_discard
          case @nesting
          when :tagable
            ["tag_tagable_path(tag)", "discipline_tagables_path(tag.discipline, tagable_type: '#{class_name}')"]
          when :none
            ["#{singular_name}", "#{plural_route_name}_path"]
          else
            ["#{singular_name}", "#{@nesting}_#{plural_route_name}_path(#{@nesting})"]
          end
        end

        def index_back_link
          case @nesting
          when :tagable
            action = ":show_discipline"
            record = "@discipline"
          when :none
            action = nil
            record = nil
          else
            action = ":show_#{@nesting}"
            record = "@#{@nesting}"
          end
          [action, record]
        end

        def index_scope_text
          case @nesting
          when :tagable
            "[t('activerecord.models.discipline.one'), @discipline.label].join(': ')"
          when :none
            "t('index.all', models: t('activerecord.models.project.other'))"
          else
            "[t('activerecord.models.#{@nesting}.one'), @#{@nesting}.label].join(': ')"
          end
        end

        def show_back_link
          case @nesting
          when :tagable
            "discipline_tagables_path(@discipline, tagable_type: '#{class_name}')"
          when :none
            "#{index_helper(type: 'path')}"
          else
            "#{@nesting}_#{index_helper(type: 'path')}(@#{@nesting})"
          end
        end

        def edit_button_action(nesting)
          case nesting
          when :tagable
            :edit_tagable
          else
            :edit
          end
        end

        # Used only on the show page's own destroy button - confirmed against
        # every real tagable show.html.erb (e.g. electrical/heaters/show.html.erb,
        # electrical/switchboards/show.html.erb), which all use plain :delete
        # here (unlike the index row's :delete_tagable - a different button).
        def delete_button_action(nesting)
          :delete
        end

        def controller_test_create_params
          params = []
          @attribute_fields.each do |field|
            valid = field.dig(:options, :valid) || 
                    (if [:enum, :enum_translated].include?(field[:type])
                      field.dig(:options, :keys)&.first
                    end)
            params << "#{field[:name].to_sym}: #{valid.inspect}"
          end
          @association_fields.each do |field|
            params << "#{field[:name].to_sym}: #{field.dig(:options, :valid).inspect}"
          end
          params
        end

        # Shared between ScaffoldGenerator and TagableGenerator - inserts an
        # enum-constants key for the new model into its module's constants
        # file (or core.yml for a non-namespaced model). No nesting-specific
        # logic at all; genuinely identical for every nesting type.
        def insert_enum_constants
          constants_file = @namespaced ? "#{class_path[0]}.yml" : "core.yml"
          constants_file = Pathname.new(File.join(destination_root, "config", "constants", constants_file))
          if File.exist?(constants_file)
            content = File.read(constants_file)
            tab = "  "
            if @enum_fields.any?
              insertion_text = "#{singular_name}:\n"
              @enum_fields.each do |field|
                field_name = field[:name]
                field_indent = tab * (1 + class_path.count)
                insertion_text += "#{field_indent}#{field_name}:\n"
                if field[:options][:keys].any?
                  field[:options][:keys].each_with_index do |key, index|
                    insertion_text += "#{field_indent}#{tab}#{key}: #{index}\n"
                  end
                end
              end
            else
              insertion_text = "#{singular_name}: {}\n"
            end

            if @namespaced
              module_key = "#{class_path.last}:"
              key_pattern = /^([ \t]*)#{Regexp.escape(module_key)}[ \t]*\n/
              if (match = content.match(key_pattern))
                indent = match[1]
                insert_at = match.end(0)
                rest = content[insert_at..]
                block_end = rest =~ /^#{Regexp.escape(indent)}\S/
                insert_at += block_end || rest.length
                needs_newline = insert_at > 0 && content[insert_at - 1] != "\n"
                content = content[0...insert_at] + (needs_newline ? "\n" : "") + "#{indent}#{tab}#{insertion_text}" + content[insert_at..]
              else
                say_status :error, "#{constants_file.relative_path_from(Rails.root)}: Could not find module key #{module_key}", :red
                return
              end
            else
              content += "\n#{insertion_text}"
            end

            File.write(constants_file, content) unless options[:pretend]
            say_status :update, "#{constants_file.relative_path_from(Rails.root)}: Added #{singular_name} key", :green
          else
            say_status :error, "#{constants_file.relative_path_from(Rails.root)}: Not found", :red
          end
        end

        # Shared between ScaffoldGenerator and TagableGenerator - edits the
        # model translations file for each locale. No nesting-specific logic
        # anywhere in this method.
        def insert_translations
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
              model_section = tab*(2 + class_path.count) + "#{i18n_model_scope}:\n" +
                tab*(3 + class_path.count) + "one: \"#{human_name}\"\n" +
                tab*(3 + class_path.count) + "other: \"#{human_name.pluralize}\"\n"
              attributes_section = tab*(2 + class_path.count) + "#{i18n_model_scope}:\n"

              @fields.each do |field|
                attributes_section += tab*(3 + class_path.count) + "#{field[:name]}: \"#{field[:name].humanize}\"\n"
                if field[:type] == :enum_translated
                  attributes_section += tab*(3 + class_path.count) + "#{field[:name].pluralize}:\n"
                  field[:options][:keys].each do |key|
                    attributes_section += tab*(4 + class_path.count) + "#{key}: \"#{key.to_s.humanize}\"\n"
                  end
                end
              end

              model_insertion_regex = /models:[ \t]*(\{\})?\n/
              attributes_insertion_regex = /attributes:[ \t]*(\{\})?\n/
              if content.match?(model_insertion_regex)
                content.sub!(model_insertion_regex) { "models:\n#{model_section}" }
              else
                say_status :error, "#{translation_file.relative_path_from(Rails.root)}: Models key not found", :red
                return
              end

              if content.match?(attributes_insertion_regex)
                content.sub!(attributes_insertion_regex) { "attributes:\n#{attributes_section}" }
                File.write(translation_file, content) unless options[:pretend]
                say_status :update, "#{translation_file.relative_path_from(Rails.root)}: Added #{class_name} translations", :green
              else
                say_status :error, "#{translation_file.relative_path_from(Rails.root)}: Attributes key not found", :red
              end
            else
              say_status :error, "#{translation_file.relative_path_from(Rails.root)}: Not found", :red
            end

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
              views_section = tab*2 + "#{plural_name}:\n" +
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

              if @namespaced
                module_key = class_path.last
                module_key_pattern = /^([ \t]*)#{Regexp.escape(module_key)}:[ \t]*(\{\})?[ \t]*\n?/
                if content.match?(module_key_pattern)
                  content.sub!(module_key_pattern) { "#{$1}#{module_key}:\n#{views_section}" }
                else
                  say_status :error, "#{views_file.relative_path_from(Rails.root)}: #{module_key} key not found", :red
                  return
                end
              else
                content += "\n#{views_section}"
              end

              File.write(views_file, content) unless options[:pretend]
              say_status :update, "#{views_file.relative_path_from(Rails.root)}: Added #{class_name} views translations", :green
            else
              say_status :error, "#{views_file.relative_path_from(Rails.root)}: Not found", :red
            end
          end
        end

        # Shared with TagableGenerator's system_test.rb.erb - a best-effort
        # default for TagableSystemTests' @edit_attributes (only string/text
        # fields work there at present, per its own callers' use of
        # `fill_in`), preferring a field named "notes" since that's the
        # convention nearly every tagable model already follows.
        def tagable_edit_attributes_stub
          field = @attribute_fields.find { |f| f[:name] == "notes" && f[:type].in?(%i[string text]) } ||
                  @attribute_fields.find { |f| f[:type].in?(%i[string text]) }
          return "{}" unless field
          "{ #{field[:name]}: \"Updated value\" }"
        end

        # Shared with TagableGenerator's views/index.html.erb - the fixed
        # part of the "broken/incomplete links" row's colspan (stage + tag +
        # the model's own index fields + the links column). The project
        # column is conditional on current_project at runtime, so it's added
        # separately in the view itself, not here.
        def tagable_index_colspan
          2 + @index_fields.count + 1
        end

        def test_assertions_model(content, nesting)
          # Check for mixins
          if nesting == :tagable
            assert_includes content, "include Tagable"
          end

          # Check for constants
          @enum_fields.each do |f|
            assert_includes content, "enum :#{f[:name]}, Constants.#{@i18n_scope}.#{f[:name]}.to_h"
          end

          # Check for gem macros
          unless nesting == :tagable
            assert_includes content, "has_paper_trail"
          end

          # Check for associations
          @association_fields.each do |field|
            assert_includes content, "belongs_to :#{field[:name]}"
          end
          unless nesting.in?(%i[none tagable])
            assert_includes content, "belongs_to :#{nesting}"
          end

          # Check for presence validations on required fields
          @required_fields.each do |f|
            assert_includes content, "validates :#{f[:name]}, presence: true"
          end
        
          # Check ransackable_attributes
          assert_includes content, "def self.ransackable_attributes"
          match = content.match(/ransackable_attributes.*?\[(.*?)\]/m)
          array_code = match[0][/\[.*\]/m]
          attributes = eval(array_code)

          @searchable_fields.each do |field|
            assert_includes attributes, field[:name].to_sym,
              "Expected #{field[:name]} to be in ransackable_attributes"
          end
          %i[created_at updated_at].each do |timestamp|
            assert_includes attributes, timestamp, "Expected #{timestamp} to be in ransackable_attributes"
          end
          
          # Check ransackable_associations
          assert_includes content, "def self.ransackable_associations"
          match = content.match(/ransackable_associations.*?\[(.*?)\]/m)
          array_code = match[0][/\[.*\]/m]
          attributes = eval(array_code)
          @association_fields.each do |field|
            assert_includes attributes, field[:name].to_sym,
              "Expected #{field[:name]} to be in ransackable_associations"
          end
          if nesting == :tagable
            [:tag, :tag_discipline, :tag_discipline_project].each do |field|
              assert_includes attributes, field,
                "Expected #{field} to be in ransackable_associations"
            end
          end
        end

        def test_assertions_factory(content, nesting)
          assert_includes content, "factory :#{@singular_table_name}"
          assert_includes content, "class: #{@class_name}"
          @association_fields.each do |field|
            assert_includes content, "association :#{field[:name]}"
          end 
          @attribute_fields.each do |field|
            valid = field.dig(:options, :valid) || 
              (if [:enum, :enum_translated].include?(field[:type])
                field.dig(:options, :keys)&.first
              end)
          assert_match(/#{field[:name]}\s+\{\s+#{valid.inspect}\s*\}/, content)
          end
        end

        def test_assertions_model_test(content, nesting = nil)
          assert_includes content, "class #{@model_class_name}Test < ActiveSupport::TestCase"
          required_attributes = @required_fields - @association_fields
          required_associations = @required_fields & @association_fields
          if required_attributes.any?
            assert_includes content, "test_required_fields(#{required_attributes.map { |f| ":#{f[:name]}" }.join(", ")})"
          end
          if required_associations.any?
            assert_includes content, "test_required_associations(#{required_associations.map { |f| ":#{f[:name]}" }.join(", ")})"
          end
          if @unique_fields.any?
            assert_includes content, "test_unique_fields(#{@unique_fields.map { |f| ":#{f[:name]}" }.join(", ")})"
          end
          assert_includes content, "include ModelTestMacros" unless nesting == :tagable
          @enum_fields.each do |field|
            assert_includes content, "test_enum_field(:#{field[:name]}, prefix: true)"
          end
          translated_fields = @enum_fields.select { |f| f[:type] == :enum_translated }
          if translated_fields.any?
            assert_includes content, "test_enum_translations(#{translated_fields.map { |f| ":#{f[:name]}" }.join(", ")})"
          end
        end

        def test_assertions_migration(content, nesting)
          # Check fields are created, with null: false for required fields.
          assert_includes content, "class Create#{@class_name.gsub('::', '')}"
          assert_includes content, "create_table :#{@table_name}"
          @attribute_fields.each do |field|
            field_type =
              case field[:type]
              # Check for translation of custom types
              when :enum, :enum_translated
                "integer"
              else
                field[:type].to_s
              end
            target = "t.#{field_type} :#{field[:name]}"
            options = []
            if field.dig(:options, :required)
              options << "null: false"
            end
            if field.dig(:options, :uniq) || field.dig(:options, :unique)
              options << "index: { unique: true }"
            elsif field.dig(:options, :index)
              options << "index: true"
            end
            target = /
              t\.#{field_type}\s+:#{field[:name]}   # start of the column
              (.*?)                   # capture everything after
              (?=\n\s*t\.|\nend)      # stop at next column or end
            /mx
            match = content.match(target)
            assert match, "Expected to find t.#{field_type} :#{field[:name]}"
            options.each do |opt|
              assert_includes match[1], opt,
                "Expected #{opt} in definition of #{field[:name]}"
            end
          end
          @association_fields.each do |field|
            assert_includes content, "t.references :#{field[:name]}, foreign_key: true"
          end
        end

        def test_assertions_policy(content, nesting)
          assert_includes content, "class #{@model_class_name}Policy < #{policy_resource_class}"
        end

        def test_assertions_policy_test(content, nesting)
          assert_includes content, "class #{@model_class_name}PolicyTest < #{policy_resource_class}"
        end

        def test_assertions_controller(content, nesting)
          assert_includes content, "class #{@model_class_name.pluralize}Controller < ApplicationController"
          target = /
            def\s+resource_params\s*
            params\.require\(:#{@singular_table_name}\)\s*
            \.permit\(
            (.*?)\)
          /mx
          match = content.match(target)
          assert match, "Expected to find def params..."
          @attribute_fields.each do |field|
            assert_includes match[1], field[:name]
          end
          @association_fields.each do |field|
            assert_includes match[1], "#{field[:name]}_id"
          end
        end

        def test_assertions_controller_extension(content)
          assert_includes content, "module #{@module_name}"
          assert_includes content, "module #{@model_class_name}Extension"
          target = /
            def\s+tagable_params\s*
            params\.require\(:#{@singular_table_name}\)\s*
            \.permit\(
            (.*?)\)
          /mx
          match = content.match(target)
          assert match, "Expected to find def tagable_params..."
          @attribute_fields.each do |field|
            assert_includes match[1], field[:name]
          end
          @association_fields.each do |field|
            assert_includes match[1], "#{field[:name]}_id"
          end
        end

        def test_assertions_index_view(content, nesting)
          # The policy check target differs from the nav_button record for
          # :tagable - see index.html.erb's own new_policy_target logic:
          # tagable models share one generic tags association for policy
          # purposes, but the nav_button's record just needs a new
          # instance of the actual class for labeling/path purposes.
          policy_target = nesting == :tagable ? "@discipline.tags.build()" : new_build(nesting)
          if nesting == :tagable
            # Confirmed against every real tagable index.html.erb (e.g.
            # electrical/heaters/index.html.erb) - the new-button is also
            # guarded on @discipline.present?, not just the policy check.
            assert_includes content, "if @discipline.present? && policy(#{policy_target}).new?"
          else
            assert_includes content, "if policy(#{policy_target}).new?"
          end
          assert_includes content, "nav_button(action: :new, path: #{new_path(nesting)}, record: #{new_build(nesting)}"
          @searchable_fields.each do |field|
            assert_includes content, "f.search_field :#{field[:name]}_cont"
            # i18n key uses "/" not "." between module and model - previously untested
            assert_includes content, "placeholder: t(\"activerecord.attributes.#{i18n_model_scope}.#{field[:name]}\")"
          end
          header = File.join(*@class_path, @plural_name, "header")
          assert_includes content, "render '#{header}'"
          row = File.join(*@class_path, @plural_name, "row")
          assert_includes content, "render '#{row}', row: row"
        end

        def test_assertions_header_view(content, nesting)
          @index_fields.each do |field|
            assert_includes content, "sort_link(@q, :#{field[:name]})"
          end
        end

        def test_assertions_row_view(content, nesting)
          @index_fields.each do |field|
            case field[:type]
            when :string
              assert_includes content, "index_attribute(row, :#{field[:name]}"
            when :enum, :enum_translated, :integer, :bigint, :decimal, :float, :boolean, :date, :datetime, :timestamp, :jsonb, :binary
              assert_includes content, "index_attribute(row, :#{field[:name]}, type: :#{field[:type]}"
            end
          end
          if nesting == :tagable
            assert_includes content, "nav_button(action: :show_tagable, record: row, icon_only: true)"
            assert_includes content, "nav_button(action: :edit_tagable, record: row, icon_only: true)"
            assert_includes content, "nav_button(action: :delete_tagable, record: row, icon_only: true)"
          else
            assert_includes content, "nav_button(action: :show, record: row, icon_only: true)"
            assert_includes content, "nav_button(action: :edit, record: row, path: edit_#{singular_table_name}_path(row), icon_only: true)"
            assert_includes content, "nav_button(action: :destroy, record: row, icon_only: true)"
          end
        end

        def test_assertions_show_view(content, nesting)
          case nesting
          when :tagable
            action_suffix = "_tagable"
            index_action = "index_discipline"
            index_policy_target = "@#{@singular_name}.tag"
            new_record = new_build(nesting)
            edit_path_fragment = "path: edit_tag_tagable_path(@tag), "
            delete_path_fragment = "path: tag_tagable_path(@tag), "
          else
            action_suffix = ""
            index_action = "index"
            index_policy_target = "@#{@singular_name}"
            new_record = "@#{@singular_name}"
            edit_path_fragment = ""
            delete_path_fragment = ""
          end
          assert_includes content, "<% provide(:title, t('.title')) %>"
          assert_includes content, "policy(#{index_policy_target}).index?"
          assert_includes content, "nav_button(action: :#{index_action}, path: #{index_path(nesting)}, record: @#{@singular_name})"
          assert_includes content, "nav_button(action: :previous#{action_suffix}, record: @neighbours[0])"
          assert_includes content, "nav_button(action: :next#{action_suffix}, record: @neighbours[1])"
          assert_includes content, "<%= t('.header', label: "
          assert_includes content, "nav_button(action: :#{edit_button_action(nesting)}, #{edit_path_fragment}record: @#{@singular_name})"
          assert_includes content, "nav_button(action: :#{delete_button_action(nesting)}, #{delete_path_fragment}record: @#{@singular_name})"
          assert_includes content, "nav_button(action: :new, path: #{new_path(nesting)}, record: #{new_record}"
          @attribute_fields.each do |field|
            case field[:type]
            # Breaking these lines causes errors...
            when :string
              assert_includes content, "show_attribute(@#{@singular_name}, :#{field[:name]})"
            when :integer, :bigint, :boolean, :date, :datetime, :timestamp, :time, :enum, :enum_translated
              assert_includes content, "show_attribute(@#{@singular_name}, :#{field[:name]}, type: :#{field[:type]}"
            when :float, :decimal
              assert_includes content, "show_attribute(@#{@singular_name}, :#{field[:name]}, type: :#{field[:type]}"
            when :text, :jsonb
              assert_includes content, "show_attribute(@#{@singular_name}, :#{field[:name]}, type: :#{field[:type]}"
            when :binary
              assert_includes content, "PLACEHOLDER FOR BINARY FIELD"
            end
          end
          case nesting
          when :tag, :discipline, :project
            assert_includes content, "show_association(@#{@singular_name}, :#{nesting})"
          when :tagable
            assert_includes content, "show_association(@#{@singular_name}, :tag)"
          end
          @association_fields.each do |field|
            assert_includes content, "show_association(@#{@singular_name}, :#{field[:name]})"
          end
        end

        def test_assertions_new_view(content, nesting)
          form_variables, scope = set_form_variables(nesting)
          assert_includes content, "provide(:title, t('.title'))"
          assert_includes content, "provide(:header, t('.header'"
          if scope.present?
            assert_includes content, scope
          end
          assert_includes content, "render partial"
          assert_includes content, [*form_variables].join(",\n\t")
          # _form.html.erb references a bare `parent` local for its
          # polymorphic_path - must be passed through as a local here too
          assert_includes content, "parent: @parent" if nesting == :tagable
        end

        def test_assertions_edit_view(content, nesting)
          form_variables, scope = set_form_variables(nesting)
          assert_includes content, "provide(:title, t('.title'))"
          assert_includes content, "provide(:header, t('.header', label: @#{@singular_name}.label))"
          assert_includes content, "render partial"
          assert_includes content, [*form_variables].join(",\n\t")
        end

        def test_assertions_form_view(content, nesting)
          assert_includes content, "yield(:header)"
          assert_includes content, "html: { novalidate: true }"
          case nesting
          when :none, :tagable
            assert_includes content, "bootstrap_form_with(model: #{@singular_name}"
          else
            assert_includes content, "bootstrap_form_with(model: [#{nesting}, #{@singular_name}]"
          end
          @fields.each do |field|
            case field[:type]
            when :string
              assert_match(/form_field\(f,\s*:#{field[:name]}/, content)
            when :text
              assert_match(/form_field\(f,\s*:#{field[:name]},\s*type:\s*:text/, content)
            when :jsonb
              assert_match(/form_field\(f,\s*:#{field[:name]},\s*type:\s*:jsonb/, content)
            when :integer, :bigint, :float, :decimal
              assert_match(/form_field\(f,\s*:#{field[:name]},\s*type:\s*:number/, content)
            when :datetime, :timestamp, :time
              assert_match(/form_field\(f,\s*:#{field[:name]},\s*type:\s*:datetime/, content)
            when :date
              assert_match(/form_field\(f,\s*:#{field[:name]},\s*type:\s*:date/, content)
            when :boolean
              assert_match(/form_field\(f,\s*:#{field[:name]},\s*type:\s*:boolean/, content)
            when :enum
              assert_match(/form_field\(f,\s*:#{field[:name]},\s*type:\s*:enum\)/, content)
            when :enum_translated
              assert_match(/form_field\(f,\s*:#{field[:name]},\s*type:\s*:enum_translated/, content)
            when :references, :belongs_to
              assert_match(/form_field\(f,\s*:#{field[:name]},\s*type:\s*:select/, content)
            end
          end
        end

        def test_assertions_card_view(content, nesting)
          # Anchored on "<%=", not just the bare call - assert_includes on the
          # bare text can't tell a rendered "<%= ... %>" from a silent,
          # output-dropping "<% ... %>" (confirmed missing here once already).
          assert_includes content, "<%= nav_link(action: :show, record: #{singular_name}) %>"
          @attribute_fields.each do |field|
            case field[:type]
            # Breaking these lines causes errors...
            when :string
              assert_includes content, "show_attribute(#{singular_name}, :#{field[:name]})"
            when :integer, :bigint, :boolean, :date, :datetime, :timestamp, :time, :enum, :enum_translated
              assert_includes content, "show_attribute(#{singular_name}, :#{field[:name]}, type: :#{field[:type]}"
            when :float, :decimal
              assert_includes content, "show_attribute(#{singular_name}, :#{field[:name]}, type: :#{field[:type]}"
            when :text, :jsonb
              assert_includes content, "show_attribute(#{singular_name}, :#{field[:name]}, type: :#{field[:type]}"
            when :binary
              assert_includes content, "PLACEHOLDER FOR BINARY FIELD"
            end
          end
          @association_fields.each do |field|
            assert_includes content, "show_attribute(#{singular_name}, :#{field[:name]}, type: :association)"
          end
        end

        def test_assertions_controller_test(content, nesting)
          assert_includes content, "class #{@model_class_name.pluralize}ControllerTest"
          case nesting
          when :tag, :document, :discipline, :project
            assert_includes content, "@nesting = #{nesting.inspect}"
            assert_includes content, "setup_controller_test"
            assert_includes content, "include ControllerTestHelper"
            assert_includes content, "@resource = create(:#{@singular_table_name}, #{nesting.to_s}: @#{nesting.to_s})"
          when :tagable
            # Confirmed against every real tagable controller test (e.g.
            # test/controllers/electrical/switchboards_controller_test.rb) -
            # no @nesting assignment, and a different setup method entirely
            # (TagableControllerTests never defines setup_controller_test).
            assert_includes content, "include TagableControllerTests"
            assert_includes content, "tests TagablesController"
            assert_includes content, "def tagable_type"
            assert_includes content, "setup_tagables_controller_test"
          when :none
            assert_includes content, "@nesting = #{nesting.inspect}"
            assert_includes content, "setup_controller_test"
            assert_includes content, "@resource = create(:#{@singular_table_name})"
          end
          assert_includes content, "def create_params"
          @fields.each do |field|
            assert_includes content, "#{field[:name]}"
          end
        end

        def test_assertions_system_test(content, nesting)
          assert_includes content, "class #{@model_class_name.pluralize}SystemTest < ApplicationSystemTestCase"
          assert_includes content, "include Devise::Test::IntegrationHelpers"
          assert_includes content, "include Warden::Test::Helpers"
          text = @index_field_names.join(" ")
          assert_includes content, "@index_fields = %i[#{text}]"

          text = @searchable_field_names.join(" ")
          assert_includes content, "@search_fields = %i[#{text}]"

          text = @attribute_names.join(" ")
          assert_includes content, "@show_fields = %i[#{text}]"

          text = @association_names.join(" ")
          assert_includes content, "@show_associations = %i[#{text}]"

          text = @all_field_names.map { |f| "#{f}: nil" }.join(", ")
          assert_includes content, "@new_fields = { #{text} }"
        end
    end
  end
end