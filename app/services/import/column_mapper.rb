# app/services/import/column_mapper.rb
module Import
  # Suggests a sheet's headers -> Import::ColumnDefinition#key mapping, for
  # the user to confirm/adjust before dry-run validation. A user's saved
  # Import::MappingPreset (if any) always wins over alias-matching, so a
  # returning user's habitual headers keep working even if they happen to
  # collide with a different definition's alias.
  class ColumnMapper
    def initialize(column_definitions, headers:, preset_mapping: {})
      @column_definitions = column_definitions
      @headers = headers
      @preset_mapping = preset_mapping.stringify_keys
    end

    # { sheet_header => column_definition_key_or_nil }
    def suggested_mapping
      headers.each_with_object({}) do |header, mapping|
        mapping[header] = suggest_for(header)
      end
    end

    # Given a confirmed { sheet_header => column_definition_key_or_nil }
    # mapping, which required definitions have nothing mapped to them.
    def missing_required_keys(mapping)
      mapped_keys = mapping.values.compact.map(&:to_sym)
      column_definitions.select(&:required?).reject { |definition| mapped_keys.include?(definition.key) }.map(&:key)
    end

    private

    attr_reader :column_definitions, :headers, :preset_mapping

    def suggest_for(header)
      preset_key = preset_mapping[header]
      return preset_key.to_sym if preset_key.present?

      column_definitions.find { |definition| definition.matches?(header) }&.key
    end
  end
end
