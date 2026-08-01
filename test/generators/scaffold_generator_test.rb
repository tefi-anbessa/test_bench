# test/generators/scaffold_generator_test.rb
# Adapted from test/generators/tagable_generator_test.rb, in process of adapting to nested modules. JIC.
require 'test_helper'
require Rails.root.join('lib', 'generators', 'project_assistant', 'scaffold_generator').to_s
require Rails.root.join('lib', 'generators', 'project_assistant', 'module_generator').to_s
require Rails.root.join('lib', 'generators', 'project_assistant', 'shared', 'scaffold_helper').to_s

module ProjectAssistant
  class ScaffoldGeneratorTest < Rails::Generators::TestCase
    include ProjectAssistant::Shared::ScaffoldHelper
    tests ProjectAssistant::ScaffoldGenerator
    destination Rails.root.join('tmp', 'generators', 'scaffold')
    setup :prepare_destination

    setup do
      @class_name = "ExistingModule::NewModel" # Default namespaced class
      # Set the namedbase substitutes
      name_setup_for_test
      @nesting_options = %i[project discipline tag tagable none]

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
        # $stderr.puts "DEBUG (TEST): Calling module generator with module_name #{@module_name}"
        ProjectAssistant::ModuleGenerator.start([@module_name], destination_root: destination_root)
      end

      # Test arguments for the command line
      @args = [
        'name:string:required:index:valid=Test_name',
        'description:text:valid=Test',
        'selector:enum:keys=[a,b,c]:valid=a',
        'status:enum_translated:keys=[alpha,bravo]:valid=bravo',
        'sort_order:integer:index:step=10:valid=100:unique',
        'power:float:precision=5:units=kW:step=1:valid=2.2',
        'money:decimal:units=$:precision=7:scale=2:step=.01:valid=5555.55',
        'switch:boolean:valid=true',
        'birthday:date',
        'created:datetime',
        'flex_field:jsonb',
        'code:string:uniq:valid=AA',
        'blob:binary',
        'parent:references:required=false',
        'owner:belongs_to:required'
      ]
      
      # Borrow the generator's prepare_cli and process_fields methods.
      input_fields = prepare_cli(@args)
      @fields, errors = process_fields(input_fields)
      if errors.any?
        # $stderr.puts "DEBUG (TEST): Test setup field errors: #{errors.inspect}"
      end
      # Build the generator field sets.
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

    test "generator runs without errors from definition file v0" do
      output = capture(:stderr) do
        run_generator [@class_name, "--definition=electrical_test"]
      end
      assert_no_match(/error/i, output)
    end

    test "generator runs without errors from definition file" do
      generator = ProjectAssistant::ScaffoldGenerator.new(
        [@class_name],
        { definition: "electrical_test" },
        destination_root: destination_root
      )
      assert_nothing_raised do
        generator.invoke_all
      end
    end

    test "validates name with invalid class name" do
      generator = ProjectAssistant::ScaffoldGenerator.new(
        ["ExistingModule::123Invalid", "name:string"],
        {},
        destination_root: destination_root
      )
      assert_raises(Thor::Error) do
        generator.invoke_all
      end
    end

    test "validates name with non-existent module" do
      generator = ProjectAssistant::ScaffoldGenerator.new(
        ["NonExistent::Heater", "name:string"],
        {},
        destination_root: destination_root
      )
      assert_raises(Thor::Error) do
        generator.invoke_all
      end
    end

    test "validates correct name format" do
      generator = ProjectAssistant::ScaffoldGenerator.new(
        [@class_name, "name:string"],
        {},
        destination_root: destination_root
      )
      assert_nothing_raised do
        generator.invoke_all
      end
    end

    test "generator checks definition file exists" do
      generator = ProjectAssistant::ScaffoldGenerator.new(
        [@class_name],
        { definition: "no-file" },
        destination_root: destination_root
      )
      assert_raises(Thor::Error) do
        generator.invoke_all
      end
    end

    test "generator checks nesting option is valid" do
      generator = ProjectAssistant::ScaffoldGenerator.new(
        [@class_name, "name:string"],
        { nesting: "invalid" },
        destination_root: destination_root
      )
      assert_raises(Thor::Error) do
        generator.invoke_all
      end
    end

    test "validates invalid field names" do
      invalid_args = ["123invalid:string", "invalid-name:string", "invalid name:string"]
      generator = ProjectAssistant::ScaffoldGenerator.new(
        [@class_name, *invalid_args],
        {},
        destination_root: destination_root
      )
      assert_raises(Thor::Error) do
        generator.invoke_all
      end
    end

    test "validates missing field types" do
      invalid_args = ["name:", "description"]
      generator = ProjectAssistant::ScaffoldGenerator.new(
        [@class_name, *invalid_args],
        {},
        destination_root: destination_root
      )
      assert_raises(Thor::Error) do
        generator.invoke_all
      end
    end

    test "validates unknown field types" do
      invalid_args = ["name:invalid_type", "description:unknown"]
      generator = ProjectAssistant::ScaffoldGenerator.new(
        [@class_name, *invalid_args],
        {},
        destination_root: destination_root
      )
      assert_raises(Thor::Error) do
        generator.invoke_all
      end
    end

    test "validates unknown field options" do
      invalid_args = ["name:string:invalid_option", "description:text:unknown:another_invalid"]
      generator = ProjectAssistant::ScaffoldGenerator.new(
        [@class_name, *invalid_args],
        {},
        destination_root: destination_root)
      assert_raises(Thor::Error) do
        generator.invoke_all
      end
    end

    test "validates flag options require a valid boolean" do
      invalid_args = ["name:string:required=5", "description:text:uniq=yes"]
      generator = ProjectAssistant::ScaffoldGenerator.new(
        [@class_name, *invalid_args],
        {},
        destination_root: destination_root)
      assert_raises(Thor::Error) do
        generator.invoke_all
      end
    end

    test "validates valid options requires a value of the correct type" do
      invalid_args = ["count:integer:valid=5.5", "power:float:valid=true", "switch:boolean:valid=NO"]
      generator = ProjectAssistant::ScaffoldGenerator.new(
        [@class_name, *invalid_args],
        {},
        destination_root: destination_root)
      assert_raises(Thor::Error) do
        generator.invoke_all
      end
    end

    test "validates keys option requires an array of identifiers" do
      invalid_args = ["select1:enum:keys=5.5", "select2:enum:keys={key1,key2}", "select3:enum_translated:keys=a,b", "select4:enum:keys=[Capital,in-line]"]
      generator = ProjectAssistant::ScaffoldGenerator.new(
        [@class_name, *invalid_args],
        {},
        destination_root: destination_root)
      assert_raises(Thor::Error) do
        generator.invoke_all
      end
    end

    test "validates scale, precision options on invalid types" do
      invalid_args = ["name:string:precision=5", "description:text:scale=2"]
      generator = ProjectAssistant::ScaffoldGenerator.new(
        [@class_name, *invalid_args],
        {},
        destination_root: destination_root)
      assert_raises(Thor::Error) do
        generator.invoke_all
      end
    end

    test "validates scale, precision options with invalid value" do
      invalid_args = ["cost:decimal:precision=5.5:scale=-1", "power:float:scale=1e3:precision=high"]
      generator = ProjectAssistant::ScaffoldGenerator.new(
        [@class_name, *invalid_args],
        {},
        destination_root: destination_root)
      assert_raises(Thor::Error) do
        generator.invoke_all
      end
    end

    test "validates units, si options with invalid types" do
      invalid_args = ["name:string:units=m:si", "description:text:units=J:si", "select1:enum:units=s:si", "count:integer:units=kJ/m2:si"]
      generator = ProjectAssistant::ScaffoldGenerator.new(
        [@class_name, *invalid_args],
        {},
        destination_root: destination_root)
      assert_raises(Thor::Error) do
        generator.invoke_all
      end
    end

    test "validates si option requires valid boolean value" do
      invalid_args = ["power:float:units=m:si=yes"]
      generator = ProjectAssistant::ScaffoldGenerator.new(
        [@class_name, *invalid_args],
        {},
        destination_root: destination_root)
      assert_raises(Thor::Error) do
        generator.invoke_all
      end
    end

    test "validates step with non_numeric types" do
      invalid_args = ["name:string:step=1", "description:text:step=.1", "select1:enum:step=100", "flex:jsonb:step", "parent:references:step=1", "created:date:step=1"]
      generator = ProjectAssistant::ScaffoldGenerator.new(
        [@class_name, *invalid_args],
        {},
        destination_root: destination_root)
      assert_raises(Thor::Error) do
        generator.invoke_all
      end
    end

    test "validates step value is decimal" do
      invalid_args = ["power:float:units=m:si=true:step=string"]
      generator = ProjectAssistant::ScaffoldGenerator.new(
        [@class_name, *invalid_args],
        {},
        destination_root: destination_root)
      assert_raises(Thor::Error) do
        generator.invoke_all
      end
    end

    test "validates option key is valid" do
      invalid_args = ["power:float:units=m:si=true:invalid=string"]
      generator = ProjectAssistant::ScaffoldGenerator.new(
        [@class_name, *invalid_args],
        {},
        destination_root: destination_root)
      assert_raises(Thor::Error) do
        generator.invoke_all
      end
    end

    test "creates model" do
      original_class_name = @class_name
      original_model_class_name = @model_class_name
      # Core model: Set class name without namespace module
      @nesting_options.each do |nesting|
        @class_name = original_model_class_name + nesting.to_s.classify
        # Reset the namedbase substitutes
        name_setup_for_test
        run_generator [@class_name, *@args, "--nesting=#{nesting}"]
        assert_file File.join(destination_root, 'app', 'models', "#{@singular_name}.rb") do |content|
          assert_includes content, "class #{@model_class_name} < ApplicationRecord"
          test_assertions_model(content, nesting)
        end
      end

      # Namespaced model: Set class name with namespace module
      @nesting_options.each do |nesting|
        @class_name = original_class_name + nesting.to_s.classify
        # Reset the namedbase substitutes
        name_setup_for_test
        run_generator [@class_name, *@args, "--nesting=#{nesting}"]
        assert_file File.join(destination_root, 'app', 'models', @folder, "#{@singular_name}.rb") do |content|
          assert_includes content, "module #{@module_name}"
          assert_includes content, "class #{@model_class_name} < Base"
          test_assertions_model(content, nesting)
        end
      end
    end

    test "creates factory" do
      # Core factory
      original_class_name = @class_name
      original_model_class_name = @model_class_name
      @nesting_options.each do |nesting|
        @class_name = original_model_class_name + nesting.to_s.classify
        # Reset the namedbase substitutes
        name_setup_for_test
        run_generator [@class_name, *@args, "--nesting=#{nesting}"]
        factory_file = File.join(destination_root, 'test', 'factories', folder, 
          "#{@plural_name}.rb")
        assert_file factory_file do |content|
          test_assertions_factory(content, nesting)
        end
      end

      # Namespaced factory
      @nesting_options.each do |nesting|
        @class_name = original_class_name + nesting.to_s.classify
        # Reset the namedbase substitutes
        name_setup_for_test
        run_generator [@class_name, *@args, "--nesting=#{nesting}"]
        factory_file = File.join(destination_root, 'test', 'factories', folder, 
          "#{@plural_name}.rb")
        assert_file factory_file do |content|
          test_assertions_factory(content, nesting)
        end
      end
    end

    test "creates model test" do
      run_generator [@class_name, *@args]
      assert_file File.join(destination_root, 'test', 'models', @folder, "#{@singular_name}_test.rb") do |content|
        assert_includes content, "module #{@module_name}"
        test_assertions_model_test(content)
      # Core model test
      @class_name = @model_class_name
      name_setup_for_test
      run_generator [@class_name, *@args]
      assert_file File.join(destination_root, 'test', 'models', "#{@singular_name}_test.rb") do |content|
        test_assertions_model_test(content)
        end
      end
    end

    test "creates migration" do
      migration_dir = File.join(destination_root, "db", "migrate")
      original_class_name = @class_name
      original_model_class_name = @model_class_name
      # Core model: Set class name without namespace module
      @nesting_options.each do |nesting|
        @class_name = original_model_class_name + nesting.to_s.classify
        # Reset the namedbase substitutes
        name_setup_for_test
        run_generator [@class_name, *@args, "--nesting=#{nesting}"]
        
        migration_file = Dir.glob(File.join(migration_dir, "*_create_#{@singular_table_name}.rb")).first
        assert_file migration_file do |content|
          test_assertions_migration(content, nesting)
        end
      end

      # Namespaced model: Set class name with namespace module
      @nesting_options.each do |nesting|
        @class_name = original_class_name + nesting.to_s.classify
        # Reset the namedbase substitutes
        name_setup_for_test
        run_generator [@class_name, *@args, "--nesting=#{nesting}"]
        migration_file = Dir.glob(File.join(migration_dir, "*_create_#{@singular_table_name}.rb")).first
        assert_file migration_file do |content|
          test_assertions_migration(content, nesting)
        end
      end
    end

    test "creates policy" do
      original_class_name = @class_name
      original_model_class_name = @model_class_name
      # Core policy: Set class name without namespace module
      @nesting_options.each do |nesting|
        @class_name = original_model_class_name + nesting.to_s.classify
        # Reset the namedbase substitutes
        name_setup_for_test
        run_generator [@class_name, *@args, "--nesting=#{nesting}"]
        policy_file = File.join(destination_root, 'app', 'policies', @folder, 
          "#{@singular_name}_policy.rb")
        assert_file policy_file do |content|
          test_assertions_policy(content, nesting)
        end
      end

      # Namespaced model: Set class name with namespace module
      @nesting_options.each do |nesting|
        @class_name = original_class_name + nesting.to_s.classify
        # Reset the namedbase substitutes
        name_setup_for_test
        run_generator [@class_name, *@args, "--nesting=#{nesting}"]
        policy_file = File.join(destination_root, 'app', 'policies', @folder, 
          "#{@singular_name}_policy.rb")
        assert_file policy_file do |content|
          assert_includes content, "module #{@module_name}"
          test_assertions_policy(content, nesting)
        end
      end
    end

    test "creates policy test" do
      original_class_name = @class_name
      original_model_class_name = @model_class_name
      # Core policy: Set class name without namespace module
      @nesting_options.each do |nesting|
        @class_name = original_model_class_name + nesting.to_s.classify
        # Reset the namedbase substitutes
        name_setup_for_test
        run_generator [@class_name, *@args, "--nesting=#{nesting}"]
        policy_test_file = File.join(destination_root, 'test', 'policies', @folder, 
          "#{@singular_name}_policy_test.rb")
        assert_file policy_test_file do |content|
          test_assertions_policy_test(content, nesting)
        end
        # Namespaced policy: Set class name with namespace module
        @class_name = original_class_name + nesting.to_s.classify
        # Reset the namedbase substitutes
        name_setup_for_test
        run_generator [@class_name, *@args, "--nesting=#{nesting}"]
        policy_test_file = File.join(destination_root, 'test', 'policies', @folder, 
          "#{@singular_name}_policy_test.rb")
        assert_file policy_test_file do |content|
          assert_includes content, "module #{@module_name}"
          test_assertions_policy_test(content, nesting)
        end
      end
    end

    test "creates controller" do
      original_class_name = @class_name
      original_model_class_name = @model_class_name
      # Core controller: Set class name without namespace module
      @nesting_options.each do |nesting|
        @class_name = original_model_class_name + nesting.to_s.classify
        # Reset the namedbase substitutes
        name_setup_for_test
        run_generator [@class_name, *@args, "--nesting=#{nesting}"]
        controller_file = File.join(destination_root, 'app', 'controllers', @folder, 
          "#{@plural_name}_controller.rb")
        assert_file controller_file do |content|
          test_assertions_controller(content, nesting)
        end
        # Namespaced policy: Set class name with namespace module
        @class_name = original_class_name + nesting.to_s.classify
        # Reset the namedbase substitutes
        name_setup_for_test
        run_generator [@class_name, *@args, "--nesting=#{nesting}"]
        controller_file = File.join(destination_root, 'app', 'controllers', @folder, 
          "#{@plural_name}_controller.rb")
        assert_file controller_file do |content|
          assert_includes content, "module #{@module_name}"
          test_assertions_controller(content, nesting)
        end
      end
    end

    test "creates views" do
      original_class_name = @class_name
      original_model_class_name = @model_class_name
      # Core controller: Set class name without namespace module
      @nesting_options.each do |nesting|
        @class_name = original_model_class_name + nesting.to_s.classify
        # Reset the namedbase substitutes
        name_setup_for_test
        run_generator [@class_name, *@args, "--nesting=#{nesting}"]
        views_dir = File.join(destination_root, 'app', 'views', @folder, @plural_name)

      # index.html.erb
        assert_file File.join(views_dir, 'index.html.erb') do |content|
          test_assertions_index_view(content, nesting)
        end

      # _header.html.erb
        assert_file File.join(views_dir, '_header.html.erb') do |content|
          test_assertions_header_view(content, nesting)
        end

      # _row.html.erb
        assert_file File.join(views_dir, "_row.html.erb") do |content|
          test_assertions_row_view(content, nesting)
        end
      
      # show.html.erb
        assert_file File.join(views_dir, "show.html.erb") do |content|
          test_assertions_show_view(content, nesting)
        end
      
      # new.html.erb
        assert_file File.join(views_dir, "new.html.erb") do |content|
          test_assertions_new_view(content, nesting)
        end
      
      # edit.html.erb
        assert_file File.join(views_dir, "edit.html.erb") do |content|
          test_assertions_edit_view(content, nesting)
        end
      
      # _form.html.erb
        assert_file File.join(views_dir, "_form.html.erb") do |content|
          test_assertions_form_view(content, nesting)
        end
      
      # _card.html.erb
        assert_file File.join(views_dir, "_card.html.erb") do |content|
          test_assertions_card_view(content, nesting)
        end

        # Namespaced policy: Set class name with namespace module
        @class_name = original_class_name + nesting.to_s.classify
        # Reset the namedbase substitutes
        name_setup_for_test
        run_generator [@class_name, *@args, "--nesting=#{nesting}"]
        views_dir = File.join(destination_root, 'app', 'views', @folder, @plural_name)

      # index.html.erb
        assert_file File.join(views_dir, 'index.html.erb') do |content|
          test_assertions_index_view(content, nesting)
        end

      # _header.html.erb
        assert_file File.join(views_dir, '_header.html.erb') do |content|
          test_assertions_header_view(content, nesting)
        end

      # _row.html.erb
        assert_file File.join(views_dir, "_row.html.erb") do |content|
          test_assertions_row_view(content, nesting)
        end
      
      # show.html.erb
        assert_file File.join(views_dir, "show.html.erb") do |content|
          test_assertions_show_view(content, nesting)
        end
      
      # new.html.erb
        assert_file File.join(views_dir, "new.html.erb") do |content|
          test_assertions_new_view(content, nesting)
        end
      
      # edit.html.erb
        assert_file File.join(views_dir, "edit.html.erb") do |content|
          test_assertions_edit_view(content, nesting)
        end
      
      # _form.html.erb
        assert_file File.join(views_dir, "_form.html.erb") do |content|
          test_assertions_form_view(content, nesting)
        end
      
      # _card.html.erb
        assert_file File.join(views_dir, "_card.html.erb") do |content|
          test_assertions_card_view(content, nesting)
        end
      end
      
      # Skip cleanup for this test to examine generated files
      @skip_cleanup = true
    end

    test "creates controller test" do
      original_class_name = @class_name
      original_model_class_name = @model_class_name
      # Core controller: Set class name without namespace module
      @nesting_options.each do |nesting|
        @class_name = original_model_class_name + nesting.to_s.classify
        # Reset the namedbase substitutes
        name_setup_for_test
        run_generator [@class_name, *@args, "--nesting=#{nesting}"]
        controller_test_file = File.join(destination_root, 'test', 'controllers', folder, 
          "#{@plural_name}_controller_test.rb")
        assert_file controller_test_file do |content|
          test_assertions_controller_test(content, nesting)
        end
        # Namespaced policy: Set class name with namespace module
        @class_name = original_class_name + nesting.to_s.classify
        # Reset the namedbase substitutes
        name_setup_for_test
        run_generator [@class_name, *@args, "--nesting=#{nesting}"]
        controller_test_file = File.join(destination_root, 'test', 'controllers', folder, 
          "#{@plural_name}_controller_test.rb")
        assert_file controller_test_file do |content|
          assert_includes content, "module #{@module_name}"
          test_assertions_controller_test(content, nesting)
        end
      end
    end

    test "creates system test" do
      original_class_name = @class_name
      original_model_class_name = @model_class_name
      # Core controller: Set class name without namespace module
      @nesting_options.each do |nesting|
        @class_name = original_model_class_name + nesting.to_s.classify
        # Reset the namedbase substitutes
        name_setup_for_test
        run_generator [@class_name, *@args, "--nesting=#{nesting}"]
        system_test_file = File.join(destination_root, 'test', 'system', folder, 
        "#{@plural_name}_system_test.rb")
        assert_file system_test_file do |content|
          test_assertions_system_test(content, nesting)
        end
        # Namespaced policy: Set class name with namespace module
        @class_name = original_class_name + nesting.to_s.classify
        # Reset the namedbase substitutes
        name_setup_for_test
        run_generator [@class_name, *@args, "--nesting=#{nesting}"]
        system_test_file = File.join(destination_root, 'test', 'system', folder, 
        "#{@plural_name}_system_test.rb")
        assert_file system_test_file do |content|
          assert_includes content, "module #{@module_name}"
          test_assertions_system_test(content, nesting)
        end
      end
    end

    test "adds enum constants" do
      run_generator(@args)
      constants_file = File.join(destination_root, 'config', 'constants', "#{module_name.underscore}.yml") 
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
        models_file = File.join(destination_root, "config", "locales", folder, 
          locale.to_s, "#{locale.to_s}.#{module_name.underscore}.models.yml")
        assert_file models_file do |content|
          assert_match(/#{folder}\/#{@singular_name}:\s+"#{@model_class_name.underscore.humanize}"/, content)
          @fields.each do |field|
            assert_match(/#{field[:name]}:\s+\"#{field[:name].humanize}\"/, content)
          end
        end
      end
    end

    test "creates views translations" do
      run_generator @args
      I18n.available_locales.each do |locale|
      views_file = File.join(destination_root, "config", "locales", folder, 
            locale.to_s, "#{locale.to_s}.#{module_name.underscore}.views.yml")
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
          models_file = File.join(destination_root, "config", "locales", folder, 
            locale.to_s, "#{locale.to_s}.#{module_name.underscore}.models.yml")
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

    # Required to allow sharing of some scaffold_helper methods in tests.
    def class_name
      @class_name
    end

    def singular_name
      @model_class_name.underscore # "new_model"
    end

    def table_name
      [*@class_path, @singular_name.pluralize].join"_" # "existing_module_sub_module_new_models"; "existing_module_new_models"; "new_models"
    end

    def singular_table_name
      [*@class_path, @singular_name].join"_" # "existing_module_sub_module_new_models"; "existing_module_new_models"; "new_models"
    end

    def teardown
      # Skip cleanup if flag is set
      return if @skip_cleanup
      super
    end
  end
end