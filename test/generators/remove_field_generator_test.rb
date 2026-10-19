# frozen_string_literal: true
require "test_helper"
require Rails.root.join("lib", "generators", "project_assistant", "scaffold_generator").to_s
require Rails.root.join("lib", "generators", "project_assistant", "remove_field_generator").to_s

module ProjectAssistant
  class RemoveFieldGeneratorTest < Rails::Generators::TestCase
    tests ProjectAssistant::RemoveFieldGenerator
    destination Rails.root.join("tmp", "generators", "remove_field")
    setup :prepare_destination

    TABLE_NAME = "remove_field_test_gizmos"
    CLASS_NAME = "RemoveFieldTestGizmo"

    setup do
      # Realistic generated text for every non-model-discovery touchpoint
      # comes from actually running ScaffoldGenerator against the sandbox -
      # same approach scaffold_generator_test.rb already uses for its own
      # fixtures. Discovery itself (RemoveFieldGenerator#discover_field)
      # never reads this text - it reflects on a real, live model class
      # instead (see build_live_model below), which sidesteps needing the
      # real app's Constants module to know about a throwaway test model's
      # enum values.
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
           "plain_field:string:required=true",
           "unique_field:string:unique=true",
           "status:enum:keys=active,retired",
           "owner:references",
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

    test "removes a plain required attribute from every touchpoint" do
      run_remove_field("plain_field")
      assert_removed_from_model(/validates :plain_field, presence: true\n/)
      assert_removed_from_model(/:plain_field\b/)
      assert_removed_from_controller(/:plain_field\b/)
      assert_removed_from_views("plain_field")
      assert_removed_from_factory(/plain_field \{.*?\}\n/)
      assert_removed_from_model_test(/test_required_fields\(.*?:plain_field.*?\)/)
      assert_removed_from_system_test(/:plain_field\b/)

      # Surgical, not a wipe: a sibling field's own content must survive.
      assert_match(/:unique_field\b/, model_content)
      assert_match(/:unique_field\b/, controller_content)
      assert_match(/validates :unique_field, uniqueness: true/, model_content)
      assert_migration_created(:plain_field, column_type: :string)
    end

    test "removes a unique attribute from every touchpoint" do
      run_remove_field("unique_field")
      assert_removed_from_model(/validates :unique_field, uniqueness: true\n/)
      assert_removed_from_model_test(/test_unique_fields\(.*?:unique_field.*?\)/)
      assert_match(/validates :plain_field, presence: true/, model_content)
    end

    test "removes an enum field, including its constants and locale sub-blocks" do
      run_remove_field("status")
      assert_removed_from_model(/enum :status, Constants\..*?\.to_h.*?\n/)
      assert_removed_from_model_test(/test_enum_field\(:status, prefix: true\)/)
      refute_match(/status:\n(\s+(active|retired): \d\n)+/, constants_content)
      assert_match(/plain_field: "Plain field"/i, locale_content("en")) # sibling survives
    end

    test "removes a reference field, including the migration's remove_reference" do
      run_remove_field("owner")
      assert_removed_from_model(/belongs_to :owner(?:, optional: true)?\n/)
      assert_removed_from_model(/:owner\]/) # ransackable_associations
      assert_removed_from_controller(/:owner_id\b/)
      assert_removed_from_controller(/@owners = policy_scope\(Owner\)/)
      migration = migration_content(:owner)
      assert_match(/remove_reference :#{TABLE_NAME}, :owner, foreign_key: true/, migration)
    end

    test "removing a hash's last key preserves the closing brace's own line and indentation" do
      # "owner" is deliberately the last field in the scaffold args below,
      # so it's also the last key in controller_test's create_params hash -
      # hash_key_token's value-match must stop at the newline rather than
      # greedily consuming it along with the key, or the closing brace gets
      # dragged up onto the previous line (see issue #4's add_field work,
      # which surfaced this as a pre-existing bug here).
      run_remove_field("owner")
      assert_match(/status: "active"\n[ \t]*\}\n/, controller_test_content)
    end

    test "removes a field from IMPORTABLE_ATTRIBUTES instead of the controller permit list, when present" do
      # Mirrors the real Tag/Electrical::Motor shape: the permit list moves
      # out of the controller into a model constant shared with an
      # Import:: service - applied by hand after running the import
      # generator (see field_removal_helper.rb's own comment), not
      # something ScaffoldGenerator produces on its own.
      model_path = File.join(destination_root, "app", "models", "remove_field_test_gizmo.rb")
      model_content_before = File.read(model_path)
      File.write(model_path, model_content_before.sub(
        "class RemoveFieldTestGizmo < ApplicationRecord\n",
        "class RemoveFieldTestGizmo < ApplicationRecord\n  IMPORTABLE_ATTRIBUTES = %i[plain_field unique_field status owner_id].freeze\n"
      ))

      controller_path = File.join(destination_root, "app", "controllers", "#{TABLE_NAME}_controller.rb")
      controller_content_before = File.read(controller_path)
      File.write(controller_path, controller_content_before.sub(
        /def resource_params\s*\n\s*params\.require\(:remove_field_test_gizmo\)\s*\n\s*\.permit\(.*?\)\s*\n\s*end/m,
        "def resource_params\n        params.require(:remove_field_test_gizmo).permit(*RemoveFieldTestGizmo::IMPORTABLE_ATTRIBUTES)\n      end"
      ))
      refute_equal controller_content_before, File.read(controller_path), "the controller fixture rewrite didn't match"

      # discover_field reflects on the live class, not this text fixture -
      # it needs the same fact asserted directly, same as build_live_table_and_model
      # does for every other discovery fact.
      Object.const_get(CLASS_NAME).const_set(:IMPORTABLE_ATTRIBUTES, %i[plain_field unique_field status owner_id].freeze)

      output = capture(:stdout) { run_remove_field("plain_field") }
      assert_match(/found\s+model_importable_attributes/, output)
      refute_match(/controller_permit/, output) # not even attempted - nothing to check there

      refute_match(/plain_field/, model_content)
      assert_match(/IMPORTABLE_ATTRIBUTES = %i\[unique_field status owner_id\]/, model_content)
      # The controller's own permit call is untouched - it only ever
      # referenced the constant, never the field directly.
      assert_match(/permit\(\*RemoveFieldTestGizmo::IMPORTABLE_ATTRIBUTES\)/, controller_content)
    end

    # --- Abort / --force behavior ---

    test "aborts and changes nothing when a touchpoint was hand-edited since generation" do
      model_path = File.join(destination_root, "app", "models", "remove_field_test_gizmo.rb")
      original = File.read(model_path)
      hand_edited = original.sub(
        "def self.ransackable_attributes(auth_object = nil)\n      [:plain_field, :unique_field, :status, :created_at, :updated_at]\n    end",
        "def self.ransackable_attributes(auth_object = nil)\n      %w[plain_field unique_field status created_at updated_at]\n    end"
      )
      refute_equal original, hand_edited, "the sub! didn't actually match - fixture text drifted"
      File.write(model_path, hand_edited)

      snapshot = snapshot_all_files

      assert_raises(Thor::Error) { run_remove_field("plain_field") }

      assert_equal snapshot, snapshot_all_files, "aborting must leave every file byte-for-byte unchanged"
    end

    test "--force removes everything matchable and skips just what wasn't, leaving it untouched" do
      model_path = File.join(destination_root, "app", "models", "remove_field_test_gizmo.rb")
      original = File.read(model_path)
      hand_edited = original.sub(
        "def self.ransackable_attributes(auth_object = nil)\n      [:plain_field, :unique_field, :status, :created_at, :updated_at]\n    end",
        "def self.ransackable_attributes(auth_object = nil)\n      %w[plain_field unique_field status created_at updated_at]\n    end"
      )
      File.write(model_path, hand_edited)

      output = capture(:stdout) { run_remove_field("plain_field", force: true) }
      assert_match(/warn.*could not be located/i, output)

      # The hand-edited ransackable_attributes line survives untouched...
      assert_match(/%w\[plain_field unique_field status created_at updated_at\]/, model_content)
      # ...but every other touchpoint for plain_field was still removed.
      refute_match(/validates :plain_field, presence: true/, model_content)
      refute_match(/:plain_field\b/, controller_content)
    end

    test "reports every touchpoint, found or not, even on a clean run" do
      output = capture(:stdout) { run_remove_field("plain_field") }
      assert_match(/found/i, output)
      assert_match(/model_validates_presence/, output)
    end

    private

      # .start catches Thor::Error and exits cleanly (the right behavior
      # for the real CLI) - .new(...).invoke_all is the lower-level API
      # that actually propagates it, which is what testing an abort path
      # needs (same pattern scaffold_generator_test.rb already uses for
      # its own Thor::Error assertions).
      def run_remove_field(field, force: false)
        RemoveFieldGenerator.new([CLASS_NAME, field], { force: force }, destination_root: destination_root).invoke_all
      end

      def build_live_table_and_model
        drop_live_table_and_model
        ActiveRecord::Base.connection.create_table(TABLE_NAME.to_sym) do |t|
          t.string :plain_field
          t.string :unique_field
          t.integer :status
          t.references :owner
          t.timestamps
        end
        model = Class.new(ApplicationRecord) do
          self.table_name = TABLE_NAME
          enum :status, { active: 0, retired: 1 }, prefix: true
          belongs_to :owner, class_name: "User", optional: true
          validates :plain_field, presence: true
          validates :unique_field, uniqueness: true
        end
        Object.const_set(CLASS_NAME, model)
      end

      def drop_live_table_and_model
        Object.send(:remove_const, CLASS_NAME) if Object.const_defined?(CLASS_NAME)
        ActiveRecord::Base.connection.drop_table(TABLE_NAME, if_exists: true)
      end

      def model_content
        File.read(File.join(destination_root, "app", "models", "remove_field_test_gizmo.rb"))
      end

      def controller_content
        File.read(File.join(destination_root, "app", "controllers", "#{TABLE_NAME}_controller.rb"))
      end

      def controller_test_content
        File.read(File.join(destination_root, "test", "controllers", "#{TABLE_NAME}_controller_test.rb"))
      end

      def constants_content
        File.read(File.join(destination_root, "config", "constants", "core.yml"))
      end

      def locale_content(locale)
        File.read(File.join(destination_root, "config", "locales", "core", locale, "#{locale}.models.yml"))
      end

      def migration_content(field)
        path = Dir.glob(File.join(destination_root, "db", "migrate", "*_remove_#{field}_from_#{TABLE_NAME}.rb")).first
        assert path, "no migration generated for removing #{field}"
        File.read(path)
      end

      def assert_migration_created(field, column_type:)
        content = migration_content(field)
        assert_match(/remove_column :#{TABLE_NAME}, :#{field}, :#{column_type}/, content)
      end

      def assert_removed_from_model(pattern)
        refute_match(pattern, model_content)
      end

      def assert_removed_from_controller(pattern)
        refute_match(pattern, controller_content)
      end

      def assert_removed_from_factory(pattern)
        content = File.read(File.join(destination_root, "test", "factories", "#{TABLE_NAME}.rb"))
        refute_match(pattern, content)
      end

      def assert_removed_from_model_test(pattern)
        content = File.read(File.join(destination_root, "test", "models", "remove_field_test_gizmo_test.rb"))
        refute_match(pattern, content)
      end

      def assert_removed_from_system_test(pattern)
        content = File.read(File.join(destination_root, "test", "system", "#{TABLE_NAME}_system_test.rb"))
        refute_match(pattern, content)
      end

      def assert_removed_from_views(field)
        %w[_form.html.erb index.html.erb _header.html.erb _row.html.erb show.html.erb _card.html.erb].each do |view|
          content = File.read(File.join(destination_root, "app", "views", TABLE_NAME, view))
          refute_match(/:#{field}\b/, content, "expected #{field} to be gone from #{view}")
        end
      end

      def snapshot_all_files
        Dir.glob(File.join(destination_root, "**", "*")).select { |f| File.file?(f) }.sort.to_h { |f| [f, File.read(f)] }
      end
  end
end
