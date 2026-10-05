# frozen_string_literal: true
# lib/generators/project_assistant/import_generator.rb
#
# Retrofits spreadsheet import (see app/services/import/base.rb and friends)
# onto an existing, already-scaffolded model, e.g.:
#   bin/rails g project_assistant:import Document
#
# Different job from ScaffoldGenerator (which creates a brand-new model from
# a field list): this generator only ever touches a model that already
# exists. See /Users/frank/.claude/plans/silly-questing-cerf.md for the full
# design rationale.
require "rails/generators/named_base"
require_relative "shared/scaffold_helper"
require_relative "shared/import_helper"

module ProjectAssistant
  class ImportGenerator < Rails::Generators::NamedBase
    include Rails::Generators::ResourceHelpers
    include ProjectAssistant::Shared::ScaffoldHelper
    include ProjectAssistant::Shared::ImportHelper
    source_root File.expand_path("import/templates", __dir__)

    # The fixture/system test's shared placeholder tag reference for
    # --tagable mode - "TAG" + 4-digit-padded serial "0001" (confirmed:
    # Constants.tag.serial_digits is 4), matching how
    # tagable_system_test.rb.erb seeds its own @unassigned_tag
    # (prefix: "TAG", serial: 1, suffix: "").
    TAGABLE_FIXTURE_TAG = "TAG0001"

    class_option :discipline_association, type: :string, default: nil,
      desc: "Override the Discipline has_many association name, if reflection can't resolve it"
    class_option :nesting, type: :string, default: "project,discipline",
      desc: "Comma-separated route contexts to retrofit: project, discipline, or both"
    class_option :tagable, type: :boolean, default: false,
      desc: "Target is a tagable model (includes Tagable, no policy of its own - authorization " \
        "routes through TagPolicy via its tag association) - attaches to an " \
        "existing, unassigned Tag by natural key instead of resolving a discipline_id column. " \
        "Controller/routes are shared (TagablesController) and never generated/injected."

    def validate_model
      errors = []
      @model_class = class_name.safe_constantize
      errors << "#{class_name} is not a known class - is it spelled/namespaced correctly?" if @model_class.nil?
      errors << "#{class_name} is not an ActiveRecord model" if @model_class && !(@model_class < ActiveRecord::Base)
      abort_with(errors) if errors.any?
    end

    def validate_policy
      # class_name, not model_class_name: the latter is only the leaf name
      # (e.g. "Motor"), which resolves a bare top-level MotorPolicy - wrong
      # for a namespaced model, whose real policy is Electrical::MotorPolicy.
      # Confirmed the hard way: this originally reported "MotorPolicy does
      # not exist" for Electrical::Motor even though Electrical::MotorPolicy
      # was never checked at all.
      errors = []
      if tagable?
        # Tagable models have no policy of their own - authorization always
        # routes through TagPolicy via the model's own `tag` association
        # (see app/policies/tag_policy.rb), so there's no policy class to
        # check here at all, only that the model really is tagable.
        errors << "#{class_name} does not include Tagable, but --tagable was given." unless model_class.include?(Tagable)
      else
        @policy_class = policy_class_name.safe_constantize
        errors << "#{policy_class_name} does not exist" if @policy_class.nil?
        if @policy_class && !(@policy_class < DisciplineResourcePolicy)
          errors << "#{policy_class_name} does not inherit from DisciplineResourcePolicy - " \
            "this generator only supports that convention (see app/policies/discipline_resource_policy.rb#import?), " \
            "or --tagable for a model whose authorization routes through TagPolicy instead."
        end
      end
      abort_with(errors)
    end

    def validate_discipline_association
      if tagable?
        say_status :info, "--tagable: skipping discipline-association reflection - every tagable attaches to a Tag directly", :green
        return
      end

      if options[:discipline_association].present?
        @discipline_association = options[:discipline_association].to_sym
        return
      end

      reflection = import_discipline_association_for(model_class)
      errors = []
      errors << "Could not find a has_many association on Discipline pointing at #{model_class}. " \
        "Pass --discipline-association=<name> to override." if reflection.nil?
      abort_with(errors)
      @discipline_association = reflection.name
    end

    def validate_controller
      if tagable?
        say_status :info, "--tagable: skipping controller validation - every tagable shares TagablesController, already wired for import", :green
        return
      end

      errors = []
      unless File.exist?(controller_path)
        errors << "#{controller_path.relative_path_from(destination_root_pathname)} not found"
      end
      if File.exist?(controller_path) && File.read(controller_path).include?("include Importable")
        errors << "#{controller_class_name}Controller already includes Importable - has import already been added?"
      end
      abort_with(errors)
    end

    def validate_routes
      if tagable?
        say_status :info, "--tagable: skipping route validation - the shared tagables import route already exists", :green
        return
      end

      errors = []
      route_contexts.each do |context|
        section = routes_section(context)
        if section.nil?
          errors << "Could not find the #{context} nested routes section in config/routes.rb"
          next
        end
        _, matched = rewrite_routes_section(section, import_route_key)
        errors << "config/routes.rb: no recognized `resources :#{import_route_key}` shape found in the " \
          "#{context} nested routes section - add it by hand" unless matched
      end
      abort_with(errors)
    end

    def create_importer_service
      @column_stub = import_column_stub_for(model_class, permitted_attributes: permitted_attributes_suggestion)
      @non_discipline_fks = tagable? ? import_non_discipline_fks_for(model_class, discipline_fk: nil) : import_non_discipline_fks_for(model_class, discipline_fk: discipline_fk)
      template tagable? ? "tagable_service.rb.erb" : "service.rb.erb", File.join("app", "services", "import", "#{import_key}.rb")
    end

    def create_view_file
      template tagable? ? "tagable_view.html.erb" : "view.html.erb", File.join("app", "views", controller_file_path, "import.html.erb")
    end

    def create_fixture_and_tests
      fixture_headers = tagable? ? ["Tag"] + required_headers : required_headers
      fixture_values = tagable? ? [TAGABLE_FIXTURE_TAG] + required_values : required_values
      create_file File.join("test", "fixtures", "files", "import", "#{import_route_key}.csv"),
        "#{fixture_headers.join(",")}\n#{fixture_values.join(",")}\n"

      if tagable?
        template "tagable_service_test.rb.erb", File.join("test", "services", "import", "#{import_key}_test.rb")
        template "tagable_controller_test.rb.erb", File.join("test", "controllers", "#{controller_file_path}_import_test.rb")
        template "tagable_system_test.rb.erb", File.join("test", "system", "#{controller_file_path}_import_system_test.rb")
      else
        template "service_test.rb.erb", File.join("test", "services", "import", "#{import_key}_test.rb")
        template "controller_test.rb.erb", File.join("test", "controllers", "#{controller_file_path}_import_test.rb")
        template "system_test.rb.erb", File.join("test", "system", "#{controller_file_path}_import_system_test.rb")
      end
    end

    def inject_controller
      if tagable?
        say_status :info, "--tagable: skipping controller injection - TagablesController already has import/create_import wired in", :green
        return
      end
      # IMPORTANT: registering the same before_action method name twice with
      # different :only lists does NOT add a second independent filter -
      # Rails' callback system replaces the earlier registration entirely,
      # so only the LAST registration's :only condition ever takes effect.
      # Confirmed directly with a throwaway controller test (a method
      # registered under only: %i[a] then again under only: %i[b] never ran
      # for :a, only for :b). So each of these methods' *existing*
      # before_action call must be extended in place, not duplicated.
      unless options[:pretend]
        content = File.read(controller_path)
        content.sub!(/^(\s*)(class #{Regexp.escape(controller_class_name)}Controller\b.*\n)/) { "#{$1}#{$2}#{$1}  include Importable\n\n" }

        fresh_lines = []
        %w[require_project! set_discipline set_swatch].each do |method|
          content, extended = extend_before_action(content, method)
          fresh_lines << "before_action :#{method}, only: %i[import create_import]\n" unless extended
        end
        unless fresh_lines.empty?
          content.sub!(/^(\s*)(class #{Regexp.escape(controller_class_name)}Controller\b.*\n\s*include Importable\n\n)/) { "#{$1}#{$2}#{pad_lines(fresh_lines.join, "#{$1}  ")}" }
        end
        File.write(controller_path, content)
      end
      say_status :inject, "#{controller_path.relative_path_from(destination_root_pathname)}: added Importable + before_actions", :green

      private_methods = <<~RUBY

          # === Importable concern hooks (see app/controllers/concerns/importable.rb) ===

          def importer_key
            "#{import_key}"
          end

          def authorize_import!
            authorize @discipline.#{discipline_association}.build, :import? if @discipline.present?
          end
      RUBY
      private_methods = pad_lines(private_methods, "    ")
      unless options[:pretend]
        content = File.read(controller_path)
        content.sub!(/\n(\s*)end\s*\z/) { "\n#{private_methods}#{$1}end\n" }
        File.write(controller_path, content)
      end
      say_status :inject, "#{controller_path.relative_path_from(destination_root_pathname)}: added importer_key/authorize_import!", :green
    end

    def inject_routes
      if tagable?
        say_status :info, "--tagable: skipping route injection - the shared tagables import route already exists", :green
        return
      end
      return if options[:pretend]

      content = File.read(routes_path)
      route_contexts.each do |ctx|
        section = routes_section(content, ctx)
        rewritten, matched = rewrite_routes_section(section, import_route_key)
        next unless matched
        content = content.sub(section) { rewritten }
      end
      File.write(routes_path, content)
      say_status :inject, "config/routes.rb: added import routes for #{route_contexts.join(', ')} nesting", :green
    end

    def inject_locales
      values = import_locale_values_for(human_name_plural: human_name.pluralize)
      I18n.available_locales.each do |locale|
        file = i18n_views_file(locale)
        next unless File.exist?(file)

        # [ \t]*, not \s* (which also matches \n): this locale file's own
        # sections are separated by blank lines (electrical's own, unlike
        # core's) - \s* greedily captured the *preceding* blank line as
        # "indentation" (confirmed directly - base_indent came back as
        # "\n    ", not "    "), which then prefixed every injected line
        # with a stray extra newline. [ \t]* only ever matches the current
        # line's own leading whitespace, regardless of what precedes it.
        anchor = /^([ \t]*)#{Regexp.escape(plural_name)}:[ \t]*\n/
        content = File.read(file)
        unless content.match?(anchor)
          say_status :error, "#{file.relative_path_from(destination_root_pathname)}: could not find `#{plural_name}:` key - add the import: block by hand", :red
          next
        end

        base_indent = content.match(anchor)[1]
        # A tagable import is always discipline-scoped (no project-wide
        # variant - see Import::TagableBase), so only one header string is
        # needed, unlike a plain discipline-resource importer's two.
        if tagable?
          block = <<~YAML
            import:
              title:   "#{values[:title]}"
              header:  "#{values[:header_discipline]}"
          YAML
        else
          block = <<~YAML
            import:
              title:              "#{values[:title]}"
              header_discipline:  "#{values[:header_discipline]}"
              header_project:     "#{values[:header_project]}"
          YAML
        end
        block = pad_lines(block, "#{base_indent}  ")
        content.sub!(anchor) { "#{$&}#{block}" } unless options[:pretend]
        File.write(file, content) unless options[:pretend]
        say_status :inject, "#{file.relative_path_from(destination_root_pathname)}: added #{singular_name}.import.* keys", :green
      end
    end

    def inject_index_view_button
      view_path = File.join(destination_root, "app", "views", controller_file_path, "index.html.erb")
      unless File.exist?(view_path)
        say_status :error, "#{controller_file_path}/index.html.erb not found - add the Import button by hand", :red
        return
      end

      content = File.read(view_path)
      # The div class varies (discipline-resource index views use
      # "col-2 align-content-end"; tagable ones use "col-2 text-end" -
      # confirmed directly) - captured and reused as-is rather than
      # hardcoded, so this never silently changes an unrelated class.
      anchor = /(<!-- New Button \(Right\) -->\s*\n\s*<div class="(col-2[^"]*)">\s*\n\s*<% if @discipline\.present\? && policy\((.*?)\)\.new\? %>\s*\n\s*(<%= nav_button\(action: :new,.*?%>)\s*\n\s*<% end %>\s*\n\s*<\/div>)/m
      match = content.match(anchor)
      unless match
        say_status :info, "#{controller_file_path}/index.html.erb: New Button (Right) anchor not found - " \
          "add the Import button by hand (see app/views/tags/index.html.erb for the pattern), or it was added already", :yellow
        return
      end

      div_class = match[2]
      new_record_probe = match[3]
      new_button_line = match[4]
      if tagable?
        replacement = <<~ERB
          <!-- New / Import Buttons (Right) -->
                  <div class="#{div_class}">
                    <% if @discipline.present? %>
                      <% if policy(#{new_record_probe}).new? %>
                        #{new_button_line}
                      <% end %>
                      <% if policy(#{new_record_probe}).import? %>
                        <%= nav_button(action: :import, path: import_discipline_tagables_path(@discipline, tagable_type: "#{class_name}"), record: #{class_name}.new) %>
                      <% end %>
                    <% end %>
                  </div>
        ERB
      else
        replacement = <<~ERB
          <!-- New / Import Buttons (Right) -->
                  <div class="#{div_class}">
                    <% if @discipline.present? %>
                      <% if policy(#{new_record_probe}).new? %>
                        #{new_button_line}
                      <% end %>
                      <% if policy(#{new_record_probe}).import? %>
                        <%= nav_button(action: :import, path: import_discipline_#{import_route_key}_path(@discipline), record: #{class_name}.new) %>
                      <% end %>
                    <% elsif @project.present? && policy(#{class_name}).import? %>
                      <%= nav_button(action: :import, path: import_project_#{import_route_key}_path(@project), record: #{class_name}.new) %>
                    <% end %>
                  </div>
        ERB
      end
      content = content.sub(anchor) { replacement.rstrip }
      File.write(view_path, content) unless options[:pretend]
      say_status :inject, "#{controller_file_path}/index.html.erb: added Import button", :green
    end

    def print_manual_todo_summary
      say_status :info, "---- Manual follow-up needed ----", :yellow
      suggested_attributes = tagable? ? permitted_attributes_suggestion : ([discipline_fk] + permitted_attributes_suggestion).uniq
      source = tagable? ? "#{extension_class_name}#tagable_params" : "#{controller_class_name}Controller's own permit lists"
      say_status :info, "Add this constant to #{class_name} (suggested from #{source}):", :yellow
      say_status :info, "  IMPORTABLE_ATTRIBUTES = %i[#{suggested_attributes.join(' ')}].freeze", :yellow
      if @non_discipline_fks.any?
        say_status :info, "Not resolved by the generated importer - needs case-by-case judgement: #{@non_discipline_fks.join(', ')}", :yellow
      end
      say_status :info, "Review app/services/import/#{import_key}.rb's #{tagable? ? "own_" : ""}column_definitions - see its own REVIEW REQUIRED comment.", :yellow
    end

    private

    def model_class = @model_class
    def discipline_association = @discipline_association
    def discipline_fk = import_model_discipline_reflection_for(model_class)&.foreign_key&.to_sym || :discipline_id
    def import_key = import_key_for(model_class)
    def import_route_key = import_route_key_for(model_class)
    # Fully-qualified plural class name, e.g. "Electrical::Motors" or
    # "Documents" - confirmed directly that ActiveSupport's #pluralize
    # correctly pluralizes only the last segment of a namespaced string, so
    # this is safe to use directly as a compound Ruby class name
    # (`class Electrical::MotorsImportTest < ...`) in test templates that
    # aren't wrapped in matching `module` nesting.
    def full_plural_class_name = class_name.pluralize
    # Leading "::" and class_name (fully-qualified, e.g. "Electrical::Motor"),
    # not model_class_name (leaf-only, "Motor") - this string is both
    # constantized directly (#validate_policy) and written as literal Ruby
    # source into the generated Import::<Plural>#authorize! (see
    # service.rb.erb). That file is nested inside `module Import; module
    # Electrical; ... end; end` for a namespaced model, and a *bare*
    # "Electrical::MotorPolicy" written there does NOT reliably resolve to
    # the real top-level ::Electrical::MotorPolicy - Ruby's constant lookup
    # finds the enclosing Import::Electrical module first and looks for
    # Electrical *inside* that, raising NameError. Confirmed directly with a
    # throwaway script reproducing the exact nesting shape. The leading "::"
    # anchors it to the top level unambiguously; safe_constantize handles a
    # leading "::" correctly too (confirmed).
    def policy_class_name = "::#{class_name}Policy"
    def discipline_association_name = discipline_association
    def column_stub = @column_stub
    def non_discipline_fks = @non_discipline_fks
    def model_namespaced? = class_path.any?
    def controller_class_name = model_class_name.pluralize
    def controller_path = Pathname.new(File.join(destination_root, "app", "controllers", "#{controller_file_path}_controller.rb"))
    def routes_path = Pathname.new(File.join(destination_root, "config", "routes.rb"))
    def destination_root_pathname = Pathname.new(destination_root)
    def route_contexts = options[:nesting].to_s.split(",").map(&:strip)
    def tagable? = options[:tagable]

    # A tagable model's own strong-params allowlist doesn't live on a
    # per-model controller (there is none - every tagable shares
    # TagablesController) but on its own "*_extension.rb" module (see
    # app/controllers/electrical/motor_extension.rb), matched by the
    # existing extend_tagable convention ("#{model}Extension").
    def extension_class_name = "#{class_name}Extension"
    def extension_path = Pathname.new(File.join(destination_root, "app", "controllers", folder, "#{file_name}_extension.rb"))

    def permitted_attributes_suggestion
      @permitted_attributes_suggestion ||= import_permitted_attributes_from(File.read(tagable? ? extension_path : controller_path))
    end

    # The controller's own strong-params allowlist never includes the
    # discipline FK (it's set via association-building, e.g.
    # @discipline.documents.build) - but the importer needs to set it
    # explicitly, exactly like Tag::IMPORTABLE_ATTRIBUTES includes
    # discipline_id even though TagsController#tag_params does too by a
    # different route. Included here so the printed suggestion is usable
    # as-is.
    def required_column_stub
      @column_stub.select { |c| c[:required] }.presence || @column_stub
    end

    def required_headers = required_column_stub.map { |c| c[:label] }
    def required_values
      required_column_stub.map do |col|
        max_length = model_class.validators_on(col[:key])
          .grep(ActiveModel::Validations::LengthValidator)
          .filter_map { |v| v.options[:maximum] }
          .min
        max_length ? "Sample value"[0, max_length] : "Sample value"
      end
    end
    def required_mapping = required_headers.zip(required_column_stub.map { |c| c[:key].to_s }).to_h

    def i18n_views_file(locale)
      if model_namespaced?
        Pathname.new(File.join(destination_root, "config", "locales", folder, locale.to_s, "#{locale}.#{class_path.last}.views.yml"))
      else
        Pathname.new(File.join(destination_root, "config", "locales", "core", locale.to_s, "#{locale}.views.yml"))
      end
    end

    def routes_section(content_or_context, context = nil)
      # Called either as routes_section(full_content, context) or
      # routes_section(context) (reads the file itself) - see call sites.
      content, ctx = context ? [content_or_context, context] : [File.read(routes_path), content_or_context]
      case ctx
      when "project"
        content[/^\s*resources :projects do\b.*?^\s*end # project nested routes\s*$/m]
      when "discipline"
        content[/^\s*resources :disciplines, shallow: true, only: \[\] do\b.*?^\s*end # discipline nested routes\s*$/m]
      end
    end

    # Rewrites the first recognized `resources :<plural>` shape found within
    # section_text into one with the import collection routes added.
    # Returns [rewritten_text, true] on success, [section_text, false] if no
    # recognized shape was found (see routes recognizer in the plan doc).
    def rewrite_routes_section(section_text, plural)
      plural_pattern = Regexp.escape(plural.to_s)
      import_block = ["collection do", "  get :import", "  post :import, action: :create_import", "end"]

      # Shape: resources :plural[, opts] do ... end (already has a block)
      block_pattern = /^(?<indent>[ \t]*)resources :#{plural_pattern}\b(?<opts>[^\n]*?)\s+do[ \t]*\n/
      if (m = section_text.match(block_pattern))
        insertion = import_block.map { |line| "#{m[:indent]}  #{line}\n" }.join
        rewritten = section_text.sub(block_pattern) { "#{m[:indent]}resources :#{plural}#{m[:opts]} do\n#{insertion}" }
        return [rewritten, true]
      end

      # Shape: bare/combined resources line, no block.
      line_pattern = /^(?<indent>[ \t]*)resources (?<before>(?::\w+,\s*)*):#{plural_pattern}(?<after>(?:,\s*:\w+)*)(?<only>,\s*only:\s*\[[^\]]*\])?[ \t]*\n/
      m = section_text.match(line_pattern)
      return [section_text, false] unless m

      others = "#{m[:before]}#{m[:after]}".split(",").map(&:strip).reject(&:empty?)
      lines = []
      lines << "#{m[:indent]}resources #{others.join(', ')}#{m[:only]}\n" if others.any?
      lines << "#{m[:indent]}resources :#{plural}#{m[:only]} do\n"
      import_block.each { |line| lines << "#{m[:indent]}  #{line}\n" }
      lines << "#{m[:indent]}end\n"
      [section_text.sub(line_pattern) { lines.join }, true]
    end

    def pad_lines(text, prefix)
      text.lines.map { |l| l.strip.empty? ? l : "#{prefix}#{l}" }.join
    end

    # Extends an existing `before_action :method, only: [...]` (or `%i[...]`)
    # line's action list to also cover :import/:create_import, in place -
    # never adds a second before_action for the same method name (see the
    # comment in #inject_controller for why that silently doesn't work). If
    # the method has no :only clause at all, it already runs for every
    # action, import included - left untouched. Returns
    # [new_content, true] if an existing registration was found (extended or
    # already-covered), or [content, false] if the method isn't registered
    # at all, so the caller knows to add a fresh line for it.
    def extend_before_action(content, method)
      # No \b after the escaped method name: for a bang method like
      # require_project!, the character before \b (!) and the one after
      # (usually a comma) are both non-word characters, so \b never matches
      # there at all - confirmed directly. The escaped name is already
      # unambiguous without it.
      pattern = /^([ \t]*)before_action :#{Regexp.escape(method)}(?=[,\s])([^\n]*)\n/
      m = content.match(pattern)
      return [content, false] unless m

      indent, rest = m[1], m[2]
      new_rest =
        if rest =~ /only:\s*%i\[([^\]]*)\]/
          items = ($1.split(/\s+/).reject(&:empty?) + %w[import create_import]).uniq
          rest.sub(/only:\s*%i\[[^\]]*\]/, "only: %i[#{items.join(' ')}]")
        elsif rest =~ /only:\s*\[([^\]]*)\]/
          items = ($1.split(",").map(&:strip).reject(&:empty?) + [":import", ":create_import"]).uniq
          rest.sub(/only:\s*\[[^\]]*\]/, "only: [#{items.join(', ')}]")
        end

      return [content, true] if new_rest.nil? # no :only clause - already covers every action

      [content.sub(pattern) { "#{indent}before_action :#{method}#{new_rest}\n" }, true]
    end

    def abort_with(errors)
      return if errors.empty?
      say_status :error, "Validation failed:", :red
      errors.each { |e| say_status :error, "  - #{e}", :red }
      raise Thor::Error, "Aborting generator"
    end
  end
end
