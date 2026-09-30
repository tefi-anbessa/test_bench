# test/generators/module_generator_test.rb
require 'test_helper'
require Rails.root.join('lib/generators/project_assistant/module_generator').to_s

module ProjectAssistant
  class ModuleGeneratorTest < Rails::Generators::TestCase
    tests ProjectAssistant::ModuleGenerator
    destination Rails.root.join('tmp/generators')
    setup :prepare_destination

    setup do
      @module_class = "ExistingModule"
      @module_name = @module_class.underscore

      # Setup for nested module tests. Duplicate named_base methods as required.
      @nested_module_class = "ExistingModule::ExistingSubModule::NewSubModule"
      @nested_module_array = @nested_module_class.split("::") # ["ExistingModule", "ExistingSubModule", "NewSubModule"]
      @nested_module_dir = File.join(*@nested_module_array.map(&:underscore)) # "existing_module/existing_sub_module/new_sub_module"
      @existing_module_dir = File.join(*@nested_module_array[0..-2].map(&:underscore)) # "existing_module/existing_sub_module"
      @nested_module_name = @nested_module_array.last.underscore # "new_sub_module"
      @app_dirs = %w[controllers helpers models policies views]
      @test_dirs = %w[controllers factories models policies system]
      @locale_dirs = %w[models views]
      
      # Create necessary config files
      FileUtils.mkdir_p(File.join(destination_root, 'config'))
      File.write(File.join(destination_root, 'config', 'application.rb'), <<~RUBY)
        module TestApp
          class Application < Rails::Application
          end
        end
      RUBY

      # Create a clean routes.rb file for testing
      File.write(File.join(destination_root, 'config', 'routes.rb'), <<~RUBY)
        Rails.application.routes.draw do
          # INSERTION POINT 1 FOR MODULE GENERATOR
          
          resources :tags, shallow: true do
            # INSERTION POINT 2 FOR MODULE GENERATOR
          end
        end
      RUBY

      # Add tagable.yml setup:
      FileUtils.mkdir_p(File.join(destination_root, 'config', 'constants'))
      File.write(File.join(destination_root, 'config', 'constants', 'tagable.yml'), "tagable:\n")

    end

    test "generator runs without errors" do
      assert_nothing_raised do
        run_generator [@module_class]
      end
    end

    test "generator runs without errors for a single nested module" do
      # Run the generator for the first module in the nested module array
      assert_nothing_raised do
        run_generator [@nested_module_array.first]
      end
      # Run the generator for the second module in the nested module array
      assert_nothing_raised do
        run_generator ["#{@nested_module_array[0]}::#{@nested_module_array[1]}"]
      end
    end

    test "generator runs without errors for a nested module" do
      # Run the generator for each module in the nested module array
      path = []
      @nested_module_array.each do |mod|
        path << mod
        assert_nothing_raised do
          run_generator [path.join("::")]
        end
      end
    end

    test "creates all required directories and files" do
      run_generator [@module_class]

      # Test app directory structure - now under app/<dir>/<module_name>/
      @app_dirs.each do |dir|
        assert_directory "app/#{dir}/#{@module_name}"
        assert_file "app/#{dir}/#{@module_name}/.keep"
      end

      # Test test directory structure - now under test/<dir>/<module_name>/
      @test_dirs.each do |dir|
        assert_directory "test/#{dir}/#{@module_name}"
        assert_file "test/#{dir}/#{@module_name}/.keep"
      end

      # Test locale files with language folders and correct naming
      I18n.available_locales.each do |locale|
        lang = locale.to_s
        
        # Check language directory exists
        assert_directory "config/locales/#{@module_name}/#{lang}"
        
        # Check all YAML files exist directly in the language directory
        assert_file "config/locales/#{@module_name}/#{lang}/#{lang}.#{@module_name}.yml"
        assert_file "config/locales/#{@module_name}/#{lang}/#{lang}.#{@module_name}.models.yml" do |content|
          assert_match(/models:/, content)
          assert_match(/attributes:/, content)
          assert_match(/errors:/, content)
        end
        assert_file "config/locales/#{@module_name}/#{lang}/#{lang}.#{@module_name}.views.yml" do |content|
          assert_match(/#{@module_name}:/, content)
        end
      end

      # Test template files - base.rb is now under models/<module_name>/
      assert_file "app/models/#{@module_name}/base.rb"
      assert_file "app/models/#{@module_name}.rb" do |content|
        # table_name_prefix must be a quoted string, not bare Ruby code -
        # unquoted, it's an undefined local variable/method reference and
        # raises NameError as soon as the module is loaded.
        assert_match(/table_name_prefix\s*\n\s*'#{@module_name}_'/, content)
      end
    end

    test "creates all required directories and files for nested module" do
      # Run the generator for each module in the nested module array
      path = []
      @nested_module_array.each do |mod|
        path << mod
        run_generator [path.join("::")]
      end
    end

    test "creates more required directories and files for nested module" do
      # Test app directory structure
      @app_dirs.each do |dir|
        assert_directory File.join("app", dir, @nested_module_dir)
        assert_file File.join("app", dir, @nested_module_dir, ".keep")
      end

      # Test test directory structure - now under test/<dir>/<module_name>/
      @test_dirs.each do |dir|
        assert_directory File.join("test", dir, @nested_module_dir)
        assert_file File.join("test", dir, @nested_module_dir, ".keep")
      end

      # Test locale files with language folders and correct naming
      I18n.available_locales.each do |locale|
        lang = locale.to_s
        
        # Check language directory exists
        assert_directory File.join("config", "locales", @nested_module_dir, lang)
        
        # Check all YAML files exist directly in the language directory
        assert_file File.join("config", "locales", @nested_module_dir, lang, 
          "#{lang}.#{@nested_module_name}.yml")
        assert_file File.join("config", "locales", @nested_module_dir, lang, 
          "#{lang}.#{@nested_module_name}.models.yml") do |content|
          assert_match(/models:/, content)
          assert_match(/attributes:/, content)
          assert_match(/errors:/, content)
        end
        assert_file File.join("config", "locales", @nested_module_dir, lang, 
        "#{lang}.#{@nested_module_name}.views.yml") do |content|
          assert_match(/#{@nested_module_name}:/, content)
        end
      end

      # Test template files - base.rb is now under models/<module_name>/
      assert_file File.join("app", "models", @nested_module_dir, "base.rb")
      assert_file File.join("app", "models", @nested_module_dir, "#{@nested_module_name}.rb")
    end
    
    test "updates routes with an empty module namespace at both insertion points" do
      run_generator [@module_name]
      routes_content = File.read(File.join(destination_root, 'config', 'routes.rb'))

      # Tagable models need no route changes at all (see TagableGenerator's
      # own routes_info step) - this just seeds a plain, empty namespace as
      # a ready-made home for any non-tagable, module-namespaced model's own
      # routes, added later by the scaffold generator or by hand.
      empty_namespace = /namespace :#{@module_name} do\n\s*end/
      assert_equal 2, routes_content.scan(empty_namespace).size
    end

    test "creates constants file" do
      run_generator [@module_name]
      assert_file "config/constants/#{@module_name}.yml" do |content|
        assert_match(/#{@module_name}:/, content)
      end
    end

    test "updates constants tagable.yml with module comment" do
      run_generator [@module_name] 
      content = File.read(File.join(destination_root, 'config', 'constants', 'tagable.yml'))
      assert_includes content, "# #{@module_class}", "Should include module comment in tagable.yml"
    end
  end
end