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
      assert_file "app/models/#{@module_name}.rb"
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
    
    test "updates routes with module namespace" do
      run_generator [@module_name]
      routes_content = File.read(File.join(destination_root, 'config', 'routes.rb'))
      
      # First insertion point pattern components
      namespace_start = /namespace :#{@module_name} do/
      tagable_point1 = /\s+# INSERTION POINT 1 FOR TAGABLE GENERATOR/
      comment1 = /\s+# Insert #{@module_name} member routes here with only: \[:index, :new, :create\]/
      namespace_end = /\s+end/
      first_pattern = /#{namespace_start}\n#{tagable_point1}\n#{comment1}\n#{namespace_end}/
      assert_match(first_pattern, routes_content)
      
      # Second insertion point pattern components
      tagable_point2 = /\s+# INSERTION POINT 2 FOR TAGABLE GENERATOR/
      comment2 = /\s+# Insert #{@module_name} collection routes here with except: \[:index\]/
      second_pattern = /#{namespace_start}\n#{tagable_point2}\n#{comment2}\n#{namespace_end}/m
      assert_match(second_pattern, routes_content)
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