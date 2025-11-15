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
        end
      RUBY
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

      # Test app directory structure
      @app_dirs.each do |dir|
        assert_directory "app/#{@module_name}/#{dir}"
        assert_file "app/#{@module_name}/#{dir}/.keep"
      end

      # Test test directory structure
      @test_dirs.each do |dir|
        assert_directory "test/#{@module_name}/#{dir}"
        assert_file "test/#{@module_name}/#{dir}/.keep"
      end

      # Test locale files with language folders and correct naming
      I18n.available_locales.each do |locale|
        lang = locale.to_s
        
        # Check language directory exists
        assert_directory "config/locales/#{@module_name}/#{lang}"
        
        # Check models and views subdirectories exist
        @locale_dirs.each do |file_type|
          assert_directory "config/locales/#{@module_name}/#{lang}/#{file_type}"
        end
        
        # Check general translations file
        assert_file "config/locales/#{@module_name}/#{lang}.#{@module_name}.yml"
        
        # Check models and views translation files
        @locale_dirs.each do |file_type|
          assert_file "config/locales/#{@module_name}/#{lang}.#{@module_name}.#{file_type}.yml"
        end
      end

      # Test template files
      assert_file "app/#{@module_name}/base.rb"
      assert_file "app/models/#{@module_name}.rb"
    end

    test "adds autoload paths to application.rb" do
      run_generator [@module_name]
      assert_file "config/application.rb" do |content|
        expected = <<~RUBY
          # Autoload module directories
          config.autoload_paths += %W(\#{config.root}/app/#{@module_name} \#{config.root}/app/#{@module_name}/**/)
        RUBY
        assert_includes content, expected.strip
      end
    end

    test "adds_route_namespace_to_routes.rb" do
      run_generator [@module_name]
      
      assert_file "config/routes.rb" do |content|
        # Just check for the namespace and comment, ignore indentation
        assert_match(/namespace :#{@module_name}/, content)
        assert_match(/# Add your routes here/, content)
      end
    end
  end
end