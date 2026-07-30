# test/generators/module_generator_test.rb
require 'test_helper'
require Rails.root.join('lib', 'generators', 'project_assistant', 'tagable_generator').to_s
require Rails.root.join('lib', 'generators', 'project_assistant', 'module_generator').to_s
require Rails.root.join('lib', 'generators', 'project_assistant', 'shared', 'scaffold_helper').to_s
require "yaml"

module ProjectAssistant
  class TagableGeneratorTest < Rails::Generators::TestCase
    include ProjectAssistant::Shared::ScaffoldHelper
    tests ProjectAssistant::TagableGenerator
    destination Rails.root.join('tmp', 'generators', 'tagable')
    setup :prepare_destination

    setup do
      @module_name = "Electrical"
      @tagable_name = "Test"
      # Generator::NamedBase methods are not available in the test environment so we replicate the ones we need.
      @file_name = "#{@module_name.underscore}_#{@tagable_name.underscore}" # electrical_test
      @table_name = "#{@module_name.underscore}_#{@tagable_name.underscore.pluralize}" # electrical_tests
      @class_name = "#{@module_name}::#{@tagable_name}" # Electrical::Test
      @folder_name = "#{@module_name.underscore}" # electrical
      @singular_name = "#{@tagable_name.underscore}" # test
      @plural_name = "#{@tagable_name.underscore.pluralize}" # tests
      @controller_file_path = File.join(@module_name.underscore, @plural_name.underscore) # electrical/tests
      @i18n_key = File.join(@module_name.underscore, @tagable_name.underscore) # electrical/test
      
      # Create clean files for testing (avoid conflicts with real app files)
      FileUtils.mkdir_p(File.join(destination_root, 'config'))
      FileUtils.mkdir_p(File.join(destination_root, 'config', 'constants'))
      
      # Create clean routes.rb with insertion points
      File.write(File.join(destination_root, 'config', 'routes.rb'), <<~RUBY)
        Rails.application.routes.draw do
          # INSERTION POINT 1 FOR MODULE GENERATOR
          
          resources :tags, shallow: true do
            # INSERTION POINT 2 FOR MODULE GENERATOR
          end
        end
      RUBY
      
      # Create clean tagable.yml
      File.write(File.join(destination_root, 'config', 'constants', 'tagable.yml'), <<~YAML)
        tagable:
        YAML
      
      # Ensure test app includes config/application.rb
      File.write(File.join(destination_root, 'config/application.rb'), <<~RUBY
        module TestApp
          class Application < Rails::Application
          end
        end
      RUBY
      )

      # Generate a module (silently)
      capture(:stdout) do
        ProjectAssistant::ModuleGenerator.start([@module_name], destination_root: destination_root)
      end

      # Dummy arguments for the command line
      @args = ["#{@module_name}::#{@tagable_name}", 
        'name:string:required:valid=Test_name',
        'description:text:valid=Test',
        'selector:enum:keys=[a,b,c]:valid=a',
        'status:enum_translated:keys=[alpha,bravo]:valid=bravo',
        'sort_order:integer:index:step=10:valid=100',
        'power:float:precision=5:scale=3:units=kJ:step=1:valid=2.2',
        'money:decimal:units=$:precision=7:scale=2:step=.01:valid=5555.55',
        'switch:boolean:valid=true',
        'birthday:date',
        'created:datetime',
        'flex_field:jsonb',
        'code:string:uniq:valid=AA',
        'parent:references:required=false',
        'owner:belongs_to:required'
      ]
      
      # Mimic the generator's process_cli method.
      @fields = @args[1..-1].map do |arg|
        name, type, *opts = arg.split(':')

        options = opts.to_h do |opt|
          key, value = opt.split('=', 2)

          [key.to_sym, value.nil? ? true : value]
        end
        type = type.to_sym
        { name:, type:, options: }
      end
      # $stderr.puts "DEBUG: Fields: #{@fields.inspect}"
      # Mimic the generator field sets.
      @all_field_names = @fields.map { |field| 
          case field[:type]
          when *ProjectAssistant::Shared::ScaffoldHelper::ASSOCIATION_TYPES
            "#{field[:name]}_id"
          else
            "#{field[:name]}"
          end
        }
      @index_fields = @fields.select { |field| ProjectAssistant::Shared::ScaffoldHelper::INDEX_TYPES.include?(field[:type]) }
      @searchable_fields = @fields.select { |field| ProjectAssistant::Shared::ScaffoldHelper::SEARCHABLE_TYPES.include?(field[:type]) }
      @association_fields = @fields.select { |field| ProjectAssistant::Shared::ScaffoldHelper::ASSOCIATION_TYPES.include?(field[:type]) }
      @attribute_fields = @fields - @association_fields
      @required_fields = @fields.select { |field| field[:options][:required] == true }
      @enum_fields = @fields.select { |field| %i[enum enum_translated].include?(field[:type]) }
      @enum_fields.each do |field| 
        str = field[:options][:keys]
        field[:options][:keys] = 
          if str.start_with?("[") && str.end_with?("]")
            str[1..-2].split(",").map(&:strip)
          else
            str.split(",").map(&:strip)
          end
      end
      @unique_fields = @fields.select { |field| field[:options][:unique] == true || field[:options][:uniq] == true }
    end

    test "module generator setup complete" do
      assert_file File.join("app", "models", "#{@folder_name}", "base.rb")
      assert_file File.join("app", "models", "#{@folder_name}.rb")
      assert_file File.join("config", "constants", "tagable.yml")
    end

    test "generator runs without errors from cli" do
      output = capture(:stderr) do
        run_generator @args
      end
      assert_no_match(/error/i, output)
    end

    test "generator runs without errors from definition file" do
      output = capture(:stderr) do
        run_generator [@class_name, "--definition=electrical_test"]
      end
      assert_no_match(/error/i, output)
    end

    test "protects against mixing command line and file input" do
      output = capture(:stderr) do
        run_generator [@class_name, "--definition=electrical_test"]
      end
      assert_no_match(/error/i, output)
      output = capture(:stderr) do
        run_generator [@class_name, "name:string", "--definition=electrical_test"]
      end
      assert_match(/Aborting generator/i, output, "Expected errors in #{output}")
    end

    test "validates missing module name" do
      generator = ProjectAssistant::TagableGenerator.new(
        ["Test", "name:string"],
        {},
        destination_root: destination_root
      )

      assert_raises(Thor::Error) do
        generator.invoke_all
      end
    end

    test "validates name with invalid class name" do
      generator = ProjectAssistant::TagableGenerator.new(
        ["Electrical::123Invalid", "name:string"],
        {},
        destination_root: destination_root
      )

      assert_raises(Thor::Error) do
        generator.invoke_all
      end
    end

    test "validates name with non-existent module" do
      skip "Test environment does not test for module existence"
      generator = ProjectAssistant::TagableGenerator.new(
        ["NonExistent::Heater", "name:string"],
        {},
        destination_root: destination_root
      )
      assert_raises(Thor::Error) do
        generator.invoke_all
      end
    end

    test "validates correct name format" do
      generator = ProjectAssistant::TagableGenerator.new(
        ["#{@module_name}::#{@tagable_name}", "name:string"],
        {},
        destination_root: destination_root
      )
      assert_nothing_raised do
        generator.invoke_all
      end
    end

    test "validates invalid field names" do
      generator = ProjectAssistant::TagableGenerator.new(
        ["#{@module_name}::#{@tagable_name}", "123invalid:string", "invalid-name:string", "invalid name:string", "Start:string", "includeCapital:string"],
        {},
        destination_root: destination_root)
      assert_raises(Thor::Error) do
        generator.invoke_all
      end
    end

    test "validates missing field types" do
      generator = ProjectAssistant::TagableGenerator.new(
        ["#{@module_name}::#{@tagable_name}", "name:", "description"],
        {},
        destination_root: destination_root)
      assert_raises(Thor::Error) do
        generator.invoke_all
      end
    end

    test "validates unknown field types" do
      generator = ProjectAssistant::TagableGenerator.new(
        ["#{@module_name}::#{@tagable_name}", "name:invalid_type", "description:123unknown"],
        {},
        destination_root: destination_root)
      assert_raises(Thor::Error) do
        generator.invoke_all
      end
    end

    test "validates unknown field options" do
      generator = ProjectAssistant::TagableGenerator.new(
        ["#{@module_name}::#{@tagable_name}", "name:string:invalid_option", "description:text:unknown:another_invalid"],
        {},
        destination_root: destination_root)
      assert_raises(Thor::Error) do
        generator.invoke_all
      end
    end

    test "validates flag options require a valid boolean" do
      generator = ProjectAssistant::TagableGenerator.new(
        ["#{@module_name}::#{@tagable_name}", "name:string:required=5", "description:text:uniq=yes"],
        {},
        destination_root: destination_root)
      assert_raises(Thor::Error) do
        generator.invoke_all
      end
    end

    test "validates valid options requires a value of the correct type" do
      generator = ProjectAssistant::TagableGenerator.new(
        ["#{@module_name}::#{@tagable_name}", "count:integer:valid=5.5", "power:float:valid=true", "switch:boolean:valid=NO"],
        {},
        destination_root: destination_root)
      assert_raises(Thor::Error) do
        generator.invoke_all
      end
    end

    test "validates keys option requires an array of identifiers" do
      generator = ProjectAssistant::TagableGenerator.new(
        ["#{@module_name}::#{@tagable_name}", "select1:enum:keys=5.5", "select2:enum:keys={key1,key2}", "select3:enum_translated:keys=a,b", "select4:enum:keys=[Capital,in-line]"],
        {},
        destination_root: destination_root)
      assert_raises(Thor::Error) do
        generator.invoke_all
      end
    end

    test "validates scale, precision options on invalid types" do
      generator = ProjectAssistant::TagableGenerator.new(
        ["#{@module_name}::#{@tagable_name}", "name:string:precision=5", "description:text:scale=2"],
        {},
        destination_root: destination_root)
      assert_raises(Thor::Error) do
        generator.invoke_all
      end
    end

    test "validates scale, precision options with invalid value" do
      generator = ProjectAssistant::TagableGenerator.new(
        ["#{@module_name}::#{@tagable_name}", "cost:decimal:precision=5.5:scale=-1", "power:float:scale=1e3:precision=high"],
        {},
        destination_root: destination_root)
      assert_raises(Thor::Error) do
        generator.invoke_all
      end
    end

    test "validates units, si options with invalid types" do
      generator = ProjectAssistant::TagableGenerator.new(
        ["#{@module_name}::#{@tagable_name}", "name:string:units=m:si", "description:text:units=J:si", "select1:enum:units=s:si", "count:integer:units=kJ/m2:si"],
        {},
        destination_root: destination_root)
      assert_raises(Thor::Error) do
        generator.invoke_all
      end
    end

    test "validates si option requires valid boolean value" do
      generator = ProjectAssistant::TagableGenerator.new(
        ["#{@module_name}::#{@tagable_name}", "power:float:units=m:si=yes"],
        {},
        destination_root: destination_root)
      assert_raises(Thor::Error) do
        generator.invoke_all
      end
    end

    test "validates step with non_numeric types" do
      generator = ProjectAssistant::TagableGenerator.new(
        ["#{@module_name}::#{@tagable_name}", "name:string:step=1", "description:text:step=.1", "select1:enum:step=100", "flex:jsonb:step", "parent:references:step=1", "created:date:step=1"],
        {},
        destination_root: destination_root)
      assert_raises(Thor::Error) do
        generator.invoke_all
      end
    end

    test "validates step value is decimal" do
      generator = ProjectAssistant::TagableGenerator.new(
        ["#{@module_name}::#{@tagable_name}", "power:float:units=m:si=true:step=string"],
        {},
        destination_root: destination_root)
      assert_raises(Thor::Error) do
        generator.invoke_all
      end
    end

    test "validates option key is valid" do
      generator = ProjectAssistant::TagableGenerator.new(
        ["#{@module_name}::#{@tagable_name}", "power:float:units=m:si=true:invalid=string"],
        {},
        destination_root: destination_root)
      assert_raises(Thor::Error) do
        generator.invoke_all
      end
    end

    test "creates model" do
      run_generator @args
      assert_file File.join(destination_root, 'app', 'models', 
        "#{@module_name.underscore}", "#{@tagable_name.underscore}.rb") do |content|
        assert_match(/module #{@module_name}/, content)
        assert_match(/class #{@tagable_name} < Base/, content)
        
        # Check for belongs_to associations
        @association_fields.each do |field|
          assert_match(/belongs_to :#{field[:name]}/, content)
        end
        
        # Check for presence validation on required fields
        @required_fields.each do |f|
          assert_match(/validates :#{f[:name]}, presence: true/, content)
        end
        
        # Check for enum declarations
        @enum_fields.each do |f|
          assert_match(/enum :#{f[:name]}, Constants\.#{@module_name.underscore}\.#{@tagable_name.underscore}\.#{f[:name]}\.to_h/, content)
        end
        
        # Check ransackable_attributes
        assert_match(/def self\.ransackable_attributes/, content)
        @searchable_fields.each do |field|
          field_name = field[:name]
          assert_match(/:\s*#{field_name}(?=[,\s\]])/, content, "Expected #{field_name} to be in ransackable_attributes")
        end
        
        %w[created_at updated_at].each do |timestamp|
          assert_match(/:\s*#{timestamp}(?=[,\s\]])/, content, "Expected #{timestamp} to be in ransackable_attributes")
        end
        
        # Check ransackable_associations
        associations = [:tag, :tag_discipline, :tag_discipline_project]
        @association_fields.each do |field|
          associations += [field[:name]]
        end
        assert_match(/def self\.ransackable_associations\(auth_object = nil\)\s+#{associations}/m, content)
      end
    end

    test "creates factory" do
      run_generator(@args)
      factory_file = File.join(destination_root, 'test', 'factories', @folder_name, 
        "#{@plural_name}.rb")
      assert_file factory_file do |content|
        assert_match(/factory\s+:#{@file_name}/, content)
        assert_match(/class:\s+#{@class_name}/, content)
        @association_fields.each do |field|
          assert_match(/association\s+:\s*#{field[:name]}/, content)
        end
        @attribute_fields.each do |field| 
          assert_match(/#{field[:name]}/, content)
          if field[:options][:valid].present?
            assert_includes content, field[:options][:valid]
          end
        end
      end
    end

    test "creates model test" do
      run_generator @args
      assert_file File.join(destination_root, 'test', 'models', 
        "#{@module_name.underscore}", "#{@tagable_name.underscore}_test.rb") do |content|
        assert_match(/module #{@module_name}/, content)
        assert_match(/class #{@tagable_name}Test < ActiveSupport::TestCase/, content)
        assert_match(/include TagableModelTests/, content)
        assert_match(/setup_common_test_data/, content)
        if @required_fields.any? 
          assert_match(/test_required_fields/, content)
          @required_fields.each do |field|
            assert_match(/:#{field[:name]}/, content)
          end
        end
        if @unique_fields.any? 
          assert_match(/test_unique_fields/, content)
          @unique_fields.each do |field|
            assert_match(/:#{field[:name]}/, content)
          end
        end
        @enum_fields.each do |field|
          assert_match(/test_enum_field/, content)
          field[:options][:keys].each do |key|
            assert_match(/#{key}/, content)
          end
        end
      end
    end

    test "creates migration" do
      run_generator(@args)

      migration_dir = File.join(destination_root, "db/migrate")
      
      # Find the migration file
      migration_file = Dir.glob(File.join(migration_dir, "*_create_#{@file_name}.rb")).first
      migration_name = "Create#{@module_name}#{@tagable_name}"
      assert_file migration_file do |migration|
        # Check fields are created, with null: false for required fields.
        assert_match(/class\s+#{migration_name}/, migration)
        assert_match(/create_table\s+:#{@table_name}/, migration)
        @fields.each do |field|
          case field[:type]
          # Check for translation of custom types
          when :enum, :enum_translated
            if field[:options].include?(:required)
              assert_match(/t\.integer\s+:#{field[:name]}.*null: false/m, migration)
            else
              assert_match(/t\.integer\s+:#{field[:name]}/m, migration)
            end
          # Otherwise just check for rails type
          else
            if field[:options].include?(:required) 
              assert_match(/t\.#{field[:type]}\s+:#{field[:name]}.*null: false/m, migration)
            else
              assert_match(/t\.#{field[:type]}\s+:#{field[:name]}/m, migration)
            end
          end
          if field[:options].include?(:scale) 
            assert_match(/scale:\s+#{field[:options][:scale]}/m, migration)
          end
          if field[:options].include?(:precision) 
            assert_match(/precision:\s+#{field[:options][:precision]}/m, migration)
          end
        end
        @fields.select { |field| field[:options].include?('index') }.each do |field|
          assert_match(/add_index\s+:#{@table_name},\s+:#{field[:name]}/m, migration)
        end
        @fields.select { |field| field[:options].include?('uniq') }.each do |field|
          assert_match(/add_index\s+:#{@table_name},\s+:#{field[:name]},\s+unique: true/m, migration)
        end
      end
    end

    test "creates policy" do
      run_generator(@args)
      policy_file = File.join(destination_root, 'app', 'policies', @folder_name, 
        "#{@singular_name}_policy.rb")
      assert_file policy_file do |content|
        assert_match(/module\s+#{@module_name}/, content)
        assert_match(/class\s+#{@tagable_name}Policy\s+<\s+ResourcePolicy/m, content)
      end
    end

    test "creates policy test" do
      run_generator(@args)
      policy_test_file = File.join(destination_root, 'test', 'policies', @folder_name, 
        "#{@singular_name}_policy_test.rb")
      assert_file policy_test_file do |content|
        assert_match(/module\s+#{@module_name}/, content)
        assert_match(/class\s+#{@tagable_name}PolicyTest\s+<\s+ActiveSupport::TestCase/m, content)
      end
    end

    test "creates controller" do
      run_generator(@args)
      controller_file = File.join(destination_root, 'app', 'controllers', @folder_name, 
        "#{@plural_name}_controller.rb")
      assert_file controller_file do |content|
        assert_match(/module\s+#{@module_name}/, content)
        assert_match(/class\s+#{@tagable_name.pluralize}Controller\s+<\s+ApplicationController/m, content)
        assert_match(/include TagablesController/m, content)
        @fields.each do |field|
          assert_match(/permit\(.*[:\s]#{field[:name]}[,\s\]]/m, content)
        end
      end
    end

    test "creates views" do
      run_generator(@args)
      views_dir = File.join(destination_root, 'app', 'views', @folder_name, @plural_name)

      # index.html.erb
      assert_file File.join(views_dir, 'index.html.erb') do |content|
        assert_includes content, "nav_button(action: :show_discipline, record: @discipline)"
        assert_match(/if policy\(#{@class_name}\).new?/, content)
        assert_includes content, "nav_button(action: :new, path: new_discipline_#{@file_name}_path(@discipline), record: #{@class_name}.new)"
        @searchable_fields.each do |field|
          assert_match(/f\.search_field :#{field[:name]}_cont/, content)
        end
        assert_match(/render 'header'/, content)
        assert_match(/render 'row'/, content)
      end

      # _header.html.erb
      assert_file File.join(views_dir, "_header.html.erb") do |content|
        @index_fields.each do |field|
          assert_includes content, "sort_link(@q, :#{field[:name]}"
        end
      end
      
      # _row.html.erb
      assert_file File.join(views_dir, "_row.html.erb") do |content|
        @index_fields.each do |field|
          case field[:type]
          when :string, :enum, :integer, :bigint
            assert_includes content, "index_attribute(row, :#{field[:name]}"
          when :float, :decimal
            assert_includes content, "index_attribute(row, :#{field[:name]}, type: #{field[:type]}"
          when :enum_translated
            assert_includes content, "index_attribute(row, :#{field[:name]}, type: :enum_translated)"
          when :references, :belongs_to
            assert_includes content, "index_attribute(row, :#{field[:name]}, type: :association)"
          end
        end
      end
      
      # show.html.erb
      assert_file File.join(views_dir, "show.html.erb") do |content|
        assert_match(/<% provide\(:title, t\('.title'\)\) %>/, content)
        assert_match(/policy\(@#{@singular_name}\).index?/, content)
        assert_includes content, "nav_button(action: :index, path: discipline_#{@table_name}_path(@discipline), record: @#{@singular_name})"
        assert_includes content, "nav_button(action: :previous, record: @neighbours[0])"
        assert_includes content, "nav_button(action: :next, record: @neighbours[1])"
        assert_match(/<%= t\('\.header',\s*label:.*\)\s*%>/, content)
        assert_includes content, "nav_button(action: :edit, path: edit_#{@file_name}_path(@#{@singular_name}), record: @#{@singular_name})"
        assert_includes content, "nav_button(action: :delete, record: @#{@singular_name})"
        assert_includes content, "nav_button(action: :new, path: new_discipline_#{@file_name}_path(@discipline), record: @#{@singular_name})"
        assert_includes content, "t('show.details', model: @#{@singular_name}.model_name.human)"
        @attribute_fields.each do |field|
          case field[:type]
          # Breaking these lines causes errors...
          when :string, :integer, :bigint
            assert_includes content, "show_attribute(@#{@singular_name}, :#{field[:name]}"
          when :enum
            assert_includes content, "show_attribute(@#{@singular_name}, :#{field[:name]}, type: :#{field[:type]}"
          when :float, :decimal
            assert_includes content, "show_attribute(@#{@singular_name}, :#{field[:name]}, type: :#{field[:type]}"
          when :enum_translated
            assert_includes content, "show_attribute(@#{@singular_name}, :#{field[:name]}, type: :enum_translated)"
          when :text, :jsonb 
            assert_includes content, "show_attribute(@#{@singular_name}, :#{field[:name]}, type: :#{field[:type]}"
          when :date
            assert_includes content, "show_attribute(@#{@singular_name}, :#{field[:name]}, type: :date"
          when :datetime, :timestamp, :time
            assert_includes content, "show_attribute(@#{@singular_name}, :#{field[:name]}, type: :datetime"
          when :boolean
            assert_includes content, "show_attribute(@#{@singular_name}, :#{field[:name]}, type: :boolean"
          when :binary
            assert_match(/'PLACEHOLDER FOR BINARY FIELD'/, content)
          when :references, :belongs_to
            assert_match(/render #{Regexp.escape("#{File.join(@folder_name, field[:name].pluralize, "card")}")}, object: @#{@singular_name}.#{field[:name]} %>/, content)
          else
            assert_match(/#{Regexp.escape("@#{@singular_name}.#{field[:name]} || '-'")}/, content)
          end
        end
        assert_includes content, "show_association(@#{@singular_name}, :tag)"
        @association_fields.each do |field|
          assert_includes content, "show_association(@#{@singular_name}, :#{field[:name]})"
        end
      end
      
      # edit.html.erb
      assert_file File.join(views_dir, "edit.html.erb") do |content|
        assert_match(/<% provide\(:title, t\('.title'\)\) %>/, content)
        assert_match(/render \"form\",\s*#{@singular_name}: @#{@singular_name},\s*tag: @tag/m, content)
      end
      
      # new.html.erb
      assert_file File.join(views_dir, "new.html.erb") do |content|
        assert_match(/<% provide\(:title, t\('.title'\)\) %>/, content)
        assert_match(/render \"form\",\s*#{@singular_name}: @#{@singular_name},\s*tag: @tag/m, content)
      end
      
      # _form.html.erb
      assert_file File.join(views_dir, "_form.html.erb") do |content|
        assert_match(/yield\(:header\)/m, content)
        assert_match(/bootstrap_form_with\(model:\s+#{@singular_name}/, content)
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
          when "references"
            assert_match(/f\.select\s+:#{field[:name]}/, content)
          end
        end
      end
      
      # _card.html.erb
      assert_file File.join(views_dir, "_card.html.erb") do |content|
        assert_includes content, "#{@singular_name} = object"
        assert_includes content, "context ||= #{@singular_name}.model_name.human"
        assert_includes content, "render 'components/collapsible', id: \"\#{id}_\#{#{@singular_name}.id}_details\""
        assert_includes content, "nav_link(action: :show, record: #{@singular_name})"
        @fields.each do |field|
          case field[:type]
          # Breaking these lines causes errors...
          when :string, :integer, :enum, :bigint
            assert_includes content, "show_attribute(#{@singular_name}, :#{field[:name]}"
          when :float, :decimal
            assert_includes content, "show_attribute(#{@singular_name}, :#{field[:name]}, type: :#{field[:type]}"
          when :enum_translated
            assert_includes content, "show_attribute(#{@singular_name}, :#{field[:name]}, type: :enum_translated)"
          when :text, :jsonb 
            assert_includes content, "show_attribute(#{@singular_name}, :#{field[:name]}, type: :#{field[:type]}"
          when :date
            assert_includes content, "show_attribute(#{@singular_name}, :#{field[:name]}, type: :date"
          when :datetime, :timestamp, :time
            assert_includes content, "show_attribute(#{@singular_name}, :#{field[:name]}, type: :datetime"
          when :boolean
            assert_includes content, "show_attribute(#{@singular_name}, :#{field[:name]}, type: :boolean"
          when :references, :belongs_to
            assert_includes content, "show_attribute(#{@singular_name}, :#{field[:name]}, type: :association"
          else
            assert_includes content, "show_attribute(#{@singular_name}, :#{field[:name]}"
          end
        end
      end
      
      # Skip cleanup for this test to examine generated files
      @skip_cleanup = true
    end

    test "creates controller test" do
      run_generator(@args)
      controller_test_file = File.join(destination_root, 'test', 'controllers', @folder_name, 
        "#{@plural_name}_controller_test.rb")
      assert_file controller_test_file do |content|
        assert_match(/module\s+#{@module_name}/, content)
        assert_match(/class\s+#{@tagable_name.pluralize}ControllerTest\s*<\s*ActionController::TestCase/, content)
        assert_match(/include TagableControllerTests/, content)
        assert_match(/include Devise::Test::ControllerHelpers/, content)
        @fields.select { |field| field[:options].include?('required') }.each do |field|
          assert_match(/#{field[:name]}:/, content)
        end
      end
    end

    test "creates system test" do
      run_generator(@args)
      system_test_file = File.join(destination_root, 'test', 'system', @folder_name, 
        "#{@plural_name}_system_test.rb")
      assert_file system_test_file do |content|
        assert_match(/module\s+#{@module_name}/, content)
        assert_match(/class\s+#{@tagable_name.pluralize}SystemTest\s*<\s*ApplicationSystemTestCase/, content)
        assert_match(/include TagableSystemTests/, content)
        assert_match(/include Devise::Test::IntegrationHelpers/, content)
        assert_match(/include Warden::Test::Helpers/, content)

        assert_includes content, "def setup_model_specific_data"
        assert_includes content, "def setup_model_specific_data"
        assert_match(/@index_fields = %i\[.*\]/, content)
        assert_match(/@search_fields = %i\[.*\]/, content)
        assert_match(/@show_fields = %i\[.*\]/, content)
        assert_match(/@show_associations = %i\[.*\]/, content)
        assert_match(/@new_fields = \{.*\}/, content)
        assert_match(/@edit_fields =/, content)
      end
    end

    test "adds new class to tagable constants" do
      run_generator(@args)
      tagable_file = File.join(destination_root, 'config', 'constants', "tagable.yml") 
      assert_file tagable_file do |content|
        assert_match(/# #{@module_name}\n\s*-\s+#{@class_name}\n/, content)
      end
    end

    test "adds enum constants" do
      run_generator(@args)
      constants_file = File.join(destination_root, 'config', 'constants', "#{@module_name.underscore}.yml") 
      assert_file constants_file do |content|
        # Check that enum fields are added with namespaced structure
        if @enum_fields.any?
          assert_match(/#{@singular_name}:\s*\n/, content)
          @enum_fields.each do |field|
            assert_match(/#{field[:name]}:\s*\n/m, content)
            field[:options][:keys].each_with_index do |key, index|
              assert_match(/#{key}:\s*#{index}\s*\n/m, content)
            end
          end
        end
      end
    end

    test "updates routes file" do
      routes_file = File.join(destination_root, "config", "routes.rb")
      
      # Run the generator
      run_generator @args
      
      # Check that the routes file was updated
      assert_file routes_file do |content|        
        # Check that the new resource lines were added to routes file
        assert_match(/resources\s+:#{@plural_name}, only: \[:index, :new, :create\]/, content)
        assert_match(/resources\s+:#{@plural_name}, except: \[:index\]/, content)
      end
    end

    test "creates model translations" do
      run_generator @args
      I18n.available_locales.each do |language|
      
        # Check models file
        # $stderr.puts "DEBUG: language: #{language.inspect}"
        models_file = File.join(destination_root, "config", "locales", @folder_name, 
          language.to_s, "#{language.to_s}.#{@folder_name}.models.yml")
        assert File.exist?(models_file)
        yaml = YAML.safe_load(File.read(models_file))
        models = yaml.dig(language.to_s, "activerecord", "models")
        assert models.key?(@i18n_key)
        assert models[@i18n_key].key?("one")
        assert models[@i18n_key].key?("other")
        all_attributes = yaml.dig(language.to_s, "activerecord", "attributes")
        assert all_attributes.key?(@i18n_key)
        attributes = yaml.dig(language.to_s, "activerecord", "attributes", @i18n_key)
        @fields.each do |field|
          assert attributes.key?(field[:name])
          if field[:type] == :enum_translated
            assert attributes.key?(field[:name].pluralize)
            enum_keys = attributes[field[:name].pluralize]
            field[:options][:keys].each do |key|
              assert enum_keys.key?(key)
            end
          end
        end
      end
    end

    test "handles missing models file gracefully" do
      # Set up locale files for this test
      create_test_locale_files
      I18n.stubs(:available_locales).returns([:en, :km])
      
      # Remove the models file
      en_models_file = File.join(destination_root, "config", "locales", @folder_name, "en", "en.#{@module_name}.models.yml")
      File.delete(en_models_file) if File.exist?(en_models_file)
      
      # Should not raise an error
      assert_nothing_raised do
        run_generator @args
      end
    end

    test "creates views translations" do
      run_generator @args
      I18n.available_locales.each do |language|
      views_file = File.join(destination_root, "config", "locales", @folder_name, 
            language.to_s, "#{language.to_s}.#{@folder_name}.views.yml")
        assert File.exist?(views_file)
        yaml = YAML.safe_load(File.read(views_file))
        views = yaml.dig(language.to_s, @folder_name)
          # $stderr.puts "DEBUG: views: #{views.inspect} "
        assert views.key?(@plural_name)
        %w[index show edit new].each do |key|
          view_keys = yaml.dig(language.to_s, @folder_name, @plural_name)
          # $stderr.puts "DEBUG: view_keys: #{view_keys.inspect} key: #{key.inspect}"
          assert view_keys.key?(key)
          assert view_keys[key].key?("title")
          assert view_keys[key].key?("header")
        end
      end
    end

    test "handles missing views file gracefully" do
      # Set up locale files for this test
      create_test_locale_files
      I18n.stubs(:available_locales).returns([:en, :km])
      
      # Remove the views file
      en_views_file = File.join(destination_root, "config", "locales", @folder_name, "en", "en.#{@module_name}.views.yml")
      File.delete(en_views_file) if File.exist?(en_views_file)
      
      # Should not raise an error
      assert_nothing_raised do
        run_generator @args
      end
    end

    private

    def teardown
      # Skip cleanup if flag is set
      return if @skip_cleanup
      super
    end

    def create_test_locale_files
      # Create locale directories based on available locales
      locale_dirs = I18n.available_locales.map do |locale|
        File.join(destination_root, "config", "locales", @folder_name, locale.to_s)
      end
      
      locale_dirs.each do |dir|
        FileUtils.mkdir_p(dir)
      end
      
      # Create models files for each locale
      I18n.available_locales.each do |locale|
        models_file = File.join(destination_root, "config", "locales", @folder_name, locale.to_s, "#{locale}.#{@module_name}.models.yml")
        
        File.write(models_file, <<~YAML)
          #{locale}:
            activerecord:
              models:
                electrical/cable_type: "Cable Type"
                electrical/cable: "Cable"
              attributes:
                electrical/cable_type:
                  id: ID
                  conductor_material: "Conductor Material"
                electrical/cable:
                  from: "From"
                  to: "To"
        YAML
      end
      
      # Create views files for each locale
      I18n.available_locales.each do |locale|
        views_file = File.join(destination_root, "config", "locales", @folder_name, locale.to_s, "#{locale}.#{@module_name}.views.yml")
        
        File.write(views_file, <<~YAML)
          #{locale}:
            cables:
              index:
                title: "Cables"
                header: "Cables Schedule for %{project}"
              show:
                title: "Cable"
                header: "Cable: %{label}"
        YAML
      end
    end
  end
end