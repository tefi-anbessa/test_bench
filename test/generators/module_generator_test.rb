# test/generators/module_generator_test.rb
require 'test_helper'
require Rails.root.join('lib/generators/project_assistant/module_generator').to_s

module ProjectAssistant
  class ModuleGeneratorTest < Rails::Generators::TestCase
    tests ProjectAssistant::ModuleGenerator
    destination Rails.root.join('tmp/generators')
    setup :prepare_destination

    setup do
      @module_name = "electrical"
      @module_class = "Electrical"
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
      puts "\n=== Starting generator test ==="
      assert_nothing_raised do
        puts "Running generator with module: #{@module_name}"
        run_generator [@module_name]
        puts "Generator completed successfully"
      end
    end

    test "creates all required directories and files" do
      run_generator [@module_name]

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
        assert_file "config/locales/#{@module_name}/#{lang}/#{lang}.#{@module_name}.models.yml"
        assert_file "config/locales/#{@module_name}/#{lang}/#{lang}.#{@module_name}.views.yml"
      end

      # Test template files - base.rb is now under models/<module_name>/
      assert_file "app/models/#{@module_name}/base.rb"
      assert_file "app/models/#{@module_name}.rb"
    end

    test "adds factory_bot configuration to application.rb" do
      run_generator [@module_name]
      assert_file "config/application.rb" do |content|
        expected = "config.factory_bot.definition_file_paths << File.join(destination_root, 'test', '#{@module_name.underscore}', 'factories')"
        assert_includes content, expected
      end
    end
    
    test "updates routes with module namespace" do
      run_generator [@module_name]
      routes_content = File.read(File.join(destination_root, 'config', 'routes.rb'))
      
      # First insertion point pattern components
      namespace_start = /namespace :#{@module_name} do/
      tagable_point1 = /\s+# INSERTION POINT 1 FOR TAGABLE GENERATOR/
      comment1 = /\s+# Add #{@module_name} routes here with only: \[:index, :new, :create\]/
      namespace_end = /\s+end/
      first_pattern = /#{namespace_start}\n#{tagable_point1}\n#{comment1}\n#{namespace_end}/
      assert_match(first_pattern, routes_content)
      
      # Second insertion point pattern components
      tagable_point2 = /\s+# INSERTION POINT 2 FOR TAGABLE GENERATOR/
      comment2 = /\s+# Add #{@module_name} routes here with except: \[:index\]/
      second_pattern = /#{namespace_start}\n#{tagable_point2}\n#{comment2}\n#{namespace_end}/m
      assert_match(second_pattern, routes_content)
    end
    
    test "adds factory_bot configuration" do
      run_generator [@module_name]
      
      assert_file "config/application.rb" do |content|
        expected = "config.factory_bot.definition_file_paths << File.join(destination_root, 'test', '#{@module_name.underscore}', 'factories')"
        assert_match(/#{Regexp.escape(expected)}/, content)
      end
    end

    test "creates constants file" do
      run_generator [@module_name]
      assert_file "config/constants/#{@module_name}.yml"
    end

    test "updates constants tagable.yml with module comment" do
      run_generator [@module_name] 
      content = File.read(File.join(destination_root, 'config', 'constants', 'tagable.yml'))
      assert_includes content, "# #{@module_class}", "Should include module comment in tagable.yml"
    end
  end
end