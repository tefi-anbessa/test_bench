# app/services/import/committer.rb
module Import
  # Persists a batch's dry-run rows (see Import::Base#dry_run_rows) inside a
  # single transaction - strict mode requires every row to already be valid;
  # partial mode commits only the valid ones. Two-phase for any importer with
  # a deferred/self-referential reference (e.g. Tag's parent): phase 1 saves
  # every committable row without that reference, phase 2 - now that
  # in-batch targets have real ids - sets it via the *same* Tag validations
  # used everywhere else (Tag#prevent_circular_reference etc.), not
  # reimplemented here.
  class Committer
    Result = Struct.new(:committed_rows, :skipped_rows, keyword_init: true) do
      def imported_count = committed_rows.size
      def skipped_count = skipped_rows.size
    end

    class InvalidRowsError < StandardError; end

    def initialize(importer:, rows:, partial: false)
      @importer = importer
      @rows = rows
      @partial = partial
    end

    def call
      committable, skipped = partition_rows

      ActiveRecord::Base.transaction do
        committable.each { |row| row.record.save! }
        link_deferred_references!(committable)
      end

      Result.new(committed_rows: committable, skipped_rows: skipped)
    end

    private

    attr_reader :importer, :rows
    def partial? = @partial

    def partition_rows
      invalid_rows = rows.reject(&:valid?)

      unless partial?
        if invalid_rows.any?
          raise InvalidRowsError, "#{invalid_rows.size} of #{rows.size} row(s) are invalid, and partial import wasn't chosen"
        end
        return [rows, []]
      end

      committable = rows.select(&:valid?)

      # A row whose deferred reference points at a row that won't be
      # committed (itself invalid, or cascaded out below) can't have that
      # reference honoured - skip it too rather than silently dropping the
      # relationship it explicitly specified. Repeat to a fixed point, since
      # skipping one row can cascade to whatever referenced *it*.
      loop do
        committable_set = committable.to_set
        newly_skipped = committable.select do |row|
          row.deferred_reference_row && !committable_set.include?(row.deferred_reference_row)
        end
        break if newly_skipped.empty?
        committable -= newly_skipped
      end

      [committable, rows - committable]
    end

    def link_deferred_references!(committable)
      return unless importer.deferred_reference_attribute

      committable.each do |row|
        next unless row.deferred_reference_row
        target_id = row.deferred_reference_row.record.id
        row.record.update!(importer.deferred_reference_attribute => target_id)
      end
    end
  end
end
