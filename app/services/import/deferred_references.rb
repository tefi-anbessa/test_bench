# app/services/import/deferred_references.rb
module Import
  # Resolves a "this row references another row" column (e.g. Tag's parent)
  # against both the rows already in this same import batch and already-
  # persisted records - generic and model-agnostic, so it isn't tied to Tag
  # or to any particular natural key shape. The caller supplies:
  #
  # - natural_key_for: ->(row) { the key other rows use to reference *this*
  #   row, or nil if it can't have one (e.g. discipline didn't resolve) }
  # - reference_for: ->(row) { the raw reference value this row points to,
  #   or nil/blank if it doesn't reference anything }
  # - resolve_persisted: ->(raw_reference, row) { an already-saved record
  #   matching that reference, or nil } - `row` (the *referencing* row) is
  #   passed through because resolving a reference against persisted records
  #   can depend on the referencing row's own resolved context (e.g. a bare,
  #   unqualified parent tag reference is scoped to the referencing row's
  #   own discipline)
  #
  # `row` is opaque to this class - whatever object the caller's procs deal
  # in (e.g. an Import::Row).
  class DeferredReferences
    CircularReferenceError = Class.new(StandardError)

    def initialize(rows:, natural_key_for:, reference_for:, resolve_persisted:)
      @rows = rows
      @natural_key_for = natural_key_for
      @reference_for = reference_for
      @resolve_persisted = resolve_persisted
      @index = build_index
    end

    # { row => result }, one entry per row that has a reference to resolve
    # (rows with no reference at all are simply absent). `result` is one of:
    #   { in_batch: other_row }        - resolves to another row in this batch
    #   { persisted: record }          - resolves to an already-saved record
    #   { error: "message" }           - could not be resolved
    #
    # Raises CircularReferenceError if the in-batch reference graph itself
    # contains a cycle - that's unresolvable regardless of insert order, so
    # it's a batch-level failure rather than a per-row one.
    def resolve
      detect_cycles!

      rows.each_with_object({}) do |row, results|
        raw_reference = reference_for.call(row)
        next if blank?(raw_reference)

        if (target_row = index[normalize(raw_reference)])
          results[row] = { in_batch: target_row }
        elsif (persisted = resolve_persisted.call(raw_reference, row))
          results[row] = { persisted: persisted }
        else
          results[row] = { error: "Reference '#{raw_reference}' not found in this file or existing records" }
        end
      end
    end

    private

    attr_reader :rows, :natural_key_for, :reference_for, :resolve_persisted, :index

    def build_index
      rows.each_with_object({}) do |row, idx|
        key = natural_key_for.call(row)
        idx[normalize(key)] = row unless blank?(key)
      end
    end

    def blank?(value)
      value.nil? || value.to_s.strip.empty?
    end

    def normalize(key)
      key.to_s.strip.downcase
    end

    # Follows in-batch references from each row, raising if the chain ever
    # revisits a row already seen while following *that* row's own chain.
    def detect_cycles!
      rows.each do |starting_row|
        visited = Set.new
        current = starting_row

        loop do
          raw_reference = reference_for.call(current)
          break if blank?(raw_reference)

          target_row = index[normalize(raw_reference)]
          break unless target_row # not an in-batch reference - no cycle risk from here

          if visited.include?(target_row)
            raise CircularReferenceError, "Circular reference detected starting from row #{rows.index(starting_row) + 1}"
          end

          visited << target_row
          current = target_row
        end
      end
    end
  end
end
