# frozen_string_literal: true
# lib/generators/project_assistant/shared/import_helper.rb
#
# Content-generation helpers for retrofitting spreadsheet import (see
# app/services/import/base.rb and friends) onto a model. Deliberately kept
# separate from ScaffoldHelper's own large method set, and deliberately
# free of any generator instance state (no @ivars, no `options`) - every
# method here takes plain arguments and returns a value, so it can be
# called equally from ImportGenerator (retrofitting an existing model) and,
# later, from ScaffoldGenerator's own planned --include-import option
# (wiring import into a brand-new model at creation time). Only *content
# generation* lives here; *where* that content gets inserted into an
# existing file is retrofit-specific and lives in ImportGenerator itself.
module ProjectAssistant
  module Shared
    module ImportHelper
      # The registry key Import::Base.registered expects - slash-joined for
      # a namespaced model (model_class.name.underscore already preserves
      # "::" as "/"), so re-camelizing it resolves back to the real
      # namespaced constant. NOT the same string as the route helper
      # segment below - confirmed directly that a namespaced model's route
      # helper segment ("model_name.route_key", underscore-joined) and its
      # Import::Base registry key (slash-joined) are two different strings.
      def import_key_for(model_class)
        model_class.name.underscore.pluralize
      end

      def import_service_class_name_for(model_class)
        "Import::#{import_key_for(model_class).camelize}"
      end

      # Rails' own primitive for the (possibly namespaced) route helper
      # segment, e.g. "documents" for Document. Used to build
      # discipline_<route_key>_path/project_<route_key>_path.
      def import_route_key_for(model_class)
        model_class.model_name.route_key
      end

      # The has_many association on Discipline that points back at
      # model_class - e.g. Discipline#documents for Document. Never guessed
      # from the model's own name (a namespaced model's association name
      # doesn't necessarily match its own pluralized name).
      def import_discipline_association_for(model_class)
        Discipline.reflect_on_all_associations(:has_many).find do |assoc|
          assoc.klass == model_class
        rescue StandardError
          false
        end
      end

      # model_class's own belongs_to association to Discipline - gives both
      # the association name and (via .foreign_key) the real FK column name,
      # again never assumed to literally be "discipline"/"discipline_id".
      def import_model_discipline_reflection_for(model_class)
        model_class.reflect_on_all_associations(:belongs_to).find { |assoc| assoc.klass == Discipline }
      end

      # Best-effort union of every params.require(...).permit(...) call's
      # attribute list found in a controller's source. Used only to *suggest*
      # IMPORTABLE_ATTRIBUTES and to intersect against for the column_definitions
      # stub - never written to a file automatically (see ImportGenerator).
      def import_permitted_attributes_from(controller_source)
        controller_source.scan(/\.permit\(([^)]*)\)/m).flatten.flat_map do |args|
          args.split(",").filter_map do |arg|
            name = arg.strip.delete_prefix(":")
            name.presence&.to_sym
          end
        end.uniq
      end

      # A best-effort column_definitions stub: model_class's own columns,
      # excluding id/timestamps/any foreign key (foreign keys are resolved
      # separately, not plain-mapped columns), intersected with whatever the
      # host controller's own strong params already allow - this is what
      # correctly excludes a server-computed column (e.g. a serial number)
      # that happens to still be a plain, non-FK column, without needing to
      # special-case attr_readonly.
      def import_column_stub_for(model_class, permitted_attributes:)
        model_class.columns
          .reject { |c| %w[id created_at updated_at].include?(c.name) }
          .reject { |c| c.name.end_with?("_id") }
          .select { |c| permitted_attributes.include?(c.name.to_sym) }
          .map do |c|
            { key: c.name.to_sym, label: c.name.humanize, required: !c.null && c.default.nil? }
          end
      end

      # Any foreign key column other than the discipline one - flagged as a
      # manual TODO (see ImportGenerator), never auto-resolved, since that
      # needs natural-key semantics this generator can't guess.
      def import_non_discipline_fks_for(model_class, discipline_fk:)
        model_class.columns
          .select { |c| c.name.end_with?("_id") && c.name != discipline_fk.to_s }
          .map(&:name)
      end

      def import_locale_values_for(human_name_plural:)
        {
          title: "Import #{human_name_plural}",
          header_discipline: "Import #{human_name_plural} into %{discipline}",
          header_project: "Import #{human_name_plural} into %{project}"
        }
      end
    end
  end
end
