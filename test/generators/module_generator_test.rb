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

      File.write(File.join(destination_root, 'config', 'routes.rb'), <<~RUBY)
        Rails.application.routes.draw do
          # NAMESPACE INSERTION POINT 1 FOR GENERATOR
          resources :tags, shallow: true do
            # NAMESPACE INSERTION POINT 2 FOR GENERATOR
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

    test "adds_route_namespace_to_routes.rb" do
      run_generator [@module_name]
      
      assert_file "config/routes.rb" do |content|
        # Just check for the namespace and comment, ignore indentation
        assert_match(/namespace :#{@module_name}/, content)
        assert_match(/# Add #{@module_name.underscore} routes here with only: \[:index, :new, :create\]/, content)
      end
    end
    
    test "updates routes with module namespace" do
      run_generator [@module_name]
      routes_content = File.read(File.join(destination_root, 'config', 'routes.rb'))
      assert_match(/namespace :#{@module_name} do\n\s+# Add #{@module_name} routes here with only: \[:index, :new, :create\]\n\s+end/, routes_content)
      assert_match(/namespace :#{@module_name} do\n\s+# Add #{@module_name} routes here with except: \[:index\]\n\s+end/m, routes_content)
    end
    
    test "adds_factory_bot_configuration" do
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
      assert_includes content, "# #{@module_name}:", "Should include module comment in tagable.yml"
    end
  end
end