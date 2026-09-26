# app/services/import/column_definition.rb
module Import
  # One importable field an Import::Base subclass declares via
  # #column_definitions - e.g. Tag's "prefix" column. Purely descriptive: it
  # knows how to recognize a sheet's header as this field and how to coerce a
  # raw cell value, but resolving foreign keys or building the target record
  # is the importer's own job, not this class's.
  class ColumnDefinition
    attr_reader :key, :label, :aliases, :required

    def initialize(key:, label:, aliases: [], required: false, coercer: ->(value) { value })
      @key = key.to_sym
      @label = label
      @aliases = Array(aliases).map { |a| normalize(a) }
      @required = required
      @coercer = coercer
    end

    def required?
      @required
    end

    # Does this sheet header plausibly mean this column? Matches on the
    # label, any declared alias, or the raw key itself (so a header that's
    # already the app's own attribute name - e.g. from a file exported by
    # this app - matches with no aliases needed).
    def matches?(header)
      candidates = [normalize(label), normalize(key)] + aliases
      candidates.include?(normalize(header))
    end

    def coerce(raw_value)
      return nil if raw_value.nil?
      @coercer.call(raw_value)
    end

    private

    def normalize(text)
      text.to_s.strip.downcase.gsub(/[\s_-]+/, " ")
    end
  end
end
