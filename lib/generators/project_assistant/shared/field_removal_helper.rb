# frozen_string_literal: true
module ProjectAssistant
  module Shared
    # Supports RemoveFieldGenerator - the mirror image of ScaffoldHelper's
    # insert_* methods. Those only ever insert new content at a fixed
    # anchor; nothing in this codebase previously needed to read back an
    # existing generated file, locate a specific field's declaration in it,
    # and remove just that - this module is that capability.
    module FieldRemovalHelper
      private

        # === Discovery - reads the live model class, never model.rb/schema.rb
        # text. A model's own files can (and, confirmed in this app, already
        # do - see app/models/electrical/switchboard.rb) drift from exactly
        # what the generator would have written, so this is the one source
        # of truth that's always accurate: the schema and model Ruby code
        # that's actually loaded and running.

        def discover_field
          @model_class = class_name.safe_constantize
          unless @model_class && @model_class < ActiveRecord::Base
            say_status :error, "#{class_name} is not a known ActiveRecord model", :red
            raise Thor::Error, "Aborting generator"
          end

          reflection = @model_class.reflect_on_association(field_name.to_sym)
          if reflection&.belongs_to?
            @kind = :association
            @required = reflection.options[:optional] != true
            @unique = false
            @is_enum = false
          else
            column = @model_class.columns_hash[field_name]
            unless column
              say_status :error, "#{field_name.inspect} is not a column or association on #{class_name}", :red
              raise Thor::Error, "Aborting generator"
            end
            @kind = :attribute
            @column_type = column.type
            # Postgres reports both bigint and integer columns as :integer -
            # sql_type is the only reliable signal, needed for a correct
            # remove_column migration (every other touchpoint's own pattern
            # already treats integer/bigint alike, so this only matters here).
            @sql_type = column.sql_type.match?(/bigint/i) ? :bigint : @column_type
            @is_enum = @model_class.defined_enums.key?(field_name)
            @enum_keys = @is_enum ? @model_class.defined_enums[field_name].keys : []
            @is_ip = (field_name == "ingress_protection" && @column_type == :string)
            validators = @model_class.validators_on(field_name.to_sym)
            @required = validators.any? { |v| v.is_a?(ActiveModel::Validations::PresenceValidator) }
            @unique = validators.any? { |v| v.is_a?(ActiveRecord::Validations::UniquenessValidator) }
          end

          @is_tagable = @model_class.include?(Tagable)
          @nesting =
            if @is_tagable
              :tagable
            elsif @model_class.const_defined?(:NESTED_SCOPES)
              scopes = @model_class::NESTED_SCOPES
              if scopes.size > 1
                say_status :error,
                  "#{class_name}::NESTED_SCOPES has more than one entry (#{scopes.inspect}) - " \
                  "this generator only understands a single fixed nesting, same as the scaffold " \
                  "generator's own templates. Not safe to proceed.", :red
                raise Thor::Error, "Aborting generator"
              end
              scopes.first
            else
              :none
            end

          @index_exists = @kind == :attribute &&
            @model_class.connection.index_exists?(@model_class.table_name, field_name)
        end

        # === Shared removal primitives

        # Deletes a single whole line matched by line_regex (which must
        # itself match through to, and including, the line's trailing
        # newline). Returns content unchanged if the pattern isn't present -
        # callers only call this once they already know (from the locate
        # phase) that it matched.
        def remove_whole_line(content, line_regex)
          content.sub(line_regex, "")
        end

        # Removes one token from inside a comma/space-separated inner list
        # and returns just the updated inner text (not the whole content) -
        # the plain-array/plain-list case, used where the enclosing literal
        # is never deleted outright even if it becomes empty (e.g. the
        # ransack arrays, which stay valid Ruby as `[]`). Prefers to also
        # consume a trailing separator (so "a, b, c" minus "b" leaves
        # "a, c" not "a, , c"), falling back to a leading one for the last
        # element in the list.
        def remove_list_element(inner, token_regex, separator: ",")
          sep_pattern = Regexp.escape(separator)
          new_inner = inner.sub(/#{token_regex}\s*#{sep_pattern}\s*/, "")
          new_inner = new_inner.sub(/#{sep_pattern}\s*#{token_regex}/, "") if new_inner == inner
          new_inner.sub(token_regex, "")
        end

        # Removes one comma/space-separated element from inside an enclosing
        # literal (an array, a permit(...) list, a hash). enclosing_regex
        # must capture the literal's inner text as group 1; token_regex
        # matches just the one element to remove within that captured text.
        def remove_bracket_element(content, enclosing_regex, token_regex, separator: ",")
          match = content.match(enclosing_regex)
          return content unless match

          new_inner = remove_list_element(match[1], token_regex, separator: separator)
          content[0...match.begin(1)] + new_inner + content[match.end(1)..]
        end

        # Removes one argument from a method call's arglist, deleting the
        # whole call (and its line) outright if that was the call's only
        # argument - for macro calls like test_required_fields(:foo) where
        # an empty call is meaningless, unlike a plain array that can stay
        # `[]`. whole_line_regex must match the entire call's line(s)
        # (through its trailing newline) and capture the arglist as group 1.
        def remove_arg_or_whole_call(content, whole_line_regex, token_regex, separator: ",")
          match = content.match(whole_line_regex)
          return content unless match

          new_inner = remove_list_element(match[1], token_regex, separator: separator)
          if new_inner.strip.empty?
            content.sub(whole_line_regex, "")
          else
            content[0...match.begin(1)] + new_inner + content[match.end(1)..]
          end
        end

        # A bareword hash key's value, stopping at the next comma or
        # closing brace/bracket - for hash literals whose values aren't
        # otherwise predictable (factory defaults, test fixture params).
        def hash_key_token(key)
          /#{Regexp.escape(key)}:\s*[^,}\]]*/
        end

        def symbol_or_string_token(name)
          /(?::#{Regexp.escape(name)}\b|"#{Regexp.escape(name)}")/
        end

        def tp(key:, path:, locate:, remove:, optional: false)
          { key: key, path: path, locate: locate, remove: remove, optional: optional }
        end

        # === Touchpoint registry - one method per generated file, each
        # returning the touchpoint(s) applicable to this field. Called once
        # from build_touchpoint_registry. "Applicable" is decided here from
        # discovery (@kind/@is_enum/@required/@unique/@is_tagable/etc) -
        # entries aren't included at all when they wouldn't apply, rather
        # than included and expected to report not-found.

        def model_path
          Pathname.new(File.join(destination_root, "app", "models", "#{file_path}.rb"))
        end

        def model_touchpoints
          path = model_path
          points = []

          if @is_enum
            points << tp(
              key: :model_enum, path: path,
              locate: ->(c) { c.match?(/^[ \t]*enum :#{field_name}, Constants\..*?\.to_h(?:, prefix: true)?\n/) },
              remove: ->(c) { remove_whole_line(c, /^[ \t]*enum :#{field_name}, Constants\..*?\.to_h(?:, prefix: true)?\n/) }
            )
          end

          if @kind == :association
            points << tp(
              key: :model_belongs_to, path: path,
              locate: ->(c) { c.match?(/^[ \t]*belongs_to :#{field_name}(?:, optional: true)?\n/) },
              remove: ->(c) { remove_whole_line(c, /^[ \t]*belongs_to :#{field_name}(?:, optional: true)?\n/) }
            )
          end

          if @kind == :attribute && @required
            points << tp(
              key: :model_validates_presence, path: path,
              locate: ->(c) { c.match?(/^[ \t]*validates :#{field_name}, presence: true\n/) },
              remove: ->(c) { remove_whole_line(c, /^[ \t]*validates :#{field_name}, presence: true\n/) }
            )
          end

          if @kind == :attribute && @unique
            points << tp(
              key: :model_validates_uniqueness, path: path,
              locate: ->(c) { c.match?(/^[ \t]*validates :#{field_name}, uniqueness: true\n/) },
              remove: ->(c) { remove_whole_line(c, /^[ \t]*validates :#{field_name}, uniqueness: true\n/) }
            )
          end

          # A required association field's redundant model.rb validates
          # line (see field_removal_helper.rb discovery comment) can't be
          # told apart from "wasn't generated" via live reflection - so this
          # one touchpoint is discovered by probing for its own presence,
          # and marked optional (its absence is never an abort reason).
          if @kind == :association
            points << tp(
              key: :model_validates_presence_association, path: path,
              locate: ->(c) { c.match?(/^[ \t]*validates :#{field_name}, presence: true\n/) },
              remove: ->(c) { remove_whole_line(c, /^[ \t]*validates :#{field_name}, presence: true\n/) },
              optional: true
            )
          end

          ransack_array_name = @kind == :association ? "ransackable_associations" : "ransackable_attributes"
          applies_to_ransack = @kind == :association || ScaffoldHelper::SEARCHABLE_TYPES.include?(@column_type)
          if applies_to_ransack
            array_regex = /def self\.#{ransack_array_name}\(auth_object = nil\)\n(.*?)\n[ \t]*end\n/m
            token = symbol_or_string_token(field_name)
            points << tp(
              key: :"model_#{ransack_array_name}", path: path,
              locate: ->(c) {
                m = c.match(array_regex)
                m && m[1].match?(token)
              },
              remove: ->(c) { remove_bracket_element(c, array_regex, token) }
            )
          end

          points
        end

        # === Migration - not a touchpoint (nothing to locate), but still
        # gated behind check_report! passing - see create_removal_migration_file.

        def migration_class_name
          "Remove#{field_name.camelize}From#{table_name.camelize}"
        end

        def migration_body
          if @kind == :association
            lines = []
            lines << "    remove_reference :#{table_name}, :#{field_name}, foreign_key: true"
            lines.join("\n")
          else
            lines = []
            if @index_exists
              lines << "    remove_index :#{table_name}, :#{field_name} if index_exists?(:#{table_name}, :#{field_name})"
              lines << ""
            end
            lines << "    remove_column :#{table_name}, :#{field_name}, :#{@sql_type}"
            lines.join("\n")
          end
        end

        # === Controller

        def controller_path_for_removal
          if @is_tagable
            Pathname.new(File.join(destination_root, "app", "controllers", *class_path, "#{singular_name}_extension.rb"))
          else
            Pathname.new(File.join(destination_root, "app", "controllers", "#{controller_file_path}_controller.rb"))
          end
        end

        def controller_touchpoints
          path = controller_path_for_removal
          permit_method = @is_tagable ? "tagable_params" : "resource_params"
          permit_token = @kind == :association ? /:#{field_name}_id\b/ : symbol_or_string_token(field_name)
          permit_regex = /def #{permit_method}\b.*?\.permit\((.*?)\)/m
          points = [
            tp(
              key: :controller_permit, path: path,
              locate: ->(c) {
                m = c.match(permit_regex)
                m && m[1].match?(permit_token)
              },
              remove: ->(c) { remove_bracket_element(c, permit_regex, permit_token) }
            )
          ]

          if @kind == :association
            line_regex = /^[ \t]*@#{field_name.pluralize} = policy_scope\(#{field_name.classify}\)\n/
            points << tp(
              key: :controller_setup_form_data, path: path,
              locate: ->(c) { c.match?(line_regex) },
              remove: ->(c) { remove_whole_line(c, line_regex) },
              optional: true # setup_additional_form_data is hand-editable free text, not a fixed template body
            )
          end

          points
        end

        # === Views

        def views_dir
          File.join(destination_root, "app", "views", controller_file_path)
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
          points << index_search_touchpoint if ScaffoldHelper::SEARCHABLE_TYPES.include?(@column_type) && @kind == :attribute
          points.compact
        end

        def form_view_touchpoints
          path = view_path("_form.html.erb")
          if @kind == :association
            line_regex = /^[ \t]*<%\s*collection = options_for_select\(#{field_name.pluralize},.*?\n[ \t]*<%=\s*form_field\(f, :#{field_name},.*?%>\n/m
            [tp(
              key: :view_form, path: path,
              locate: ->(c) { c.match?(line_regex) },
              remove: ->(c) { remove_whole_line(c, line_regex) }
            )]
          elsif @is_ip
            line_regex = /^[ \t]*<%=\s*render "shared\/ip_rating".*?%>\n/
            [tp(
              key: :view_form, path: path,
              locate: ->(c) { c.match?(line_regex) },
              remove: ->(c) { remove_whole_line(c, line_regex) }
            )]
          else
            line_regex = /^[ \t]*<%=\s*form_field\(f, :#{field_name}\b.*?%>\n/
            [tp(
              key: :view_form, path: path,
              locate: ->(c) { c.match?(line_regex) },
              remove: ->(c) { remove_whole_line(c, line_regex) }
            )]
          end
        end

        def header_view_touchpoint
          return nil unless ScaffoldHelper::INDEX_TYPES.include?(@column_type) || @kind == :association
          path = view_path("_header.html.erb")
          line_regex = /^[ \t]*<th><%=\s*sort_link\(@q, :#{field_name}\)\s*%><\/th>\n/
          tp(
            key: :view_header, path: path,
            locate: ->(c) { c.match?(line_regex) },
            remove: ->(c) { remove_whole_line(c, line_regex) }
          )
        end

        def row_view_touchpoint
          return nil unless ScaffoldHelper::INDEX_TYPES.include?(@column_type) || @kind == :association
          path = view_path("_row.html.erb")
          line_regex = /^[ \t]*<td><%=\s*index_attribute\(row, :#{field_name}\b.*?%><\/td>\n/
          tp(
            key: :view_row, path: path,
            locate: ->(c) { c.match?(line_regex) },
            remove: ->(c) { remove_whole_line(c, line_regex) }
          )
        end

        def show_view_touchpoint
          path = view_path("show.html.erb")
          if @kind == :association
            line_regex = /^[ \t]*<%=\s*show_association\(@#{singular_name}, :#{field_name}\)\s*%>\n/
          else
            return nil if @column_type == :binary
            line_regex = /^[ \t]*<%=\s*show_attribute\(@#{singular_name}, :#{field_name}\b.*?%>\n/
          end
          tp(
            key: :view_show, path: path,
            locate: ->(c) { c.match?(line_regex) },
            remove: ->(c) { remove_whole_line(c, line_regex) }
          )
        end

        def card_view_touchpoint
          path = view_path("_card.html.erb")
          if @kind == :association
            line_regex = /^[ \t]*<%=\s*show_attribute\(#{singular_name}, :#{field_name}, type: :association\)\s*%>\n/
          else
            return nil if @column_type == :binary
            line_regex = /^[ \t]*<%=\s*show_attribute\(#{singular_name}, :#{field_name}\b.*?%>\n/
          end
          tp(
            key: :view_card, path: path,
            locate: ->(c) { c.match?(line_regex) },
            remove: ->(c) { remove_whole_line(c, line_regex) }
          )
        end

        def index_search_touchpoint
          path = view_path("index.html.erb")
          block_regex = /^[ \t]*<%=\s*f\.search_field :#{field_name}_cont,.*?%>\n/m
          tp(
            key: :view_index_search, path: path,
            locate: ->(c) { c.match?(block_regex) },
            remove: ->(c) { remove_whole_line(c, block_regex) }
          )
        end

        # === Factory

        def factory_path
          Pathname.new(File.join(destination_root, "test", "factories", "#{controller_file_path}.rb"))
        end

        def factory_touchpoints
          path = factory_path
          if @kind == :association
            line_regex = /^[ \t]*association :#{field_name}\n/
          else
            line_regex = /^[ \t]*#{field_name} \{.*?\}\n/
          end
          [tp(
            key: :factory, path: path,
            locate: ->(c) { c.match?(line_regex) },
            remove: ->(c) { remove_whole_line(c, line_regex) }
          )]
        end

        # === Model test

        def model_test_path
          Pathname.new(File.join(destination_root, "test", "models", "#{file_path}_test.rb"))
        end

        def model_test_touchpoints
          path = model_test_path
          points = []
          token = symbol_or_string_token(field_name)

          if @required
            macro = @kind == :association ? "test_required_associations" : "test_required_fields"
            line_regex = /^[ \t]*#{macro}\((.*?)\)\n/
            points << tp(
              key: :model_test_required, path: path,
              locate: ->(c) {
                m = c.match(line_regex)
                m && m[1].match?(token)
              },
              remove: ->(c) { remove_arg_or_whole_call(c, line_regex, token) }
            )
          end

          if @kind == :attribute && @unique
            line_regex = /^[ \t]*test_unique_fields\((.*?)\)\n/
            points << tp(
              key: :model_test_unique, path: path,
              locate: ->(c) {
                m = c.match(line_regex)
                m && m[1].match?(token)
              },
              remove: ->(c) { remove_arg_or_whole_call(c, line_regex, token) }
            )
          end

          if @is_enum
            line_regex = /^[ \t]*test_enum_field\(:#{field_name}, prefix: true\)\n/
            points << tp(
              key: :model_test_enum, path: path,
              locate: ->(c) { c.match?(line_regex) },
              remove: ->(c) { remove_whole_line(c, line_regex) }
            )

            # enum vs enum_translated isn't recoverable from Rails' own enum
            # metadata (see discover_field) - discovered here by probing
            # whether this field's symbol actually appears inside a
            # test_enum_translations(...) call, not pre-decided.
            translations_regex = /^[ \t]*test_enum_translations\((.*?)\)\n/
            points << tp(
              key: :model_test_enum_translations, path: path,
              locate: ->(c) {
                m = c.match(translations_regex)
                m && m[1].match?(token)
              },
              remove: ->(c) { remove_arg_or_whole_call(c, translations_regex, token) },
              optional: true
            )
          end

          points
        end

        # === System test

        def system_test_path
          Pathname.new(File.join(destination_root, "test", "system", "#{controller_file_path}_system_test.rb"))
        end

        def system_test_touchpoints
          path = system_test_path
          token = symbol_or_string_token(field_name)
          points = []

          [["@index_fields", ScaffoldHelper::INDEX_TYPES.include?(@column_type) && @kind == :attribute],
           ["@search_fields", ScaffoldHelper::SEARCHABLE_TYPES.include?(@column_type) && @kind == :attribute],
           ["@show_fields", @kind == :attribute],
           ["@show_associations", @kind == :association]].each do |ivar, applicable|
            next unless applicable
            array_regex = /#{Regexp.escape(ivar)} = %i\[(.*?)\]/
            points << tp(
              key: :"system_test_#{ivar.delete('@')}", path: path,
              locate: ->(c) {
                m = c.match(array_regex)
                m && m[1].match?(/\b#{field_name}\b/)
              },
              remove: ->(c) { remove_bracket_element(c, array_regex, /\b#{field_name}\b/, separator: " ") }
            )
          end

          new_fields_regex = /@new_fields = \{(.*?)\}/
          points << tp(
            key: :system_test_new_fields, path: path,
            locate: ->(c) {
              m = c.match(new_fields_regex)
              m && m[1].match?(hash_key_token(field_name))
            },
            remove: ->(c) { remove_bracket_element(c, new_fields_regex, hash_key_token(field_name)) }
          )

          if @is_tagable
            points << system_test_edit_attributes_touchpoint
          end

          points
        end

        # Not a deletion - @edit_attributes is chosen by a heuristic
        # (prefers a field named "notes", falls back to any remaining
        # string/text column) at generation time. If this field is the one
        # currently chosen, the line must be rewritten against the model's
        # *remaining* columns, not just have this field's mention stripped.
        def system_test_edit_attributes_touchpoint
          path = system_test_path
          line_regex = /^([ \t]*)@edit_attributes = (\{.*?\})\n/
          tp(
            key: :system_test_edit_attributes, path: path,
            locate: ->(c) { c.match?(line_regex) },
            remove: ->(c) {
              match = c.match(line_regex)
              next c unless match
              current = match[2]
              new_value =
                if current.match?(hash_key_token(field_name))
                  remaining = @model_class.columns.reject { |col| col.name == field_name }
                  chosen = remaining.find { |col| col.name == "notes" && col.type.in?(%i[string text]) } ||
                    remaining.find { |col| col.type.in?(%i[string text]) }
                  chosen ? "{ #{chosen.name}: \"Updated value\" }" : "{}"
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
          [tp(
            key: :controller_test_create_params, path: path,
            locate: ->(c) {
              m = c.match(create_params_regex)
              m && m[1].match?(hash_key_token(field_name))
            },
            remove: ->(c) { remove_bracket_element(c, create_params_regex, hash_key_token(field_name)) },
            optional: true # create_params is a one-shot generated stub developers routinely hand-edit afterwards
          )]
        end

        # === Constants YAML (enum fields only)

        def constants_path
          file = @namespaced ? "#{class_path[0]}.yml" : "core.yml"
          Pathname.new(File.join(destination_root, "config", "constants", file))
        end

        def constants_touchpoints
          return [] unless @is_enum
          path = constants_path
          key_regex = /^([ \t]*)#{Regexp.escape(field_name)}:[ \t]*\n/
          [tp(
            key: :constants_enum_block, path: path,
            locate: ->(c) { c.match?(key_regex) },
            remove: ->(c) { remove_nested_yaml_block(c, key_regex, singular_name) }
          )]
        end

        # Removes an indented YAML sub-block whose own key matches
        # key_regex (capturing its indentation as group 1), using
        # block_end_offset to find where it ends. If removing it empties
        # the enclosing model's own block entirely, collapses that to
        # "<model>: {}" - matching exactly what insert_enum_constants
        # itself writes for an enum-less model, so removal stays idempotent
        # with a fresh scaffold.
        def remove_nested_yaml_block(content, key_regex, singular_name)
          match = content.match(key_regex)
          return content unless match

          indent = match[1]
          block_start = match.end(0)
          block_end = block_end_offset(content, after_index: block_start, indent: indent)
          new_content = content[0...match.begin(0)] + content[block_end..]

          model_key_regex = /^([ \t]*)#{Regexp.escape(singular_name)}:[ \t]*\n/
          model_match = new_content.match(model_key_regex)
          if model_match
            model_indent = model_match[1]
            model_block_start = model_match.end(0)
            model_block_end = block_end_offset(new_content, after_index: model_block_start, indent: model_indent)
            if new_content[model_block_start...model_block_end].strip.empty?
              new_content = new_content[0...model_match.begin(0)] + "#{model_indent}#{singular_name}: {}\n" + new_content[model_block_end..]
            end
          end
          new_content
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

        # The model's own key appears twice in a models.yml file - once
        # under "models:" (with one:/other: children), once under
        # "attributes:" (with this field's own label line) - confirmed by
        # reading the real generated output, not assumed. Must anchor the
        # search to start after "attributes:", or it matches the wrong
        # occurrence.
        def locale_attributes_model_match(content)
          attrs = content.match(/^[ \t]*attributes:[ \t]*\n/)
          return nil unless attrs
          content.match(/^([ \t]*)#{Regexp.escape(i18n_model_scope)}:[ \t]*\n/, attrs.end(0))
        end

        def locale_touchpoints
          I18n.available_locales.flat_map do |locale|
            path = locale_model_file(locale)
            field_key_regex = /^([ \t]*)#{Regexp.escape(field_name)}:[ \t]*".*?"\n/

            points = [tp(
              key: :"locale_#{locale}_attribute_label", path: path,
              locate: ->(c) {
                m = locale_attributes_model_match(c)
                next false unless m
                block_end = block_end_offset(c, after_index: m.end(0), indent: m[1])
                c[m.end(0)...block_end].match?(field_key_regex)
              },
              remove: ->(c) {
                m = locale_attributes_model_match(c)
                next c unless m
                block_end = block_end_offset(c, after_index: m.end(0), indent: m[1])
                block = c[m.end(0)...block_end]
                c[0...m.end(0)] + remove_whole_line(block, field_key_regex) + c[block_end..]
              }
            )]

            # enum_translated's sibling pluralized block - discovered by
            # probing (see model_test_touchpoints' same reasoning), not
            # pre-decided, and optional for the same reason.
            plural_key_regex = /^([ \t]*)#{Regexp.escape(field_name.pluralize)}:[ \t]*\n/
            points << tp(
              key: :"locale_#{locale}_enum_translated_block", path: path,
              locate: ->(c) {
                m = locale_attributes_model_match(c)
                next false unless m
                block_end = block_end_offset(c, after_index: m.end(0), indent: m[1])
                c[m.end(0)...block_end].match?(plural_key_regex)
              },
              remove: ->(c) {
                m = locale_attributes_model_match(c)
                next c unless m
                model_block_end = block_end_offset(c, after_index: m.end(0), indent: m[1])
                block = c[m.end(0)...model_block_end]
                plural_match = block.match(plural_key_regex)
                next c unless plural_match
                sub_block_end = block_end_offset(block, after_index: plural_match.end(0), indent: plural_match[1])
                new_block = block[0...plural_match.begin(0)] + block[sub_block_end..]
                c[0...m.end(0)] + new_block + c[model_block_end..]
              },
              optional: true
            )

            points
          end
        end
    end
  end
end
