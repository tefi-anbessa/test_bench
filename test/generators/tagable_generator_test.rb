# test/generators/tagable_generator_test.rb
require 'test_helper'
require Rails.root.join('lib', 'generators', 'project_assistant', 'tagable_generator').to_s
require Rails.root.join('lib', 'generators', 'project_assistant', 'module_generator').to_s
require Rails.root.join('lib', 'generators', 'project_assistant', 'shared', 'scaffold_helper').to_s

module ProjectAssistant
  class TagableGeneratorTest < Rails::Generators::TestCase
    include ProjectAssistant::Shared::ScaffoldHelper
    tests ProjectAssistant::TagableGenerator
    destination Rails.root.join('tmp', 'generators', 'tagable')
    setup :prepare_destination

    setup do
      @class_name = "ExistingModule::NewModel" # Always namespaced - tagable models require a module.
      @nesting = :tagable
      name_setup_for_test

      # Create clean files for testing (avoid conflicts with real app files)
      FileUtils.mkdir_p(File.join(destination_root, 'config'))
      FileUtils.mkdir_p(File.join(destination_root, 'config', 'constants'))

      # routes.rb isn't touched by this generator (tagable routes are
      # entirely generic), but module_generator expects it to exist.
      File.write(File.join(destination_root, 'config', 'routes.rb'), <<~RUBY)
        Rails.application.routes.draw do
        end
      RUBY

      File.write(File.join(destination_root, 'config', 'constants', 'core.yml'), <<~YAML)
        nr: "Not Required"
      YAML

      File.write(File.join(destination_root, 'config', 'constants', 'tagable.yml'), <<~YAML)
        tagable:
          # Document
      YAML

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

      @args = [
        'name:string:required:index:valid=Test_name',
        'description:text:valid=Test',
        'selector:enum:keys=[a,b,c]:valid=a',
        'status:enum_translated:keys=[alpha,bravo]:valid=bravo',
        'sort_order:integer:index:step=1:valid=100:unique',
        'power:float:precision=5:units=kW:step=0.1:valid=2.2',
        'switch:boolean:valid=true',
        'birthday:date',
        'created:datetime',
        'flex_field:jsonb',
        'code:string:uniq:valid=AA',
      ]

      input_fields = prepare_cli(@args)
      @fields, errors = process_fields(input_fields)
      field_sets
    end

    test "module generator setup complete" do
      paths_to_check(@folder).each do |path|
        assert_directory path
      end
    end

    test "generator runs without errors from cli" do
      output = capture(:stderr) do
        run_generator [@class_name, *@args]
      end
      assert_no_match(/error/i, output)
    end

    test "validates name requires a module prefix" do
      generator = ProjectAssistant::TagableGenerator.new(
        ["BareModelNoModule", "name:string"],
        {},
        destination_root: destination_root
      )
      assert_raises(Thor::Error) do
        generator.invoke_all
      end
    end

    test "validates name with invalid class name" do
      generator = ProjectAssistant::TagableGenerator.new(
        ["ExistingModule::123Invalid", "name:string"],
        {},
        destination_root: destination_root
      )
      assert_raises(Thor::Error) do
        generator.invoke_all
      end
    end

    test "validates name with non-existent module" do
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
        [@class_name, "name:string"],
        {},
        destination_root: destination_root
      )
      assert_nothing_raised do
        generator.invoke_all
      end
    end

    test "generator checks definition file exists" do
      generator = ProjectAssistant::TagableGenerator.new(
        [@class_name],
        { definition: "no-file" },
        destination_root: destination_root
      )
      assert_raises(Thor::Error) do
        generator.invoke_all
      end
    end

    test "creates model" do
      run_generator [@class_name, *@args]
      assert_file File.join(destination_root, 'app', 'models', @folder, "#{@singular_name}.rb") do |content|
        assert_includes content, "module #{@module_name}"
        assert_includes content, "class #{@model_class_name} < Base"
        test_assertions_model(content, @nesting)
      end
    end

    test "creates factory" do
      run_generator [@class_name, *@args]
      factory_file = File.join(destination_root, 'test', 'factories', @folder, "#{@plural_name}.rb")
      assert_file factory_file do |content|
        test_assertions_factory(content, @nesting)
      end
    end

    test "creates model test" do
      run_generator [@class_name, *@args]
      assert_file File.join(destination_root, 'test', 'models', @folder, "#{@singular_name}_test.rb") do |content|
        assert_includes content, "module #{@module_name}"
        test_assertions_model_test(content, @nesting)
      end
    end

    test "creates migration" do
      run_generator [@class_name, *@args]
      migration_dir = File.join(destination_root, "db", "migrate")
      migration_file = Dir.glob(File.join(migration_dir, "*_create_#{@singular_table_name}.rb")).first
      assert_file migration_file do |content|
        test_assertions_migration(content, @nesting)
      end
    end

    test "creates controller extension" do
      run_generator [@class_name, *@args]
      extension_file = File.join(destination_root, 'app', 'controllers', @folder, "#{@singular_name}_extension.rb")
      assert_file extension_file do |content|
        test_assertions_controller_extension(content)
      end
    end

    test "creates views" do
      run_generator [@class_name, *@args]
      views_dir = File.join(destination_root, 'app', 'views', @folder, @plural_name)

      assert_file File.join(views_dir, 'index.html.erb') do |content|
        test_assertions_index_view(content, @nesting)
      end
      assert_file File.join(views_dir, '_header.html.erb') do |content|
        test_assertions_header_view(content, @nesting)
      end
      assert_file File.join(views_dir, '_row.html.erb') do |content|
        test_assertions_row_view(content, @nesting)
      end
      assert_file File.join(views_dir, 'show.html.erb') do |content|
        test_assertions_show_view(content, @nesting)
      end
      assert_file File.join(views_dir, 'new.html.erb') do |content|
        test_assertions_new_view(content, @nesting)
      end
      assert_file File.join(views_dir, 'edit.html.erb') do |content|
        assert_tagable_edit_view(content)
      end
      assert_file File.join(views_dir, '_form.html.erb') do |content|
        test_assertions_form_view(content, @nesting)
      end
      assert_file File.join(views_dir, '_card.html.erb') do |content|
        test_assertions_card_view(content, @nesting)
      end
    end

    test "creates controller test" do
      run_generator [@class_name, *@args]
      controller_test_file = File.join(destination_root, 'test', 'controllers', @folder, "#{@plural_name}_controller_test.rb")
      assert_file controller_test_file do |content|
        assert_includes content, "module #{@module_name}"
        test_assertions_controller_test(content, @nesting)
      end
    end

    test "creates system test" do
      run_generator [@class_name, *@args]
      system_test_file = File.join(destination_root, 'test', 'system', @folder, "#{@plural_name}_system_test.rb")
      assert_file system_test_file do |content|
        assert_includes content, "module #{@module_name}"
        test_assertions_system_test(content, @nesting)
      end
    end

    test "does not touch routes file" do
      run_generator [@class_name, *@args]
      routes_file = File.join(destination_root, "config", "routes.rb")
      assert_file routes_file do |content|
        refute_match(/resources\s+:#{@plural_name}/, content)
      end
    end

    test "registers the new type in the tagable registry" do
      run_generator [@class_name, *@args]
      registry_file = File.join(destination_root, 'config', 'constants', 'tagable.yml')
      assert_file registry_file do |content|
        assert_match(/^\s*-\s*#{Regexp.escape(@class_name)}\s*$/, content)
      end
    end

    test "does not register the same type twice on a second run" do
      run_generator [@class_name, *@args]
      run_generator [@class_name, *@args]
      registry_file = File.join(destination_root, 'config', 'constants', 'tagable.yml')
      content = File.read(registry_file)
      assert_equal 1, content.scan(/^\s*-\s*#{Regexp.escape(@class_name)}\s*$/).count
    end

    test "registers the new type directly under its module comment" do
      registry_file = File.join(destination_root, 'config', 'constants', 'tagable.yml')
      File.write(registry_file, <<~YAML)
        tagable:
          # ExistingModule
          - ExistingModule::Other
          # Piping
          - Piping::Pipe
      YAML
      run_generator [@class_name, *@args]
      assert_file registry_file do |content|
        assert_includes content, "  # ExistingModule\n  - #{@class_name}\n  - ExistingModule::Other\n"
      end
    end

    test "adds enum constants" do
      run_generator [@class_name, *@args]
      constants_file = File.join(destination_root, 'config', 'constants', "#{@module_name.underscore}.yml")
      assert_file constants_file do |content|
        assert_includes content, "#{@singular_name}:"
        @enum_fields.each do |f|
          assert_includes content, "#{f[:name]}:"
          f[:options][:keys].each_with_index do |key, index|
            assert_includes content, "#{key}: #{index}"
          end
        end
      end
    end

    test "creates model translations" do
      run_generator [@class_name, *@args]
      I18n.available_locales.each do |locale|
        models_file = File.join(destination_root, "config", "locales", @folder,
          locale.to_s, "#{locale}.#{@module_name.underscore}.models.yml")
        assert_file models_file do |content|
          assert_match(/#{@folder}\/#{@singular_name}:\s*\n\s*one:\s+"#{@model_class_name.underscore.humanize}"/, content)
          assert_match(/other:\s+"#{@model_class_name.underscore.humanize.pluralize}"/, content)
          @fields.each do |field|
            assert_match(/#{field[:name]}:\s+\"#{field[:name].humanize}\"/, content)
          end
        end
      end
    end

    test "creates views translations" do
      run_generator [@class_name, *@args]
      I18n.available_locales.each do |locale|
        views_file = File.join(destination_root, "config", "locales", @folder,
          locale.to_s, "#{locale}.#{@module_name.underscore}.views.yml")
        assert_file views_file do |content|
          assert_match(/#{@plural_name}:/, content)
          assert_match(/title:\s*"#{@human_name.pluralize}"/, content)
          assert_match(/title:\s*"Edit #{@human_name}"/, content)
          assert_match(/title:\s*"New #{@human_name}"/, content)
          assert_match(/title:\s*"#{@human_name}"/, content)
        end
      end
    end

    private

    # Required to allow sharing of some scaffold_helper methods in tests -
    # TagableGeneratorTest isn't a Rails::Generators::NamedBase subclass, so
    # these NamedBase methods aren't naturally available here; redefine them
    # to read the ivars name_setup_for_test already sets. Without this,
    # bare "class_name" silently resolves to Minitest::Test#class_name
    # (self.class.name) instead - confirmed the hard way.
    def class_name
      @class_name
    end

    def singular_name
      @model_class_name.underscore
    end

    def table_name
      [*@class_path, @singular_name.pluralize].join"_"
    end

    def singular_table_name
      [*@class_path, @singular_name].join"_"
    end

    def assert_tagable_edit_view(content)
      form_variables, _scope = set_form_variables(:tagable)
      assert_includes content, "provide(:title, t('.title'))"
      assert_includes content, "provide(:header, t('.header', label: @#{@singular_name}.long_label))"
      assert_includes content, "render partial"
      assert_includes content, [*form_variables].join(",\n\t")
    end
  end
end
