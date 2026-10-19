require_relative "shared/scaffold_helper"
require_relative "shared/field_addition_helper"

module ProjectAssistant
  # Adds one field to an existing scaffold- or tagable-generated model,
  # writing everything ScaffoldGenerator/TagableGenerator would have
  # written for it, had it been there from the start - see
  # docs/GENERATORS.md or issue #4 for the full design rationale. The
  # mirror image of RemoveFieldGenerator: where that one locates existing
  # content and deletes it, this one locates a stable insertion point and
  # writes new content.
  #
  #   bin/rails g project_assistant:add_field Electrical::Heater sheath_material:string:required:valid=steel [--force]
  #
  # field_spec uses the same name:type[:option=value]... grammar as the
  # scaffold generator's own CLI fields.
  #
  # Always checks every applicable insertion point first and reports the
  # complete result before deciding anything - never aborts at the first
  # miss. By default, if any insertion point couldn't be found (e.g. a
  # file was hand-edited since generation in a way that moved or removed
  # the anchor this generator looks for), nothing is written and the full
  # report explains why. --force inserts everything that did match and
  # skips just what didn't, leaving those for the developer to finish by
  # hand.
  #
  # A required field's migration never invents a backfill value - see
  # field_addition_helper.rb#validate_field_addition - required: without
  # valid: is a hard validation failure, not a --force-skippable touchpoint
  # miss, same as the field already existing or the spec being malformed.
  class AddFieldGenerator < Rails::Generators::NamedBase
    include Rails::Generators::ResourceHelpers
    include ProjectAssistant::Shared::ScaffoldHelper
    include ProjectAssistant::Shared::FieldAdditionHelper

    argument :field_spec, type: :string, banner: "name:type[:option=value]..."
    class_option :force, type: :boolean, default: false,
      desc: "Continue past insertion points that can't be matched, skipping just those"

    # --- Phase 0: hard preconditions - --force has no effect on any of
    # these: there's nothing to partially add when the model doesn't
    # exist, the field already exists, the field spec is invalid, or a
    # required field has no backfill value to work with.
    def run_validate_field_addition
      validate_field_addition
    end

    # --- Phase 1: build the registry, then verify every entry against the
    # real files - never short-circuits on the first miss.
    def build_touchpoint_registry
      @touchpoints = []
      @touchpoints.concat(model_touchpoints)
      @touchpoints.concat(controller_touchpoints)
      @touchpoints.concat(view_touchpoints)
      @touchpoints.concat(factory_touchpoints)
      @touchpoints.concat(model_test_touchpoints)
      @touchpoints.concat(system_test_touchpoints)
      @touchpoints.concat(controller_test_touchpoints)
      @touchpoints.concat(constants_touchpoints)
      @touchpoints.concat(locale_touchpoints)
    end

    def locate_touchpoints
      @file_contents = {}
      @touchpoints.each do |tp|
        content = @file_contents.fetch(tp[:path]) {
          @file_contents[tp[:path]] = File.exist?(tp[:path]) ? File.read(tp[:path]) : nil
        }
        tp[:found] = content.nil? ? false : !!tp[:locate].call(content)
      end
    end

    # --- Gate: print the complete report, then abort here (writing
    # nothing) unless every touchpoint was found or --force was given.
    def check_report!
      @touchpoints.each do |tp|
        label = "#{tp[:key]} (#{tp[:path].relative_path_from(Rails.root)})"
        if tp[:found]
          say_status :found, label, :green
        elsif tp[:optional]
          say_status :"not found", "#{label} - optional, not applicable here", :blue
        else
          say_status :MISSING, label, :red
        end
      end

      missing = @touchpoints.reject { |tp| tp[:found] || tp[:optional] }
      return if missing.empty?

      if options[:force]
        say_status :warn, "#{missing.size} touchpoint(s) could not be located - skipping those, per --force. " \
          "You'll need to finish adding #{field_name.inspect} to them by hand.", :yellow
      else
        say_status :error, "#{missing.size} touchpoint(s) could not be located where the generator expects " \
          "(likely hand-edited since generation) - nothing has been changed. Fix the file(s) above to match, " \
          "or re-run with --force to skip just those.", :red
        raise Thor::Error, "Aborting generator"
      end
    end

    # --- Phase 2: nothing above has written anything. Only touchpoints
    # marked found get inserted into; everything else (--force-skipped) is
    # left untouched.
    def apply_insertions
      @touchpoints.group_by { |tp| tp[:path] }.each do |path, tps|
        content = @file_contents[path]
        next if content.nil?

        applicable = tps.select { |tp| tp[:found] }
        next if applicable.empty?

        applicable.each { |tp| content = tp[:insert].call(content) }
        File.write(path, content) unless options[:pretend]
        say_status :update, "#{path.relative_path_from(Rails.root)}: added #{field_name}", :green
      end
    end

    def create_addition_migration_file
      timestamp = Time.now.utc.strftime("%Y%m%d%H%M%S")
      migration_file = File.join(destination_root, "db", "migrate", "#{timestamp}_add_#{field_name}_to_#{table_name}.rb")
      # execute + change_column_null isn't safely reversible as a single
      # `change` block - matches the real hand-written precedent
      # (db/migrate/20251027005729_add_project_to_discipline.rb).
      content =
        if migration_requires_backfill?
          <<~RUBY
            class #{migration_class_name} < ActiveRecord::Migration[8.0]
              def up
            #{migration_body}
              end

              def down
                remove_column :#{table_name}, :#{field_name}
              end
            end
          RUBY
        else
          <<~RUBY
            class #{migration_class_name} < ActiveRecord::Migration[8.0]
              def change
            #{migration_body}
              end
            end
          RUBY
        end
      create_file migration_file, content
      say_status :info, "Migration file #{Pathname.new(migration_file).relative_path_from(Rails.root)} created. Review and run `bin/rails db:migrate`", :yellow
    end
  end
end
