# test/generators/module_generator_test.rb
require 'test_helper'
require Rails.root.join('lib/generators/project_assistant/tagable_generator').to_s
require Rails.root.join('lib/generators/project_assistant/module_generator').to_s

module ProjectAssistant
  class TagableGeneratorTest < Rails::Generators::TestCase
    tests ProjectAssistant::TagableGenerator
    destination Rails.root.join('tmp/generators')
    setup :prepare_destination

    setup do
      @module_name = "Electrical"
      @tagable_name = "Motor"
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
       # First generate a module (silently)
       capture(:stdout) do
         ProjectAssistant::ModuleGenerator.start([@module_name], 
          destination_root: destination_root)
       end
       @args = ["#{@module_name}::#{@tagable_name}", 
       'name:string:required', 
       'description:text',
       'selector:enum',
       'sort_order:integer:index',
       'code:string:uniq'
      ]
      puts "\n=== Setup complete ==="
    end

    test "module generator setup complete" do
      assert_file "app/models/#{@module_name}/base.rb"
      assert_file "app/models/#{@module_name}.rb"
    end

    test "generator runs without errors" do
      puts "\n=== Starting generator test ==="
      assert_nothing_raised do
        puts "Running generator with #{@module_name}::#{@tagable_name}"
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
      assert_equal 5, fields.size
      
      # Check first field
      assert_equal 'name', fields[0][:name]
      assert_equal 'string', fields[0][:type].to_s
      assert_includes fields[0][:options], 'required'
      
      # Check second field
      assert_equal 'description', fields[1][:name]
      assert_equal 'text', fields[1][:type]
      refute_includes fields[1][:options], 'required'
    end

    test "creates model" do
      run_generator @args
      assert_file File.join(destination_root, 'app', 'models', 
        "#{@module_name}", "#{@tagable_name}.rb") do |content|
        assert_match(/module #{@module_name}/, content)
        assert_match(/class #{@tagable_name} < Base/, content)
        assert_match(/validates :name, presence: true/, content)
        assert_match(/enum selector: \['stub'\]/, content)
      
    # Check ransackable_attributes
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

    test "creates migration" do
      run_generator(@args)

      migration_dir = File.join(destination_root, "db/migrate")
      table_name = "#{@module_name.underscore}_#{@tagable_name.underscore.pluralize}"
      # Find the migration file
      migration_file = Dir.glob(File.join(migration_dir, "*_create_#{table_name.singularize}.rb")).first
      migration_name = "Create#{@module_name}#{@tagable_name}"
      assert_file migration_file do |migration|
        # Check fields are created, with null: false for required fields.
        assert_match(/class\s+#{migration_name}/, migration)
        assert_match(/create_table\s+:#{table_name}/, migration)
        assert_match(/t\.string\s+:name.*null: false/m, migration)
        assert_match(/t\.text\s+:description/m, migration)  
        assert_match(/t\.integer\s+:selector/m, migration)
        assert_match(/t\.integer\s+:sort_order/m, migration)
        assert_match(/t\.string\s+:code/m, migration)
        assert_match(/add_index\s+:#{table_name},\s+:sort_order/m, migration)
        assert_match(/add_index\s+:#{table_name},\s+:code,\s+unique: true/m, migration)
      end
    end
  end
end