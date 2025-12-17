# test/generators/module_generator_test.rb
require 'test_helper'
require Rails.root.join('lib', 'generators', 'project_assistant', 'tagable_generator').to_s
require Rails.root.join('lib', 'generators', 'project_assistant', 'module_generator').to_s
require Rails.root.join('lib', 'generators', 'project_assistant', 'field_types').to_s

module ProjectAssistant
  class TagableGeneratorTest < Rails::Generators::TestCase
    include ProjectAssistant::FieldTypes
    tests ProjectAssistant::TagableGenerator
    destination Rails.root.join('tmp/generators')
    setup :prepare_destination

    setup do
      @module_name = "Electrical"
      @tagable_name = "Motor"
      # Generator::NamedBase methods not available in test environment
      @file_name = "#{@module_name.underscore}_#{@tagable_name.underscore}" # electrical_motor
      @table_name = "#{@module_name.underscore}_#{@tagable_name.underscore.pluralize}" # electrical_motors
      @class_name = "#{@module_name}::#{@tagable_name}" # Electrical::Motor
      @folder_name = "#{@module_name.underscore}" # electrical
      @singular_name = "#{@tagable_name.underscore}" # motor
      @plural_name = "#{@tagable_name.underscore.pluralize}" # motors
      # Set up a dummy Rails app
#      app_root = File.join(destination_root, "dummy")
#      FileUtils.mkdir_p(app_root)

#      Dir.chdir(app_root) do
#        # Initialize a minimal Rails app
#        'rails new . --skip-bundle --skip-test --skip-system-test --skip-webpack-install --skip-jbuilder --skip-bootsnap'
#      end
#      
      # Ensure test app includes config/application.rb
      FileUtils.mkdir_p(File.join(destination_root, 'config'))
      File.write(File.join(destination_root, 'config/application.rb'), <<~RUBY
        module TestApp
          class Application < Rails::Application
          end
        end
      RUBY
      )

      # Ensure test setup includes config/constants/tagable.yml
      FileUtils.mkdir_p(File.join(destination_root, 'config/constants'))
      tagable_file = File.join(destination_root, 'config/constants/tagable.yml')
      File.write(tagable_file, "tagable:\n") unless File.exist?(tagable_file)

      # Generate a module (silently)
      capture(:stdout) do
        ProjectAssistant::ModuleGenerator.start([@module_name], 
        destination_root: destination_root)
      end

      # Dummy arguments for the command line
      @args = ["#{@module_name}::#{@tagable_name}", 
        'name:string:required',
        'description:text',
        'selector:enum',
        'status:enum_translated',
        'sort_order:integer:index',
        'code:string:uniq'
      ]
      # Mimic the generators process_fields method to improve test robustness.
      @fields = @args[1..-1].map do |arg| 
        name, type, *opts = arg.split(':')
        { name: name, type: type, options: opts } 
      end
      puts "\n=== Setup complete ==="
    end

    test "module generator setup complete" do
      assert_file "app/models/#{@module_name}/base.rb"
      assert_file "app/models/#{@module_name}.rb"
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
      generator = ProjectAssistant::TagableGenerator.new(@args)
      
      # Test the process_fields method directly
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

    test "creates model" do
      run_generator @args
      assert_file File.join(destination_root, 'app', 'models', 
        "#{@module_name.underscore}", "#{@tagable_name.underscore}.rb") do |content|
        assert_match(/module #{@module_name}/, content)
        assert_match(/class #{@tagable_name} < Base/, content)
        @fields.select { |f| f[:options].include?('required') }.each do |f|
          assert_match(/validates :#{f[:name]}, presence: true/, content)
        end
        @fields.select { |f| ['enum', 'enum_translated'].include?(f[:type]) }.each do |f|
          assert_match(/enum #{f[:name]}: \['stub'\]/, content)
        end
      
      # Check ransackable_attributes (legacy using args instead of fields...)
      assert_match(/def self\.ransackable_attributes/, content)
      @args[1..-1].each do |field_arg|
        field_name = field_arg.split(':').first
        assert_match(/:\s*#{field_name}(?=[,\s\]])/, content, "Expected #{field_name} to be in ransackable_attributes")
      end
      %w[created_at updated_at].each do |timestamp|
        assert_match(/:\s*#{timestamp}(?=[,\s\]])/, content, "Expected #{timestamp} to be in ransackable_attributes")
      end
      
      # Check ransackable_associations
      assert_match(/def self\.ransackable_associations\(auth_object = nil\)\s+\[ :tag \]/m, content)
      end
    end

    test "creates factory" do
      run_generator(@args)
      factory_file = File.join(destination_root, 'test', 'factories', @folder_name, 
        "#{@plural_name}.rb")
      assert_file factory_file do |content|
        assert_match(/factory\s+:#{@file_name}/, content)
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
        "#{@module_name.underscore}", "#{@tagable_name.underscore}_test.rb") do |content|
        assert_match(/module #{@module_name}/, content)
        assert_match(/class #{@tagable_name}Test < ActiveSupport::TestCase/, content)
        assert_match(/include TagableModelPatterns/, content)
        assert_match(/@resource = create\(#{@file_name}, tag: @tag\)/, content)
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
        assert_match(/class\s+#{@tagable_name}Policy\s+<\s+ResourcePolicy/m, content)
        assert_match(/def\s+#{@singular_name}/, content)
        assert_match(/^\s*def\s+tag\s*\n\s+#{@singular_name}\.tag\s*\n/m, content)
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
        assert_match(/if policy\(#{@class_name}\).new?/, content)
        assert_match(/link_to new_#{@file_name}_path/, content)
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
        assert_match(/link_to edit_#{@file_name}_path\(@#{@singular_name}\)/, content)
        assert_match(/link_to @#{@singular_name},\s*method:\s*:delete/m, content)
        assert_match(/render 'tags\/card'/, content)
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
    end

    test "creates controller test" do
      run_generator(@args)
      controller_test_file = File.join(destination_root, 'test', 'controllers', @folder_name, 
        "#{@plural_name}_controller_test.rb")
      assert_file controller_test_file do |content|
        assert_match(/module\s+#{@module_name}/, content)
        assert_match(/class\s+#{@tagable_name.pluralize}ControllerTest\s*<\s*ActionController::TestCase/, content)
        assert_match(/include TagableTestPatterns/, content)
        assert_match(/include Devise::Test::ControllerHelpers/, content)
        @fields.select { |field| field[:options].include?(:required) }.each do |field|
          assert_match(/#{field[:name]}:/, content)
        end
      end
    end

    test "edits constants" do
      run_generator(@args)
      tagable_file = File.join(destination_root, 'config/constants/tagable.yml') 
      assert_file tagable_file do |content|
        assert_match(/# #{@module_name}\n\s*-\s+#{@class_name}\n/, content)
      end
    end

    test "creates system test" do
      run_generator(@args)
      system_test_file = File.join(destination_root, 'test', 'system', @folder_name, 
        "#{@plural_name}_system_test.rb")
      assert_file system_test_file do |content|
        assert_match(/module\s+#{@module_name}/, content)
        assert_match(/class\s+#{@tagable_name.pluralize}SystemTest\s*<\s*ApplicationSystemTestCase/, content)
        assert_match(/include TagableSystemTestPatterns/, content)
        assert_match(/include Devise::Test::IntegrationHelpers/, content)
        assert_match(/include Warden::Test::Helpers/, content)
        assert_match(/include ActionView::Helpers::NumberHelper/, content)
      end
    end
  end
end