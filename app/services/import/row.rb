# app/services/import/row.rb
module Import
  # One spreadsheet row's result as it moves through the dry-run pipeline.
  # `resolution_errors` are added by the framework/importer *before* a record
  # is even built (e.g. an unresolvable discipline code) - when any exist,
  # the row's own model validations are never run (see Import::Base), so a
  # user only ever sees one, specific, actionable message per problem rather
  # than a resolution error and a generic "must exist" validation error
  # saying the same thing two different ways.
  class Row
    attr_reader :row_number, :raw, :resolution_errors
    attr_accessor :attributes, :record
    # Set when this row's deferred/self-referential reference (e.g. parent)
    # resolves to another row in this same batch, rather than an
    # already-persisted record or a plain foreign key - see
    # Import::Base#resolve_deferred_references!. Import::Committer uses this
    # for its two-phase insert, once the referenced row has a real id.
    attr_accessor :deferred_reference_row

    def initialize(row_number:, raw:)
      @row_number = row_number
      @raw = raw
      @attributes = {}
      @resolution_errors = []
      @record = nil
    end

    def add_resolution_error(message)
      resolution_errors << message
    end

    def valid?
      return false if resolution_errors.any?
      record.present? && record.errors.empty?
    end

    def error_messages
      return resolution_errors if resolution_errors.any?
      record ? record.errors.full_messages : []
    end
  end
end
