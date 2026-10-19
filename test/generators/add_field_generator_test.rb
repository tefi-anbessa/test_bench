# frozen_string_literal: true
require "test_helper"
require Rails.root.join("lib", "generators", "project_assistant", "scaffold_generator").to_s
require Rails.root.join("lib", "generators", "project_assistant", "add_field_generator").to_s
require Rails.root.join("lib", "generators", "project_assistant", "remove_field_generator").to_s

module ProjectAssistant
  class AddFieldGeneratorTest < Rails::Generators::TestCase
    tests ProjectAssistant::AddFieldGenerator
    destination Rails.root.join("tmp", "generators", "add_field")
    setup :prepare_destination

    TABLE_NAME = "add_field_test_gizmos"
    CLASS_NAME = "AddFieldTestGizmo"

    setup do
      # Same sandbox-fixture approach as remove_field_generator_test.rb -
      # realistic text for every non-model-discovery touchpoint comes from
      # actually running ScaffoldGenerator, since discover/validate here
      # never reads this text for the field itself (it reflects on a real,
      # live model class - see build_live_table_and_model).
      FileUtils.mkdir_p(File.join(destination_root, "config", "constants"))
      FileUtils.mkdir_p(File.join(destination_root, "config", "locales", "core", "en"))
      %w[km th cn].each { |l| FileUtils.mkdir_p(File.join(destination_root, "config", "locales", "core", l)) }

      File.write(File.join(destination_root, "config", "routes.rb"), <<~RUBY)
        Rails.application.routes.draw do
          resources :#{TABLE_NAME}
          # Insertion point for non-nested routes
        end
      RUBY
      File.write(File.join(destination_root, "config", "constants", "core.yml"), "nr: \"Not Required\"\n")
      %w[en km th cn].each do |locale|
        File.write(File.join(destination_root, "config", "locales", "core", locale, "#{locale}.models.yml"),
          "#{locale}:\n  activerecord:\n    models:\n    attributes:\n")
        File.write(File.join(destination_root, "config", "locales", "core", locale, "#{locale}.views.yml"), "#{locale}:\n")
      end
      File.write(File.join(destination_root, "config", "application.rb"), <<~RUBY)
        module TestApp
          class Application < Rails::Application
          end
        end
      RUBY

      capture(:stdout) do
        ScaffoldGenerator.start(
          [CLASS_NAME,
           "existing_field:string:required=true",
           "existing_unique:string:unique=true",
           "existing_status:enum:keys=active,retired",
           "existing_owner:references",
           "--nesting=none"],
          destination_root: destination_root
        )
      end

      build_live_table_and_model
    end

    teardown do
      drop_live_table_and_model
    end

    # --- Golden path, one per field category ---

    test "adds a plain required attribute to every touchpoint" do
      run_add_field("new_field:string:required:valid=widget")
      assert_added_to_model(/validates :new_field, presence: true\n/)
      assert_added_to_model(/:new_field\b/) # ransackable_attributes
      assert_added_to_controller(/:new_field\b/)
      assert_added_to_views("new_field")
      assert_added_to_factory(/new_field \{ "widget" \}\n/)
      assert_added_to_model_test(/test_required_fields\(.*?:new_field.*?\)/)
      assert_added_to_system_test(/\bnew_field\b/)

      # Surgical, not a wipe: existing fields must survive untouched.
      assert_match(/:existing_unique\b/, model_content)
      assert_match(/validates :existing_unique, uniqueness: true/, model_content)

      migration = migration_content(:new_field)
      assert_match(/add_column :#{TABLE_NAME}, :new_field, :string/, migration)
      assert_match(/UPDATE #{TABLE_NAME} SET new_field = 'widget' WHERE new_field IS NULL/, migration)
      assert_match(/change_column_null :#{TABLE_NAME}, :new_field, false/, migration)
      assert_match(/def up/, migration) # not `change` - execute+change_column_null isn't reversible as one block
    end

    test "adds a unique attribute to every touchpoint" do
      run_add_field("new_unique:string:unique")
      assert_added_to_model(/validates :new_unique, uniqueness: true\n/)
      assert_added_to_model_test(/test_unique_fields\(.*?:new_unique.*?\)/)
      assert_match(/validates :existing_field, presence: true/, model_content)

      migration = migration_content(:new_unique)
      assert_match(/add_column :#{TABLE_NAME}, :new_unique, :string/, migration)
      assert_match(/add_index :#{TABLE_NAME}, :new_unique, unique: true/, migration)
      assert_match(/def change/, migration) # no backfill needed - plain `change` is fine
    end

    test "adds an enum field, including its constants and locale sub-blocks" do
      run_add_field("new_status:enum:keys=on,off")
      assert_added_to_model(/enum :new_status, Constants\..*?\.to_h.*?\n/)
      assert_added_to_model_test(/test_enum_field\(:new_status, prefix: true\)/)
      assert_match(/new_status:\n(\s+(on|off): \d\n)+/, constants_content)
      assert_match(/existing_status:\n(\s+(active|retired): \d\n)+/, constants_content) # sibling survives
      assert_match(/new_status: "New status"/i, locale_content("en"))
    end

    test "adds an enum_translated field, including the sibling pluralized locale block" do
      run_add_field("new_status_t:enum_translated:keys=red,blue")
      assert_added_to_model(/enum :new_status_t, Constants\..*?\.to_h.*?\n/)
      assert_added_to_model_test(/test_enum_translations\(.*?:new_status_t.*?\)/)
      locale = locale_content("en")
      assert_match(/new_status_t: "New status t"/i, locale)
      assert_match(/new_status_ts:\n(\s+(red|blue): "(Red|Blue)"\n)+/i, locale)
    end

    test "adds an optional reference field, including the migration's add_reference" do
      run_add_field("new_owner:references")
      assert_added_to_model(/belongs_to :new_owner, optional: true\n/)
      assert_added_to_model(/:new_owner\]/) # ransackable_associations
      assert_added_to_controller(/:new_owner_id\b/)
      assert_added_to_controller(/@new_owners = policy_scope\(NewOwner\)/)
      migration = migration_content(:new_owner)
      assert_match(/add_reference :#{TABLE_NAME}, :new_owner, null: true, foreign_key: true/, migration)
      refute_match(/change_column_null/, migration) # references never get a DB-level NOT NULL here
    end

    test "adds a required reference field without needing valid: - references never get a DB constraint" do
      run_add_field("new_owner_req:references:required")
      assert_added_to_model(/belongs_to :new_owner_req\n/) # no `, optional: true` - required
      migration = migration_content(:new_owner_req)
      assert_match(/add_reference :#{TABLE_NAME}, :new_owner_req, null: true, foreign_key: true/, migration)
      refute_match(/change_column_null/, migration)
    end

    test "adds a field to IMPORTABLE_ATTRIBUTES instead of the controller permit list, when present" do
      model_path = File.join(destination_root, "app", "models", "add_field_test_gizmo.rb")
      model_content_before = File.read(model_path)
      File.write(model_path, model_content_before.sub(
        "class AddFieldTestGizmo < ApplicationRecord\n",
        "class AddFieldTestGizmo < ApplicationRecord\n  IMPORTABLE_ATTRIBUTES = %i[existing_field existing_unique existing_status existing_owner_id].freeze\n"
      ))

      controller_path = File.join(destination_root, "app", "controllers", "#{TABLE_NAME}_controller.rb")
      controller_content_before = File.read(controller_path)
      File.write(controller_path, controller_content_before.sub(
        /def resource_params\s*\n\s*params\.require\(:add_field_test_gizmo\)\s*\n\s*\.permit\(.*?\)\s*\n\s*end/m,
        "def resource_params\n        params.require(:add_field_test_gizmo).permit(*AddFieldTestGizmo::IMPORTABLE_ATTRIBUTES)\n      end"
      ))
      refute_equal controller_content_before, File.read(controller_path), "the controller fixture rewrite didn't match"

      Object.const_get(CLASS_NAME).const_set(:IMPORTABLE_ATTRIBUTES, %i[existing_field existing_unique existing_status existing_owner_id].freeze)

      output = capture(:stdout) { run_add_field("new_field:string") }
      assert_match(/found\s+model_importable_attributes/, output)
      refute_match(/controller_permit/, output) # not even attempted - nothing to check there

      assert_match(/IMPORTABLE_ATTRIBUTES = %i\[existing_field existing_unique existing_status existing_owner_id new_field\]/, model_content)
      refute_match(/new_field/, controller_content)
    end

    # --- Precondition / abort tests ---

    test "aborts when the field already exists as a column" do
      assert_raises(Thor::Error) { run_add_field("existing_field:string") }
    end

    test "aborts when the field already exists as an association" do
      assert_raises(Thor::Error) { run_add_field("existing_owner:references") }
    end

    test "aborts on an invalid field spec" do
      assert_raises(Thor::Error) { run_add_field("new_field:not_a_real_type") }
    end

    test "aborts when required is given without valid for an attribute field" do
      snapshot = snapshot_all_files
      assert_raises(Thor::Error) { run_add_field("new_field:string:required") }
      assert_equal snapshot, snapshot_all_files, "the hard precondition must leave every file byte-for-byte unchanged"
    end

    test "aborts and changes nothing when a touchpoint was hand-edited since generation" do
      model_path = File.join(destination_root, "app", "models", "add_field_test_gizmo.rb")
      original = File.read(model_path)
      hand_edited = original.sub(
        "def self.ransackable_attributes(auth_object = nil)\n      [:existing_field, :existing_unique, :existing_status, :created_at, :updated_at]\n    end",
        "def self.ransackable_attributes(auth_object = nil)\n      %w[existing_field existing_unique existing_status created_at updated_at]\n    end"
      )
      refute_equal original, hand_edited, "the sub! didn't actually match - fixture text drifted"
      File.write(model_path, hand_edited)

      snapshot = snapshot_all_files

      assert_raises(Thor::Error) { run_add_field("new_field:string") }

      assert_equal snapshot, snapshot_all_files, "aborting must leave every file byte-for-byte unchanged"
    end

    test "--force inserts everywhere matchable and skips just what wasn't, leaving it untouched" do
      model_path = File.join(destination_root, "app", "models", "add_field_test_gizmo.rb")
      original = File.read(model_path)
      hand_edited = original.sub(
        "def self.ransackable_attributes(auth_object = nil)\n      [:existing_field, :existing_unique, :existing_status, :created_at, :updated_at]\n    end",
        "def self.ransackable_attributes(auth_object = nil)\n      %w[existing_field existing_unique existing_status created_at updated_at]\n    end"
      )
      File.write(model_path, hand_edited)

      output = capture(:stdout) { run_add_field("new_field:string", force: true) }
      assert_match(/warn.*could not be located/i, output)

      # The hand-edited ransackable_attributes line survives untouched...
      assert_match(/%w\[existing_field existing_unique existing_status created_at updated_at\]/, model_content)
      # ...but every other touchpoint for new_field was still added.
      assert_match(/:new_field\b/, controller_content)
    end

    test "reports every touchpoint, found or not, even on a clean run" do
      output = capture(:stdout) { run_add_field("new_field:string") }
      assert_match(/found/i, output)
    end

    # --- Round-trip invariant: add_field and remove_field must cancel out ---

    test "adding a field then removing it restores every file to its original content" do
      snapshot_before = snapshot_all_files

      run_add_field("new_field:string:unique")

      # remove_field's own discovery reflects on the live class, not text -
      # apply the migration's effect to the live table/model directly so it
      # sees exactly what the migration claims to have created, the same
      # way build_live_table_and_model sets up the base fixture.
      ActiveRecord::Base.connection.add_column(TABLE_NAME, :new_field, :string)
      ActiveRecord::Base.connection.add_index(TABLE_NAME, :new_field, unique: true)
      Object.const_get(CLASS_NAME).reset_column_information
      Object.const_get(CLASS_NAME).validates(:new_field, uniqueness: true)

      RemoveFieldGenerator.new([CLASS_NAME, "new_field"], {}, destination_root: destination_root).invoke_all

      snapshot_after = snapshot_all_files
      # Both steps create their own new, non-cancelling timestamped
      # migration file - excluded deliberately, not silently ignored.
      migrate_glob = File.join(destination_root, "db", "migrate", "*")
      snapshot_before_sans_migrations = snapshot_before.reject { |f, _| File.fnmatch?(migrate_glob, f) }
      snapshot_after_sans_migrations = snapshot_after.reject { |f, _| File.fnmatch?(migrate_glob, f) }

      assert_equal snapshot_before_sans_migrations, snapshot_after_sans_migrations
    end

    private

      # .start catches Thor::Error and exits cleanly (the right behavior
      # for the real CLI) - .new(...).invoke_all is the lower-level API
      # that actually propagates it, needed for testing abort paths (same
      # pattern remove_field_generator_test.rb already uses).
      def run_add_field(field_spec, force: false)
        AddFieldGenerator.new([CLASS_NAME, field_spec], { force: force }, destination_root: destination_root).invoke_all
      end

      def build_live_table_and_model
        drop_live_table_and_model
        ActiveRecord::Base.connection.create_table(TABLE_NAME.to_sym) do |t|
          t.string :existing_field
          t.string :existing_unique
          t.integer :existing_status
          t.references :existing_owner
          t.timestamps
        end
        model = Class.new(ApplicationRecord) do
          self.table_name = TABLE_NAME
          enum :existing_status, { active: 0, retired: 1 }, prefix: true
          belongs_to :existing_owner, class_name: "User", optional: true
          validates :existing_field, presence: true
          validates :existing_unique, uniqueness: true
        end
        Object.const_set(CLASS_NAME, model)
      end

      def drop_live_table_and_model
        Object.send(:remove_const, CLASS_NAME) if Object.const_defined?(CLASS_NAME)
        ActiveRecord::Base.connection.drop_table(TABLE_NAME, if_exists: true)
      end

      def model_content
        File.read(File.join(destination_root, "app", "models", "add_field_test_gizmo.rb"))
      end

      def controller_content
        File.read(File.join(destination_root, "app", "controllers", "#{TABLE_NAME}_controller.rb"))
      end

      def constants_content
        File.read(File.join(destination_root, "config", "constants", "core.yml"))
      end

      def locale_content(locale)
        File.read(File.join(destination_root, "config", "locales", "core", locale, "#{locale}.models.yml"))
      end

      def migration_content(field)
        path = Dir.glob(File.join(destination_root, "db", "migrate", "*_add_#{field}_to_#{TABLE_NAME}.rb")).first
        assert path, "no migration generated for adding #{field}"
        File.read(path)
      end

      def assert_added_to_model(pattern)
        assert_match(pattern, model_content)
      end

      def assert_added_to_controller(pattern)
        assert_match(pattern, controller_content)
      end

      def assert_added_to_factory(pattern)
        content = File.read(File.join(destination_root, "test", "factories", "#{TABLE_NAME}.rb"))
        assert_match(pattern, content)
      end

      def assert_added_to_model_test(pattern)
        content = File.read(File.join(destination_root, "test", "models", "add_field_test_gizmo_test.rb"))
        assert_match(pattern, content)
      end

      def assert_added_to_system_test(pattern)
        content = File.read(File.join(destination_root, "test", "system", "#{TABLE_NAME}_system_test.rb"))
        assert_match(pattern, content)
      end

      def assert_added_to_views(field)
        %w[_form.html.erb _header.html.erb _row.html.erb show.html.erb _card.html.erb].each do |view|
          content = File.read(File.join(destination_root, "app", "views", TABLE_NAME, view))
          assert_match(/:#{field}\b/, content, "expected #{field} to be present in #{view}")
        end
        # index.html.erb's own token always carries a _cont suffix (ransack's
        # "contains" predicate), so :field\b never matches there - :field_cont
        # does.
        index_content = File.read(File.join(destination_root, "app", "views", TABLE_NAME, "index.html.erb"))
        assert_match(/:#{field}_cont\b/, index_content, "expected #{field}_cont to be present in index.html.erb")
      end

      def snapshot_all_files
        Dir.glob(File.join(destination_root, "**", "*")).select { |f| File.file?(f) }.sort.to_h { |f| [f, File.read(f)] }
      end
  end
end
