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
          when :tag, :discipline, :project
            "#{nesting.to_s}_#{table_name}_path(@#{nesting.to_s})"
          when :tagable
            "discipline_#{table_name}_path(@#{@discipline})"
          when :none
            "#{table_name}_path"
          end
        end

        def new_path(nesting)
          case nesting
          when :tag, :discipline, :project
            "new_#{nesting.to_s}_#{singular_table_name}_path(@#{nesting.to_s})"
          when :tagable
            "new_discipline_#{singular_table_name}_path(@discipline)"
          when :none
            "new_#{singular_table_name}_path"
          end
        end

        def new_build(nesting)
          case nesting
          when :tag, :discipline, :project
            "@#{nesting.to_s}.#{table_name}.build"
          when :tagable
            "@discipline.#{table_name}.build"
          when :none
            "#{class_name}.new"
          end
        end

        def name_setup_for_test
          # Generator::NamedBase methods not available in test environment
          # @class_name examples: ModuleName::SubModule::NewModel; ModuleName::NewModel; NewModel
          @module_name = @class_name.split("::")[0..-2].join("::")  # "ModuleName::SubModule"; "ModuleName"; ""
          @model_class_name = @class_name.split('::').last # "NewModel"
          @singular_name = @model_class_name.underscore # "new_model"
          @plural_name = @singular_name.pluralize # "new_models"
          @human_name = @singular_name.humanize # "New model"
          @class_path = @module_name.split('::').to_a.map(&:underscore) # ["ExistingModule", "SubModule"]; ["ExistingModule"]; []
          @table_name = [*@class_path, @singular_name.pluralize].join"_" # "existing_module_sub_module_new_models"; "existing_module_new_models"; "new_models"
          @singular_table_name = @table_name.singularize # "existing_module_sub_module_new_model"; "existing_module_new_model"; "new_model"
          @folder = File.join(*@class_path) # "existing_module/sub_module"; "existing_module"; ""
          @index_path = "#{@nesting.to_s}_#{@table_name}_path(@#{@nesting.to_s})"
          @new_path = "new_#{@nesting.to_s}_#{@singular_table_name}_path(@#{@nesting.to_s})"
          @i18n_scope = [*@class_path, @singular_name].join('.') # "existing_module.sub_module.new_model"; "existing_modulenew_model"; "new_model"
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
          when :project, :discipline, :tag
            "#{@nesting.to_s.camelize}ResourcesController"
          when :tagable
            "TagablesController"
          when :none
            ""
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
        end

        def set_form_variables(nesting)
          form_variables = ["#{singular_name}: @#{singular_name}, ""swatch: @swatch"]
          scope = nil
          case nesting
          when :tag, :discipline, :project
            form_variables << "#{nesting}: @#{nesting}"
            scope = "scope_text: @#{nesting}.long_label"
          when :tagable
            form_variables << "tag: @tag"
            scope = "scope_text: @tag.long_label"
          end
          @association_fields.each do |field|
            form_variables << "#{field[:name].pluralize}: @#{field[:name].pluralize}"
          end
          [form_variables, scope]
        end

        def form_url
          case @nesting
          when :tagable
            "#{singular_name}.persisted? ?
            #{singular_name} : 
            ( tag.persisted? ?
              tag_#{plural_route_name}_path(tag) :
              discipline_#{plural_route_name}_path(discipline))"
          when :tag, :discipline, :project
            "#{singular_name}.persisted? ? #{singular_name} : #{@nesting}_#{plural_route_name}_path(#{@nesting})"
          else
            nil
          end
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
          @required_fields.each do |field|
            assert_includes content, "test \"#{field[:name]} must be present\" do"
            assert_includes content, "@resource.#{field[:name]} = nil"
          end
          @unique_fields.each do |field|
            assert_includes content, "test \"#{field[:name]} must be unique\" do"
            assert_includes content, "refute new_resource.valid?"
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
              when 'enum', 'enum_translated'
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

        def test_assertions_index_view(content, nesting)
          assert_includes content, "if policy(#{new_build(nesting)}).new?"
          assert_includes content, "nav_button(action: :new, path: #{new_path(nesting)}, record: #{new_build(nesting)}"
          @searchable_fields.each do |field|
            assert_includes content, "f.search_field :#{field[:name]}_cont"
          end
          assert_includes content, "render 'header'"
          assert_includes content, "render 'row'"
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
        end

        def test_assertions_show_view(content, nesting)
          assert_includes content, "<% provide(:title, t('.title')) %>"
          assert_includes content, "policy(@#{@singular_name}).index?"
          assert_includes content, "nav_button(action: :index, path: #{index_path(nesting)}, record: @#{@singular_name})"
          assert_includes content, "nav_button(action: :previous, record: @neighbours[0])"
          assert_includes content, "nav_button(action: :next, record: @neighbours[1])"
          assert_includes content, "<%= t('.header', label: "
          assert_includes content, "nav_button(action: :edit, record: @#{@singular_name}, path: edit_#{@singular_table_name}_path(@#{@singular_name}))"
          assert_includes content, "nav_button(action: :delete, record: @#{@singular_name})"
          assert_includes content, "nav_button(action: :new, path: #{new_path(nesting)}, record: @#{@singular_name}"
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
            when "binary"
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
          assert_includes content, "render \"form\""
          assert_includes content, [*form_variables].join(', ')
        end

        def test_assertions_edit_view(content, nesting)
          form_variables, scope = set_form_variables(nesting)
          assert_includes content, "provide(:title, t('.title'))"
          assert_includes content, "provide(:header, t('.header', label: @#{@singular_name}.label))"
          assert_includes content, "render \"form\""
          assert_includes content, [*form_variables].join(', ')
        end

        def test_assertions_form_view(content, nesting)
          assert_includes content, "yield(:header)"
          assert_includes content, "bootstrap_form_with(model: #{@singular_name}"
          @fields.each do |field|
            case field[:type]
            when "string"
              assert_match(/f\.text_field\s+:#{field[:name]}/, content)
            when "text"
              assert_match(/f\.text_area\s+:#{field[:name]}/, content)
            when "integer", "bigint"
              assert_match(/f\.number_field\s+:#{field[:name]}/, content)
            when "float", "decimal"
              assert_match(/f\.number_field\s+:#{field[:name]}/, content)
            when "datetime", "timestamp", "time", "date"
              assert_match(/f\.datetime_select\s+:#{field[:name]}/, content)
            when "boolean"
              assert_match(/f\.check_box\s+:#{field[:name]}/, content)
            when "jsonb"
              assert_match(/f\.text_area\s+:#{field[:name]}/, content)
            when "enum"
              assert_match(/f\.select\s+:#{field[:name]}/, content)
            when "enum_translated"
              assert_match(/f\.select\s+:#{field[:name]}/, content)
            end
          end
        end

        def test_assertions_card_view(content, nesting)
          assert_includes content, "nav_link(action: :show, record: #{singular_name})"
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
            when "binary"
              assert_includes content, "PLACEHOLDER FOR BINARY FIELD"
            end
          end
          @association_fields.each do |field|
            assert_includes content, "show_attribute(#{singular_name}, :#{field[:name]}, type: :association)"
          end
        end

        def test_assertions_controller_test(content, nesting)
          assert_includes content, "class #{@model_class_name.pluralize}ControllerTest"
          assert_includes content, "@nesting = #{nesting.inspect}"
          assert_includes content, "setup_controller_test"
          case nesting
          when :tag, :document, :discipline, :project
            assert_includes content, "include ControllerTestHelper"
            assert_includes content, "@resource = create(:#{@singular_table_name}, #{nesting.to_s}: @#{nesting.to_s})"
          when :tagable
            assert_includes content, "include TagableControllerTests"
          when :none
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