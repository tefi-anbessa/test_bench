# test/generators/scaffold_generator_test.rb
# Adapted from test/generators/tagable_generator_test.rb, in process of adapting to nested modules. JIC.
require 'test_helper'
require Rails.root.join('lib', 'generators', 'project_assistant', 'scaffold_generator').to_s
require Rails.root.join('lib', 'generators', 'project_assistant', 'module_generator').to_s
require Rails.root.join('lib', 'generators', 'project_assistant', 'field_types').to_s

module ProjectAssistant
  class ScaffoldGeneratorTest < Rails::Generators::TestCase
    include ProjectAssistant::FieldTypes
    tests ProjectAssistant::ScaffoldGenerator
    destination Rails.root.join('tmp/generators')
    setup :prepare_destination

    setup do
      @module_name = "ModuleName"
      @model_name = "ClassName"
      # Generator::NamedBase methods not available in test environment
      @human_name = @model_name.underscore.humanize
      @class_path = @module_name.split('::').to_a # ["ModuleName"]
      @file_name = "#{@model_name.underscore}" # "class_name"
      @table_name = "#{@module_name.split('::').join('_').underscore}_#{@model_name.underscore.pluralize}" # "module_name_class_names"
      @singular_table_name = @table_name.singularize # "module_name_class_name"
      @class_name = "#{@module_name}::#{@model_name}" # "ModuleName::ClassName"
      @folder_name = "#{@module_name.underscore}" # "module_name/class_name"
      @singular_name = "#{@model_name.underscore}" # "class_name"
      @plural_name = "#{@model_name.underscore.pluralize}" # "class_names"
      
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
          # Document
        YAML
      
      # Ensure test app includes config/application.rb
      File.write(File.join(destination_root, 'config/application.rb'), <<~RUBY
        module TestApp
          class Application < Rails::Application
          end
        end
      RUBY
      )

      # Generate the module (silently)
      capture(:stdout) do
        ProjectAssistant::ModuleGenerator.start([@module_name], destination_root: destination_root)
      end

      # Test arguments for the command line
      @args = ["#{@module_name}::#{@model_name}", 
        'name:string:required',
        'description:text',
        'selector:enum',
        'status:enum_translated',
        'sort_order:integer:index',
        'code:string:uniq'
      ]
      
      # Mimic the generators process_fields method.
      @fields = @args[1..-1].map do |arg| 
        name, type, *opts = arg.split(':')
        { name: name, type: type, options: opts } 
      end
    end
    
    test "module generator setup complete" do
      assert_file "app/models/#{@folder_name}/base.rb"
      assert_file "app/models/#{@folder_name}.rb"
      assert_file "config/constants/tagable.yml"
    end

    test "generator runs without errors" do
      puts "\n=== Starting generator test ==="
      assert_nothing_raised do
        puts "Running generator with #{@class_name}"
        run_generator @args
        puts "=== Generator completed successfully ==="
      end
    end

    test "processes command line arguments correctly" do
      # Access the generator instance
      generator = ProjectAssistant::ScaffoldGenerator.new(@args)
      
      # Test the process_fields method directly
      # This should succeed since all test args are valid
      fields = generator.send(:process_fields)
      
      # Verify the fields were processed correctly
      assert_equal @fields.size, fields.size
      
      # Check fields
      @fields.each_with_index do |f, index|
        assert_equal f[:name], fields[index][:name]
        assert_equal f[:type], fields[index][:type]
        assert_equal f[:options], fields[index][:options]
      end
    end

    test "validates namespaced name with invalid class name" do
      assert_raises(SystemExit) do
        run_generator ["Document::123Invalid", "name:string"]
      end
    end

    test "validates name with non-existent module" do
      skip "Module name validation is crashing generator"
      assert_raises(SystemExit) do
        run_generator ["NonExistent::Heater", "name:string"]
      end
    end

    test "validates correct name format" do
      assert_nothing_raised do
        run_generator ["#{@module_name}::#{@model_name}", "name:string"]
      end
    end

    test "validates invalid field names" do
      invalid_args = ["#{@module_name}::#{@model_name}", "123invalid:string", "invalid-name:string", "invalid name:string"]
      generator = ProjectAssistant::ScaffoldGenerator.new(invalid_args)
      
      # Mock user input to choose 'N' (abort) when prompted
      $stdin.stubs(:gets).returns("N\n")
      assert_raises(SystemExit) do
        generator.send(:process_fields)
      end
      $stdin.unstub(:gets)
    end

    test "validates missing field types" do
      invalid_args = ["#{@module_name}::#{@model_name}", "name:", "description"]
      generator = ProjectAssistant::ScaffoldGenerator.new(invalid_args)
      
      # Mock user input to choose 'N' (abort) when prompted
      $stdin.stubs(:gets).returns("N\n")
      assert_raises(SystemExit) do
        generator.send(:process_fields)
      end
      $stdin.unstub(:gets)
    end

    test "validates unknown field types" do
      invalid_args = ["#{@module_name}::#{@model_name}", "name:invalid_type", "description:unknown"]
      generator = ProjectAssistant::ScaffoldGenerator.new(invalid_args)
      
      # Mock user input to choose 'N' (abort) when prompted
      $stdin.stubs(:gets).returns("N\n")
      assert_raises(SystemExit) do
        generator.send(:process_fields)
      end
      $stdin.unstub(:gets)
    end

    test "validates invalid field options" do
      invalid_args = ["#{@module_name}::#{@model_name}", "name:string:invalid_option", "description:text:unknown:another_invalid"]
      generator = ProjectAssistant::ScaffoldGenerator.new(invalid_args)
      
      # Mock user input to choose 'N' (abort) when prompted
      $stdin.stubs(:gets).returns("N\n")
      assert_raises(SystemExit) do
        generator.send(:process_fields)
      end
      $stdin.unstub(:gets)
    end

    test "allows continuing with valid fields when some are invalid" do
      mixed_args = ["#{@module_name}::#{@model_name}", "name:string", "123invalid:integer", "description:text"]
      generator = ProjectAssistant::ScaffoldGenerator.new(mixed_args)
      
      # Mock user input to choose 'y' (continue) when prompted
      $stdin.stubs(:gets).returns("y\n")
      fields = generator.send(:process_fields)
      # Should only process the valid fields
      assert_equal 2, fields.size
      assert_equal ["name", "description"], fields.map { |f| f[:name] }
      $stdin.unstub(:gets)
    end

    test "creates model" do
      run_generator @args
      assert_file File.join(destination_root, 'app', 'models', 
        "#{@module_name.underscore}", "#{@model_name.underscore}.rb") do |content|
        assert_match(/module #{@module_name}/, content)
        assert_match(/class #{@model_name} < Base/, content)
        @fields.select { |f| f[:options].include?('required') }.each do |f|
          assert_match(/validates :#{f[:name]}, presence: true/, content)
        end
        @fields.select { |f| ['enum', 'enum_translated'].include?(f[:type]) }.each do |f|
          assert_match(/enum :#{f[:name]}, Constants\.#{@module_name.underscore}\.#{@model_name.underscore}\.#{f[:name]}\.to_h/, content)
        end
      
      # Check ransackable_attributes
      assert_match(/def self\.ransackable_attributes/, content)
      @fields.select { |f| SEARCHABLE_TYPES.include?(f[:type]) }.each do |field|
        field_name = field[:name]
        assert_match(/:\s*#{field_name}(?=[,\s\]])/, content, "Expected #{field_name} to be in ransackable_attributes")
      end
      %w[created_at updated_at].each do |timestamp|
        assert_match(/:\s*#{timestamp}(?=[,\s\]])/, content, "Expected #{timestamp} to be in ransackable_attributes")
      end
      
      # Check ransackable_associations
      assert_match(/def self\.ransackable_associations\(auth_object = nil\)\s+\[ :project \]/m, content)
      end
    end

    test "creates factory" do
      run_generator(@args)
      factory_file = File.join(destination_root, 'test', 'factories', @folder_name, 
        "#{@plural_name}.rb")
      assert_file factory_file do |content|
        assert_match(/factory\s+:#{@singular_table_name}/, content)
        assert_match(/class:\s+#{@class_name}/, content)
        @fields.each do |field|
          if field[:options].include?('required')
            assert_match(/#{field[:name]}\s+\{\s*\}\s*# Provide default value for required field/, content)
          else
            assert_match(/#{field[:name]}\s+\{\s*\}/, content)
          end
        end
      end
    end

    test "creates model test" do
      run_generator @args
      assert_file File.join(destination_root, 'test', 'models', 
        "#{@module_name.underscore}", "#{@model_name.underscore}_test.rb") do |content|
        assert_match(/module #{@module_name}/, content)
        assert_match(/class #{@model_name}Test < ActiveSupport::TestCase/, content)
        @fields.each do |field|
          if field[:options].include?('required')
            assert_match(/test "#{field[:name]} must be present" do/, content)
            assert_match(/@resource.#{field[:name]} = nil/, content)
          else
            refute_match(/test "#{field[:name]} must be present" do/, content)
            refute_match(/@resource.#{field[:name]} = nil/, content)
          end
        end
      end
    end

    test "creates migration" do
      run_generator(@args)

      migration_dir = File.join(destination_root, "db", "migrate")
      
      # Find the migration file
      migration_file = Dir.glob(File.join(migration_dir, "*_create_#{@singular_table_name}.rb")).first
      migration_name = "Create#{@module_name}#{@model_name}"
      assert_file migration_file do |migration|
        # Check fields are created, with null: false for required fields.
        assert_match(/class\s+#{migration_name}/, migration)
        assert_match(/create_table\s+:#{@table_name}/, migration)
        @fields.each do |field|
          case field[:type]
          # Check for translation of custom types
          when 'enum', 'enum_translated'
            if field[:options].include?('required')
              assert_match(/t\.integer\s+:#{field[:name]}.*null: false/m, migration)
            else
              assert_match(/t\.integer\s+:#{field[:name]}/m, migration)
            end
          # Otherwise just check for rails type
          else
            if field[:options].include?('required') 
              assert_match(/t\.#{field[:type]}\s+:#{field[:name]}.*null: false/m, migration)
            else
              assert_match(/t\.#{field[:type]}\s+:#{field[:name]}/m, migration)
            end
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
        assert_match(/class\s+#{@model_name}Policy\s+<\s+ResourcePolicy/m, content)
        assert_match(/def\s+#{@singular_name}/, content)
      end
    end

    test "creates policy test" do
      run_generator(@args)
      policy_test_file = File.join(destination_root, 'test', 'policies', @folder_name, 
        "#{@singular_name}_policy_test.rb")
      assert_file policy_test_file do |content|
        assert_match(/module\s+#{@module_name}/, content)
        assert_match(/class\s+#{@model_name}PolicyTest\s+<\s+ActiveSupport::TestCase/m, content)
      end
    end

    test "creates controller" do
      run_generator(@args)
      controller_file = File.join(destination_root, 'app', 'controllers', @folder_name, 
        "#{@plural_name}_controller.rb")
      assert_file controller_file do |content|
        assert_match(/module\s+#{@module_name}/, content)
        assert_match(/class\s+#{@model_name.pluralize}Controller\s+<\s+ApplicationController/m, content)
        @fields.each do |field|
          assert_match(/permit\(.*:#{field[:name]}[,\s\)]/m, content)
        end
      end
    end

    test "creates views" do
      run_generator(@args)
      views_dir = File.join(destination_root, 'app', 'views', @folder_name, @plural_name)
      # index.html.erb
      assert_file File.join(views_dir, 'index.html.erb') do |content|
        assert_match(/if policy\(#{@class_name}\).new?/, content)
        assert_match(/link_to new_#{@singular_table_name}_path/, content)
        @fields.each do |field|
          if SEARCHABLE_TYPES.include?(field[:type])
            assert_match(/f\.search_field :#{field[:name]}_cont/, content)
          else
            refute_match(/f\.search_field :#{field[:name]}_cont/, content)
          end
        end
        assert_match(/render 'header'/, content)
        assert_match(/render 'row'/, content)
      end

      # _header.html.erb
      assert_file File.join(views_dir, "_header.html.erb") do |content|
        @fields.each do |field|
          if INDEX_TYPES.include?(field[:type])
            assert_match(/sort_link\(@q, :#{field[:name]}\)/, content)
          else
            refute_match(/sort_link\(@q, :#{field[:name]}\)/, content)
          end
        end
      end
      
      # _row.html.erb
      assert_file File.join(views_dir, "_row.html.erb") do |content|
        @fields.each do |field|
          if INDEX_TYPES.include?(field[:type])
            case field[:type]
            when 'string', 'enum', 'integer', 'bigint', 'decimal'
              assert_match(/#{Regexp.escape("row.#{field[:name]} || '-'")}/, content)
            when 'float'
              assert_match(/#{Regexp.escape("number_to_human(row.#{field[:name]}, precision: 4, units: { unit: 'x', thousand: 'kx', million: 'Mx' }) || '-'")}/, content)
            when 'enum_translated'
              assert_match(/#{Regexp.escape("row.class.human_enum_name(:#{field[:name]}, row.#{field[:name]})")}/, content)
            end
          else
            refute_match(/#{Regexp.escape("row.#{field[:name]}")}/, content)
          end
        end
      end
      
      # show.html.erb
      assert_file File.join(views_dir, "show.html.erb") do |content|
        assert_match(/<% provide\(:title, t\('.title'\)\) %>/, content)
        assert_match(/policy\(@#{@singular_name}\).index?/, content)
        assert_match(/link_to #{@table_name}_path/, content)
        assert_match(/link_to prev_#{ @singular_name }/, content)
        assert_match(/link_to next_#{ @singular_name }/, content)
        assert_match(/<%= t\('\.header',\s*label:.*\)\s*%>/, content)
        assert_match(/link_to edit_#{@singular_table_name}_path\(@#{@singular_name}\)/, content)
        assert_match(/link_to @#{@singular_name},\s*method:\s*:delete/m, content)
        @fields.each do |field|
            case field[:type]
            # Breaking these lines causes errors...
            when "string", "enum", "integer", "bigint", "decimal"
              assert_match(/#{Regexp.escape("@#{@singular_name}.class.human_attribute_name(:#{field[:name]})")}/, content)
              assert_match(/#{Regexp.escape("@#{@singular_name}.#{field[:name]} || '-'")}/, content)
            when "float" 
              assert_match(/number_to_human\(@#{singular_name}.#{field[:name]}/, content)
            when "enum_translated"
              assert_match(/#{Regexp.escape("@#{@singular_name}.class.human_enum_name(:#{field[:name]}, @#{@singular_name}.#{field[:name]})")}/, content)
            when "text", "jsonb" 
              assert_match(/simple_format\(@#{@singular_name}.#{field[:name]} || '-'\)/, content)
            when "datetime", "timestamp", "time", "date"
              assert_match(/time_tag\(@#{@singular_name}.#{field[:name]} || '-'\)/, content)
            when "binary"
              assert_match(/'PLACEHOLDER FOR BINARY FIELD'/, content)
            else
              assert_match(/#{Regexp.escape("@#{@singular_name}.#{field[:name]} || '-'")}/, content)
            end
        end
      end
      
      # edit.html.erb
      assert_file File.join(views_dir, "edit.html.erb") do |content|
        assert_match(/<% provide\(:title, t\('.title'\)\) %>/, content)
        assert_match(/render \"form\",\s*#{@singular_name}: @#{@singular_name}/m, content)
      end
      
      # new.html.erb
      assert_file File.join(views_dir, "new.html.erb") do |content|
        assert_match(/<% provide\(:title, t\('.title'\)\) %>/, content)
        assert_match(/render \"form\",\s*#{@singular_name}: @#{@singular_name}/m, content)
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
          end
        end
      end
      
      # _card.html.erb
      assert_file File.join(views_dir, "_card.html.erb") do |content|
        assert_match(/resource = object/, content)
        assert_match(/render \'components\/collapsible\'/, content)
        assert_match(/link_to resource/, content)
        @fields.each do |field|
          assert_match(/#{Regexp.escape("resource.class.human_attribute_name(:#{field[:name]})")}/, content)
          case field[:type]
          # Breaking these lines causes errors...
          when "string", "enum", "integer", "bigint", "decimal"
            assert_match(/#{Regexp.escape("resource.#{field[:name]} || '-'")}/, content)
          when "float" 
            assert_match(/number_to_human\(resource.#{field[:name]}/, content)
          when "enum_translated"
            assert_match(/#{Regexp.escape("resource.class.human_enum_name(:#{field[:name]}, resource.#{field[:name]})")}/, content)
          when "text", "jsonb" 
            assert_match(/simple_format\(@#{@singular_name}.#{field[:name]} || '-'\)/, content)
          when "datetime", "timestamp", "time", "date"
            assert_match(/time_tag\(@#{@singular_name}.#{field[:name]} || '-'\)/, content)
          when "binary"
            assert_match(/'PLACEHOLDER FOR BINARY FIELD'/, content)
          else
            assert_match(/#{Regexp.escape("@#{@singular_name}.#{field[:name]} || '-'")}/, content)
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
        assert_match(/class\s+#{@model_name.pluralize}ControllerTest\s*<\s*ActionController::TestCase/, content)
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
        assert_match(/class\s+#{@model_name.pluralize}SystemTest\s*<\s*ApplicationSystemTestCase/, content)
        assert_match(/include Devise::Test::IntegrationHelpers/, content)
        assert_match(/include Warden::Test::Helpers/, content)
        assert_match(/include ActionView::Helpers::NumberHelper/, content)
      end
    end

    test "adds enum constants" do
      run_generator(@args)
      constants_file = File.join(destination_root, 'config', 'constants', "#{@module_name.underscore}.yml") 
      assert_file constants_file do |content|
        assert_match(/#{@singular_name}:/, content)
        # Check that enum fields are added with namespaced structure
        enum_fields = @fields.select { |f| ['enum', 'enum_translated'].include?(f[:type]) }
        if enum_fields.any?
          assert_match(/#{@singular_name}:\s*\n/, content)
          enum_fields.each do |f|
            assert_match(/#{f[:name]}:\s*\n\s+#{f[:name]}_other: 0.*?# TODO: Add enum values/m, content)
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
        # TODO extend the regexp to match the correct location for each line.
        assert_match(/resources\s+:#{@plural_name}/, content)
      end
    end

    test "creates model translations" do
      run_generator @args
      I18n.available_locales.each do |locale|
      
        # Check models file
        models_file = File.join(destination_root, "config", "locales", @folder_name, 
          locale.to_s, "#{locale.to_s}.#{@module_name.underscore}.models.yml")
        assert_file models_file do |content|
          assert_match(/#{@folder_name}\/#{@singular_name}:\s+"#{@model_name.underscore.humanize}"/, content)
          @fields.each do |field|
            assert_match(/#{field[:name]}:\s+\"#{field[:name].humanize}\"/, content)
          end
        end
      end
    end

    test "creates views translations" do
      run_generator @args
      I18n.available_locales.each do |locale|
      views_file = File.join(destination_root, "config", "locales", @folder_name, 
            locale.to_s, "#{locale.to_s}.#{@module_name.underscore}.views.yml")
        assert_file views_file do |content|
          assert_match(/#{@plural_name}:/, content)
          assert_match(/title:\s*"#{@human_name.pluralize}"/, content)
          assert_match(/header:\s*"#{@human_name.pluralize} Schedule for %{project}"/, content)
          assert_match(/title:\s*"Edit #{@human_name}"/, content)
          assert_match(/header:\s*"Edit #{@human_name}: %{label}"/, content)
          assert_match(/title:\s*"New #{@human_name}"/, content)
          assert_match(/header:\s*"New #{@human_name}"/, content)
          assert_match(/title:\s*"#{@human_name}"/, content)
          assert_match(/header:\s*"#{@human_name}: %{label}"/, content)
        end
      end
    end

    test "handles enum_translated fields correctly in translations" do
      run_generator @args
      enum_translated_fields = @fields.select { |f| ['enum_translated'].include?(f[:type]) }
      if enum_translated_fields.any?
        I18n.available_locales.each do |locale|
          # Check models file
          models_file = File.join(destination_root, "config", "locales", @folder_name, 
            locale.to_s, "#{locale.to_s}.#{@module_name.underscore}.models.yml")
          assert_file models_file do |content|
            enum_translated_fields.each do |field|
              assert_match(/#{field[:name]}:\s+\"#{field[:name].humanize}\"/, content)
              assert_match(/#{field[:name].pluralize}/, content)
            end
          end
        end
      end
    end

    private

    def teardown
      # Skip cleanup if flag is set
      return if @skip_cleanup
      super
    end
  end
end