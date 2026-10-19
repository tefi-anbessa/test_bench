# frozen_string_literal: true
module ProjectAssistant
  module Shared
    # Supports AddFieldGenerator - the mirror image of FieldRemovalHelper.
    # Where that module locates a field's existing content and deletes it,
    # this one locates a stable, always-present anchor and inserts new
    # content shaped exactly like what ScaffoldGenerator's own templates
    # would have produced for the field, had it been there from the start.
    #
    # Insertion never tries to reproduce ScaffoldGenerator's exact ordering
    # within a section (e.g. a new belongs_to line may land after the
    # model's own nesting association, rather than before it, the way
    # ScaffoldGenerator itself would place it). That ordering is purely
    # cosmetic - nothing in Ruby, YAML, or ERB cares about it - so every
    # touchpoint here anchors on the nearest fixed, always-present marker
    # and inserts immediately next to it, rather than trying to detect
    # "the end of the existing run of same-shaped lines".
    module FieldAdditionHelper
      private

        # === Validation - the mirror of discover_field. There's nothing to
        # reflect on for the field itself (it doesn't exist yet), so this
        # validates the field spec and confirms the field is genuinely new,
        # rather than discovering what kind of field already exists.

        def validate_field_addition
          @model_class = class_name.safe_constantize
          unless @model_class && @model_class < ActiveRecord::Base
            say_status :error, "#{class_name} is not a known ActiveRecord model", :red
            raise Thor::Error, "Aborting generator"
          end

          @namespaced = class_path.any?
          @is_tagable = @model_class.include?(Tagable)
          @has_importable_attributes = @model_class.const_defined?(:IMPORTABLE_ATTRIBUTES, false)

          # field_spec must parse before field_name (derived from it, see
          # #field_name below) is usable for the existence check.
          input_fields = prepare_cli([field_spec])
          fields, errors = process_fields(input_fields)
          field = fields.first

          if field && field[:type] == :ip
            errors << "#{field[:name]}: :ip is only supported by the tagable generator."
            field = nil
          end

          if errors.any? || field.nil?
            say_status :error, "Field spec validation errors found:", :red
            errors.each { |error| say_status :error, "  - #{error}", :red }
            raise Thor::Error, "Aborting generator"
          end

          @field = field

          if @model_class.columns_hash.key?(field_name) || @model_class.reflect_on_association(field_name.to_sym)
            say_status :error, "#{field_name.inspect} already exists as a column or association on #{class_name}", :red
            raise Thor::Error, "Aborting generator"
          end

          @kind = ScaffoldHelper::ASSOCIATION_TYPES.include?(@field[:type]) ? :association : :attribute
          @required = @field[:options][:required] == true
          @unique = @field[:options][:unique] == true || @field[:options][:uniq] == true
          @index_opt = @field[:options][:index] == true
          @valid = @field[:options][:valid]
          @enum_keys = @field[:options][:keys] || []
          @classification_type = @field[:type].in?(%i[enum enum_translated]) ? :enum : @field[:type]
          @sql_type = @classification_type == :enum ? :integer : @field[:type]

          # A required field's migration can't safely set NOT NULL on an
          # existing (possibly populated) table without a backfill value,
          # and this generator will not invent one (see CLAUDE.md's "don't
          # invent default values" rule, and issue #4's plan notes) - so
          # required: without valid: is a hard validation failure, same
          # severity as any other bad field spec, not a --force-skippable
          # touchpoint miss. Scoped to attribute fields only: scaffold's own
          # create_table migration never enforces NOT NULL on a reference's
          # FK column either (see migration.rb.erb - t.references never
          # receives a null:false/options at all, required or not), so a
          # required association here only ever drives the model-level
          # belongs_to (no optional: true), never a DB constraint.
          if @kind == :attribute && @required && @valid.nil?
            say_status :error, "#{field_name.inspect} is required but no valid: value was given - a required " \
              "field added to a table that may already have rows needs an explicit backfill value, and this " \
              "generator will not invent one. Add :valid=<value> to the field spec, or drop :required.", :red
            raise Thor::Error, "Aborting generator"
          end
        end

        # field_spec (the Thor argument) carries the whole "name:type:opts"
        # string; every touchpoint below needs just the name, matching
        # RemoveFieldGenerator's own field_name Thor argument so the two
        # generators' touchpoint registries read the same either direction.
        def field_name
          @field[:name]
        end

        # === Shared insertion primitives - mirror image of
        # FieldRemovalHelper's primitives, not reused from them (most of
        # what each direction needs to locate is genuinely different - see
        # the module comment above and add_field_generator.rb/issue #4's
        # plan notes).

        # Inserts new_line immediately after the first line matched by
        # anchor_regex (which must match through to, and including, its own
        # trailing newline).
        def insert_line_after(content, anchor_regex, new_line)
          match = content.match(anchor_regex)
          return content unless match

          content[0...match.end(0)] + new_line + content[match.end(0)..]
        end

        # Inserts new_line immediately before the first line matched by
        # anchor_regex.
        def insert_line_before(content, anchor_regex, new_line)
          match = content.match(anchor_regex)
          return content unless match

          content[0...match.begin(0)] + new_line + content[match.begin(0)..]
        end

        # Appends one token to a comma/space-separated inner list's text -
        # the plain-array/plain-list case, mirror of remove_list_element.
        # Handles an empty list ("[]", "%i[]", empty permit()) without a
        # stray leading separator.
        def insert_list_element(inner, new_token, separator: ",")
          return new_token if inner.strip.empty?

          sep = separator == " " ? " " : "#{separator} "
          trimmed = inner.rstrip
          # Insert right before any trailing whitespace/newline rather than
          # after stripping it away, so a multi-line hash/array's closing
          # brace keeps its own line and indentation instead of being
          # dragged up onto the new element's line.
          trailing_ws = inner[trimmed.length..]
          "#{trimmed}#{sep}#{new_token}#{trailing_ws}"
        end

        # Appends one element into an enclosing literal (an array, a
        # permit(...) list, a hash). enclosing_regex must capture the
        # literal's inner text as group 1 - mirror of remove_bracket_element.
        def insert_bracket_element(content, enclosing_regex, new_token, separator: ",")
          match = content.match(enclosing_regex)
          return content unless match

          new_inner = insert_list_element(match[1], new_token, separator: separator)
          content[0...match.begin(1)] + new_inner + content[match.end(1)..]
        end

        # The one primitive with no removal-side mirror: several macro
        # calls (test_required_fields, test_enum_field, etc.) only exist in
        # the first place if some earlier field already needed them. If
        # existing_call_regex matches, append into its arglist (same as
        # insert_bracket_element); otherwise insert a brand new line,
        # formatted fresh, immediately before fallback_anchor_regex.
        def insert_arg_or_new_call(content, existing_call_regex, fallback_anchor_regex, new_line, new_token, separator: ",")
          match = content.match(existing_call_regex)
          if match
            new_inner = insert_list_element(match[1], new_token, separator: separator)
            content[0...match.begin(1)] + new_inner + content[match.end(1)..]
          else
            insert_line_before(content, fallback_anchor_regex, new_line)
          end
        end

        def symbol_token(name)
          ":#{name}"
        end

        def tp(key:, path:, locate:, insert:, optional: false)
          { key: key, path: path, locate: locate, insert: insert, optional: optional }
        end

        # === Touchpoint registry - one method per generated file, mirroring
        # FieldRemovalHelper's same 9 categories and key: symbols.

        def model_path
          Pathname.new(File.join(destination_root, "app", "models", "#{file_path}.rb"))
        end

        def model_touchpoints
          path = model_path
          points = []

          if @classification_type == :enum
            anchor = /^[ \t]*# enum declarations\n/
            line = "    enum :#{field_name}, Constants.#{i18n_scope}.#{field_name}.to_h, prefix: true\n"
            points << tp(
              key: :model_enum, path: path,
              locate: ->(c) { c.match?(anchor) },
              insert: ->(c) { insert_line_after(c, anchor, line) }
            )
          end

          if @kind == :association
            anchor = /^[ \t]*# === Associations ===\n/
            line = "    belongs_to :#{field_name}#{", optional: true" unless @required}\n"
            points << tp(
              key: :model_belongs_to, path: path,
              locate: ->(c) { c.match?(anchor) },
              insert: ->(c) { insert_line_after(c, anchor, line) }
            )
          end

          if @kind == :attribute && @required
            anchor = /^[ \t]*# Presence validation for required fields\.\n/
            line = "    validates :#{field_name}, presence: true\n"
            points << tp(
              key: :model_validates_presence, path: path,
              locate: ->(c) { c.match?(anchor) },
              insert: ->(c) { insert_line_after(c, anchor, line) }
            )
          end

          if @kind == :attribute && @unique
            anchor = /^[ \t]*# Uniqueness validation for unique fields\.\n/
            line = "    validates :#{field_name}, uniqueness: true\n"
            points << tp(
              key: :model_validates_uniqueness, path: path,
              locate: ->(c) { c.match?(anchor) },
              insert: ->(c) { insert_line_after(c, anchor, line) }
            )
          end

          # NOTE: every touchpoint below needs its own uniquely-named local
          # variables - see FieldRemovalHelper#model_touchpoints' comment on
          # this exact hazard (a lambda closes over the *variable*, not its
          # value at definition time, so a later block reassigning the same
          # name silently corrupts an earlier touchpoint's closure before
          # apply_insertions ever calls it).
          ransack_array_name = @kind == :association ? "ransackable_associations" : "ransackable_attributes"
          applies_to_ransack = @kind == :association || ScaffoldHelper::SEARCHABLE_TYPES.include?(@classification_type)
          if applies_to_ransack
            # Captures just the array literal's inner text (between its own
            # [ and ]), not the whole return-statement line - unlike
            # FieldRemovalHelper's equivalent regex (which can capture the
            # whole line, since surgical token removal works regardless of
            # the surrounding bracket style), insertion needs to know
            # exactly where the closing bracket is. ScaffoldGenerator's own
            # <%= @ransack_attributes %> always renders Ruby's Array#to_s
            # bracket form (confirmed real), never %i[...] - a hand-edited
            # %i[...] form (confirmed real on Switchboard) simply won't
            # match here, which is correct: this touchpoint reports MISSING
            # rather than guess where to insert.
            ransack_array_regex = /def self\.#{ransack_array_name}\(auth_object = nil\)\n[ \t]*\[(.*?)\]\n[ \t]*end\n/m
            ransack_token = symbol_token(field_name)
            points << tp(
              key: :"model_#{ransack_array_name}", path: path,
              locate: ->(c) { c.match?(ransack_array_regex) },
              insert: ->(c) { insert_bracket_element(c, ransack_array_regex, ransack_token) }
            )
          end

          if @has_importable_attributes
            importable_token_name = @kind == :association ? "#{field_name}_id" : field_name
            importable_array_regex = /IMPORTABLE_ATTRIBUTES = %i\[(.*?)\]/m
            importable_token = importable_token_name
            points << tp(
              key: :model_importable_attributes, path: path,
              locate: ->(c) { c.match?(importable_array_regex) },
              insert: ->(c) { insert_bracket_element(c, importable_array_regex, importable_token, separator: " ") }
            )
          end

          points
        end

        # === Migration - not a touchpoint (nothing to locate), but still
        # gated behind check_report! passing - see create_addition_migration_file.

        def migration_class_name
          "Add#{field_name.camelize}To#{table_name.camelize}"
        end

        # Only ever reached with @valid present when @required - the
        # pipeline aborts in validate_field_addition otherwise. For an enum
        # field, @valid is the key's own name (as given on the CLI, e.g.
        # "steel"), resolved here to its integer position within the field
        # spec's own explicit keys: list - no dependency on reading
        # constants.yml back, since that list is exactly what will be
        # written there in the first place.
        def backfill_sql_value
          case @classification_type
          when :enum
            @enum_keys.map(&:to_s).index(@valid.to_s)
          when :integer, :bigint, :boolean, :float, :decimal
            @valid.to_s
          else
            ActiveRecord::Base.connection.quote(@valid.to_s)
          end
        end

        def migration_requires_backfill?
          @kind == :attribute && @required
        end

        def migration_body
          if @kind == :association
            # Scaffold's own create_table migration never enforces NOT NULL
            # on a reference's FK column either way (t.references never
            # receives null:false, required or not - see migration.rb.erb)
            # - required: only ever drives the model-level belongs_to here,
            # never a DB constraint, so there's nothing to backfill.
            "    add_reference :#{table_name}, :#{field_name}, null: true, foreign_key: true"
          else
            lines = ["    add_column :#{table_name}, :#{field_name}, :#{@sql_type}"]
            if @unique
              lines << "    add_index :#{table_name}, :#{field_name}, unique: true"
            elsif @index_opt
              lines << "    add_index :#{table_name}, :#{field_name}"
            end
            if migration_requires_backfill?
              lines << "    execute \"UPDATE #{table_name} SET #{field_name} = #{backfill_sql_value} WHERE #{field_name} IS NULL\""
              lines << "    change_column_null :#{table_name}, :#{field_name}, false"
            end
            lines.join("\n")
          end
        end

        # === Controller

        def controller_path_for_addition
          if @is_tagable
            Pathname.new(File.join(destination_root, "app", "controllers", *class_path, "#{singular_name}_extension.rb"))
          else
            Pathname.new(File.join(destination_root, "app", "controllers", "#{controller_file_path}_controller.rb"))
          end
        end

        def controller_touchpoints
          path = controller_path_for_addition
          points = []

          unless @has_importable_attributes
            permit_method = @is_tagable ? "tagable_params" : "resource_params"
            permit_token = @kind == :association ? "#{field_name}_id" : field_name
            permit_token = ":#{permit_token}"
            permit_regex = /def #{permit_method}\b.*?\.permit\((.*?)\)/m
            points << tp(
              key: :controller_permit, path: path,
              locate: ->(c) { c.match?(permit_regex) },
              insert: ->(c) { insert_bracket_element(c, permit_regex, permit_token) }
            )
          end

          if @kind == :association
            # Not optional, unlike the removal side's version of this
            # touchpoint - insertion needs a guaranteed landing spot rather
            # than tolerating a hand-edited method it can't find its way
            # into. The method's own def line (always present) is the
            # anchor; block_end_offset (same primitive used for the YAML
            # touchpoints below) finds the body's end by indentation, which
            # survives a developer having added their own nested
            # if/each/end inside the body - a lazy "match up to the first
            # \nend\n" regex would stop at that nested end instead.
            def_regex = /^([ \t]*)def setup_additional_form_data\n/
            line = "        @#{field_name.pluralize} = policy_scope(#{field_name.classify})\n"
            points << tp(
              key: :controller_setup_form_data, path: path,
              locate: ->(c) { c.match?(def_regex) },
              insert: ->(c) {
                match = c.match(def_regex)
                next c unless match
                body_end = block_end_offset(c, after_index: match.end(0), indent: match[1])
                c[0...body_end] + line + c[body_end..]
              }
            )
          end

          points
        end

        # === Views

        def views_dir
          File.join(destination_root, "app", "views", controller_file_path)
        end

        # The precision/scale/units/si options, formatted exactly as the
        # view templates' own `opts` local does, for a decimal/float
        # field's row/show/card display - "" when none are set.
        def display_opts_suffix
          return "" unless @classification_type.in?(%i[decimal float])
          opts = @field[:options].slice(:precision, :scale, :units, :si)
          return "" if opts.empty?
          ", #{opts.map { |k, v| "#{k}: #{v.inspect}" }.join(", ")}"
        end

        def view_path(name)
          Pathname.new(File.join(views_dir, name))
        end

        def view_touchpoints
          points = []
          points.concat(form_view_touchpoints)
          points << header_view_touchpoint
          points << row_view_touchpoint
          points << show_view_touchpoint
          points << card_view_touchpoint
          points << index_search_touchpoint if ScaffoldHelper::SEARCHABLE_TYPES.include?(@classification_type) && @kind == :attribute
          points.compact
        end

        def form_view_touchpoints
          path = view_path("_form.html.erb")
          anchor = /^[ \t]*<\/div> <!-- end #{singular_name} card body -->\n/

          if @kind == :association
            line = "                <% collection = options_for_select(#{field_name.pluralize}, selected: #{singular_name}.#{field_name}_id) %>\n" \
              "                <%= form_field(f, :#{field_name}, type: :select, collection: collection) %>\n"
          else
            opts = @field[:options].except(:index, :uniq, :unique, :valid, :keys)
            opts_text = opts.map { |k, v| "#{k}: #{v.inspect}" }.join(", ")
            type_kwarg =
              case @classification_type
              when :text then "type: :text"
              when :jsonb then "type: :jsonb"
              when :integer, :bigint, :float, :decimal then "type: :number"
              when :datetime, :timestamp, :time then "type: :datetime"
              when :date then "type: :date"
              when :boolean then "type: :boolean"
              when :enum then "type: :enum"
              when :enum_translated then "type: :enum_translated"
              end
            args = [":#{field_name}", type_kwarg, (opts_text unless opts_text.empty?)].compact.join(", ")
            line = "                <%= form_field(f, #{args}) %>\n"
          end

          [tp(
            key: :view_form, path: path,
            locate: ->(c) { c.match?(anchor) },
            insert: ->(c) { insert_line_before(c, anchor, line) }
          )]
        end

        def header_view_touchpoint
          return nil unless ScaffoldHelper::INDEX_TYPES.include?(@classification_type) || @kind == :association
          path = view_path("_header.html.erb")
          anchor = /^[ \t]*<th width="150px">.*<\/th>\n/
          line = "  <th><%= sort_link(@q, :#{field_name}) %></th>\n"
          tp(
            key: :view_header, path: path,
            locate: ->(c) { c.match?(anchor) },
            insert: ->(c) { insert_line_before(c, anchor, line) }
          )
        end

        def row_view_touchpoint
          return nil unless ScaffoldHelper::INDEX_TYPES.include?(@classification_type) || @kind == :association
          path = view_path("_row.html.erb")
          anchor = /^[ \t]*<td>\n/
          content =
            if @kind == :association
              "index_attribute(row, :#{field_name}, type: :association)"
            elsif @classification_type == :string
              "index_attribute(row, :#{field_name})"
            else
              "index_attribute(row, :#{field_name}, type: :#{@classification_type}#{display_opts_suffix})"
            end
          line = "  <td><%= #{content} %></td>\n"
          tp(
            key: :view_row, path: path,
            locate: ->(c) { c.match?(anchor) },
            insert: ->(c) { insert_line_before(c, anchor, line) }
          )
        end

        def show_view_touchpoint
          path = view_path("show.html.erb")
          if @kind == :association
            anchor = /^[ \t]*<\/div>  <!-- end inner card body -->\n/
            line = "              <%= show_association(@#{singular_name}, :#{field_name}) %>\n"
          else
            return nil if @classification_type == :binary
            anchor = /^[ \t]*<\/div>   <!-- temporary end inner card body -->\n/
            type_kwarg = @classification_type == :string ? "" : ", type: :#{@classification_type}#{display_opts_suffix}"
            line = "              <%= show_attribute(@#{singular_name}, :#{field_name}#{type_kwarg}) %>\n"
          end
          tp(
            key: :view_show, path: path,
            locate: ->(c) { c.match?(anchor) },
            insert: ->(c) { insert_line_before(c, anchor, line) }
          )
        end

        def card_view_touchpoint
          path = view_path("_card.html.erb")
          anchor = /^[ \t]*<\/div> <!-- end container-fluid -->\n/
          if @kind == :association
            line = "      <%= show_attribute(#{singular_name}, :#{field_name}, type: :association) %>\n"
          else
            return nil if @classification_type == :binary
            type_kwarg = @classification_type == :string ? "" : ", type: :#{@classification_type}#{display_opts_suffix}"
            line = "      <%= show_attribute(#{singular_name}, :#{field_name}#{type_kwarg}) %>\n"
          end
          tp(
            key: :view_card, path: path,
            locate: ->(c) { c.match?(anchor) },
            insert: ->(c) { insert_line_before(c, anchor, line) }
          )
        end

        def index_search_touchpoint
          path = view_path("index.html.erb")
          anchor = /^[ \t]*<%=\s*f\.button nil, class: "btn btn-outline-primary.*\n/
          line = "          <%= f.search_field :#{field_name}_cont,\n" \
            "                class: \"search_field\",\n" \
            "                placeholder: t(\"activerecord.attributes.#{i18n_model_scope}.#{field_name}\") %>\n"
          tp(
            key: :view_index_search, path: path,
            locate: ->(c) { c.match?(anchor) },
            insert: ->(c) { insert_line_before(c, anchor, line) }
          )
        end

        # === Factory

        def factory_path
          Pathname.new(File.join(destination_root, "test", "factories", "#{controller_file_path}.rb"))
        end

        def factory_touchpoints
          path = factory_path
          if @kind == :association
            anchor = /^[ \t]*# Associations\n/
            line = "    association :#{field_name}\n"
          else
            anchor = /^[ \t]*# Attributes\n/
            valid = @valid || (@classification_type == :enum ? @enum_keys.first : nil)
            line = "    #{field_name} { #{valid.inspect} }\n"
          end
          [tp(
            key: :factory, path: path,
            locate: ->(c) { c.match?(anchor) },
            insert: ->(c) { insert_line_after(c, anchor, line) }
          )]
        end

        # === Model test

        def model_test_path
          Pathname.new(File.join(destination_root, "test", "models", "#{file_path}_test.rb"))
        end

        FINAL_MARKER_REGEX = /^[ \t]*# Insert model specific tests here\.\n/
        private_constant :FINAL_MARKER_REGEX

        def model_test_touchpoints
          path = model_test_path
          points = []
          token = symbol_token(field_name)

          if @required
            macro = @kind == :association ? "test_required_associations" : "test_required_fields"
            existing_call_regex = /^[ \t]*#{macro}\((.*?)\)\n/m
            new_line = "    #{macro}(#{token})\n"
            points << tp(
              key: :model_test_required, path: path,
              locate: ->(c) { c.match?(existing_call_regex) || c.match?(FINAL_MARKER_REGEX) },
              insert: ->(c) { insert_arg_or_new_call(c, existing_call_regex, FINAL_MARKER_REGEX, new_line, token) }
            )
          end

          if @kind == :attribute && @unique
            existing_call_regex = /^[ \t]*test_unique_fields\((.*?)\)\n/m
            new_line = "    test_unique_fields(#{token})\n"
            points << tp(
              key: :model_test_unique, path: path,
              locate: ->(c) { c.match?(existing_call_regex) || c.match?(FINAL_MARKER_REGEX) },
              insert: ->(c) { insert_arg_or_new_call(c, existing_call_regex, FINAL_MARKER_REGEX, new_line, token) }
            )
          end

          if @classification_type == :enum
            anchor = FINAL_MARKER_REGEX
            line = "    test_enum_field(:#{field_name}, prefix: true)\n"
            points << tp(
              key: :model_test_enum, path: path,
              locate: ->(c) { c.match?(anchor) },
              insert: ->(c) { insert_line_before(c, anchor, line) }
            )

            # Unlike removal, which has to probe whether an enum field is
            # specifically enum_translated (Rails' own enum metadata can't
            # tell), add_field is told explicitly on the CLI - no probing.
            if @field[:type] == :enum_translated
              existing_call_regex = /^[ \t]*test_enum_translations\((.*?)\)\n/m
              new_line = "    test_enum_translations(#{token})\n"
              points << tp(
                key: :model_test_enum_translations, path: path,
                locate: ->(c) { c.match?(existing_call_regex) || c.match?(FINAL_MARKER_REGEX) },
                insert: ->(c) { insert_arg_or_new_call(c, existing_call_regex, FINAL_MARKER_REGEX, new_line, token) }
              )
            end
          end

          points
        end

        # === System test

        def system_test_path
          Pathname.new(File.join(destination_root, "test", "system", "#{controller_file_path}_system_test.rb"))
        end

        def system_test_touchpoints
          path = system_test_path
          points = []

          [["@index_fields", ScaffoldHelper::INDEX_TYPES.include?(@classification_type) && @kind == :attribute],
           ["@search_fields", ScaffoldHelper::SEARCHABLE_TYPES.include?(@classification_type) && @kind == :attribute],
           ["@show_fields", @kind == :attribute],
           ["@show_associations", @kind == :association]].each do |ivar, applicable|
            next unless applicable
            array_regex = /#{Regexp.escape(ivar)} = %i\[(.*?)\]/m
            points << tp(
              key: :"system_test_#{ivar.delete('@')}", path: path,
              locate: ->(c) { c.match?(array_regex) },
              insert: ->(c) { insert_bracket_element(c, array_regex, field_name, separator: " ") }
            )
          end

          new_fields_regex = /@new_fields = \{(.*?)\}/m
          points << tp(
            key: :system_test_new_fields, path: path,
            locate: ->(c) { c.match?(new_fields_regex) },
            insert: ->(c) { insert_bracket_element(c, new_fields_regex, "#{field_name}: nil") }
          )

          if @is_tagable
            points << system_test_edit_attributes_touchpoint
          end

          points
        end

        # Not an append - @edit_attributes is chosen by a heuristic at
        # generation time (prefers a field named "notes", falls back to any
        # string/text column). Only recompute if the current value is still
        # the collapsed empty default and this new field qualifies (string
        # or text) - deliberately conservative, never overrides a
        # developer's existing non-empty choice (the reverse of removal's
        # version of this heuristic, which must recompute since there the
        # chosen field is gone).
        def system_test_edit_attributes_touchpoint
          path = system_test_path
          line_regex = /^([ \t]*)@edit_attributes = (\{.*?\})\n/
          tp(
            key: :system_test_edit_attributes, path: path,
            locate: ->(c) { c.match?(line_regex) },
            insert: ->(c) {
              match = c.match(line_regex)
              next c unless match
              current = match[2]
              new_value =
                if current.strip == "{}" && @classification_type.in?(%i[string text])
                  "{ #{field_name}: \"Updated value\" }"
                else
                  current
                end
              c[0...match.begin(0)] + "#{match[1]}@edit_attributes = #{new_value}\n" + c[match.end(0)..]
            }
          )
        end

        # === Controller test

        def controller_test_path
          Pathname.new(File.join(destination_root, "test", "controllers", "#{controller_file_path}_controller_test.rb"))
        end

        def controller_test_touchpoints
          path = controller_test_path
          create_params_regex = /def create_params\s*\{(.*?)\}\s*end/m
          valid = @kind == :association ? @valid : (@valid || (@classification_type == :enum ? @enum_keys.first : nil))
          token = "#{field_name}: #{valid.inspect}"
          [tp(
            key: :controller_test_create_params, path: path,
            locate: ->(c) { c.match?(create_params_regex) },
            insert: ->(c) { insert_bracket_element(c, create_params_regex, token) },
            optional: true # create_params is a one-shot generated stub developers routinely hand-edit afterwards
          )]
        end

        # === Constants YAML (enum fields only)

        def constants_path
          file = @namespaced ? "#{class_path[0]}.yml" : "core.yml"
          Pathname.new(File.join(destination_root, "config", "constants", file))
        end

        def constants_touchpoints
          return [] unless @classification_type == :enum
          path = constants_path
          model_key_regex = /^([ \t]*)#{Regexp.escape(singular_name)}:[ \t]*(\{\})?[ \t]*\n/
          [tp(
            key: :constants_enum_block, path: path,
            locate: ->(c) { c.match?(model_key_regex) },
            insert: ->(c) { insert_nested_yaml_block(c, model_key_regex) }
          )]
        end

        # Inserts the new enum field's own sub-block inside the model's
        # existing top-level block, found via block_end_offset - the
        # literal inverse of FieldRemovalHelper#remove_nested_yaml_block's
        # collapse step: expands a collapsed "<model>: {}" back into a real
        # block first, if this is the model's first-ever enum field.
        def insert_nested_yaml_block(content, model_key_regex)
          match = content.match(model_key_regex)
          return content unless match

          indent = match[1]
          tab = "  "
          field_indent = indent + tab
          field_block = +"#{field_indent}#{field_name}:\n"
          @enum_keys.each_with_index do |key, index|
            field_block << "#{field_indent}#{tab}#{key}: #{index}\n"
          end

          if match[2] # collapsed "<model>: {}" - expand it first
            content[0...match.begin(0)] + "#{indent}#{singular_name}:\n" + field_block + content[match.end(0)..]
          else
            block_start = match.end(0)
            block_end = block_end_offset(content, after_index: block_start, indent: indent)
            content[0...block_end] + field_block + content[block_end..]
          end
        end

        # === Locale YAML (models.yml - every field; enum_translated adds a
        # sibling pluralized sub-block)

        def locale_model_file(locale)
          if @namespaced
            Pathname.new(File.join(destination_root, "config", "locales", folder, locale.to_s, "#{locale}.#{class_path[-1]}.models.yml"))
          else
            Pathname.new(File.join(destination_root, "config", "locales", "core", locale.to_s, "#{locale}.models.yml"))
          end
        end

        # Mirror of FieldRemovalHelper#locale_attributes_model_match - the
        # model's own key appears twice in the file (once under "models:",
        # once under "attributes:"), so the search must anchor past
        # "attributes:" to hit the right occurrence.
        def locale_attributes_model_match(content)
          attrs = content.match(/^[ \t]*attributes:[ \t]*\n/)
          return nil unless attrs
          content.match(/^([ \t]*)#{Regexp.escape(i18n_model_scope)}:[ \t]*\n/, attrs.end(0))
        end

        def locale_touchpoints
          I18n.available_locales.flat_map do |locale|
            path = locale_model_file(locale)
            tab = "  "

            points = [tp(
              key: :"locale_#{locale}_attribute_label", path: path,
              locate: ->(c) { !!locale_attributes_model_match(c) },
              insert: ->(c) {
                m = locale_attributes_model_match(c)
                next c unless m
                block_end = block_end_offset(c, after_index: m.end(0), indent: m[1])
                field_line = "#{m[1]}#{tab}#{field_name}: \"#{field_name.humanize}\"\n"
                c[0...block_end] + field_line + c[block_end..]
              }
            )]

            if @field[:type] == :enum_translated
              points << tp(
                key: :"locale_#{locale}_enum_translated_block", path: path,
                locate: ->(c) { !!locale_attributes_model_match(c) },
                insert: ->(c) {
                  m = locale_attributes_model_match(c)
                  next c unless m
                  block_end = block_end_offset(c, after_index: m.end(0), indent: m[1])
                  plural_block = +"#{m[1]}#{tab}#{field_name.pluralize}:\n"
                  @enum_keys.each { |key| plural_block << "#{m[1]}#{tab}#{tab}#{key}: \"#{key.to_s.humanize}\"\n" }
                  c[0...block_end] + plural_block + c[block_end..]
                }
              )
            end

            points
          end
        end
    end
  end
end
