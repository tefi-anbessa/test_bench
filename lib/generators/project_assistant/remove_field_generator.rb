require_relative "shared/scaffold_helper"
require_relative "shared/field_removal_helper"

module ProjectAssistant
  # Removes one field from an existing scaffold- or tagable-generated model,
  # reversing everything ScaffoldGenerator/TagableGenerator wrote for it -
  # see docs/DEVELOPER_NOTES.md or issue #54 for the full design rationale.
  #
  #   bin/rails g project_assistant:remove_field Electrical::Heater sheath_material [--force]
  #
  # Always checks every applicable touchpoint first and reports the
  # complete result before deciding anything - never aborts at the first
  # miss. By default, if any touchpoint didn't match exactly what the
  # generator would have produced (e.g. hand-edited since generation),
  # nothing is written and the full report explains why. --force removes
  # everything that did match and skips just what didn't, leaving those for
  # the developer to finish by hand.
  class RemoveFieldGenerator < Rails::Generators::NamedBase
    include Rails::Generators::ResourceHelpers
    include ProjectAssistant::Shared::ScaffoldHelper
    include ProjectAssistant::Shared::FieldRemovalHelper

    argument :field_name, type: :string, banner: "field_name"
    class_option :force, type: :boolean, default: false,
      desc: "Continue past touchpoints that can't be matched, skipping just those"

    # --- Phase 0: hard preconditions - --force has no effect on any of
    # these (see field_removal_helper.rb#discover_field and the plan notes
    # in issue #54): there's nothing to partially remove when the model or
    # field doesn't exist at all, or the model's nesting has evolved past
    # what this generator understands.
    def run_discover_field
      @namespaced = class_path.any?
      discover_field
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
          "You'll need to finish removing #{field_name.inspect} from them by hand.", :yellow
      else
        say_status :error, "#{missing.size} touchpoint(s) could not be located as the generator would have " \
          "written them (likely hand-edited since generation) - nothing has been changed. Fix the file(s) " \
          "above to match, or re-run with --force to skip just those.", :red
        raise Thor::Error, "Aborting generator"
      end
    end

    # --- Phase 2: nothing above has written anything. Only touchpoints
    # marked found get removed; everything else (not found, whether
    # optional or --force-skipped) is left untouched.
    def apply_removals
      @touchpoints.group_by { |tp| tp[:path] }.each do |path, tps|
        content = @file_contents[path]
        next if content.nil?

        applicable = tps.select { |tp| tp[:found] }
        next if applicable.empty?

        applicable.each { |tp| content = tp[:remove].call(content) }
        File.write(path, content) unless options[:pretend]
        say_status :update, "#{path.relative_path_from(Rails.root)}: removed #{field_name}", :green
      end
    end

    def create_removal_migration_file
      timestamp = Time.now.utc.strftime("%Y%m%d%H%M%S")
      migration_file = File.join(destination_root, "db", "migrate", "#{timestamp}_remove_#{field_name}_from_#{table_name}.rb")
      content = <<~RUBY
        class #{migration_class_name} < ActiveRecord::Migration[8.0]
          def change
        #{migration_body}
          end
        end
      RUBY
      create_file migration_file, content
      say_status :info, "Migration file #{migration_file.relative_path_from(Rails.root)} created. Review and run `bin/rails db:migrate`", :yellow
    end
  end
end
