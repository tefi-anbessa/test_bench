require "test_helper"

module Import
  class DeferredReferencesTest < ActiveSupport::TestCase
    Row = Struct.new(:key, :ref)

    def resolver_for(rows, persisted: {})
      DeferredReferences.new(
        rows: rows,
        natural_key_for: ->(row) { row.key },
        reference_for: ->(row) { row.ref },
        resolve_persisted: ->(ref, _row) { persisted[ref] }
      )
    end

    test "a row with no reference is absent from the results" do
      a = Row.new("A", nil)
      results = resolver_for([a]).resolve
      assert_empty results
    end

    test "resolves a forward reference to another row in the same batch" do
      a = Row.new("A", "B") # A references B, which appears after it
      b = Row.new("B", nil)
      results = resolver_for([a, b]).resolve
      assert_equal({ in_batch: b }, results[a])
    end

    test "resolve_persisted receives the referencing row itself, not just the raw reference" do
      a = Row.new("A", "SOMETHING")
      seen = nil
      resolver = DeferredReferences.new(
        rows: [a],
        natural_key_for: ->(row) { row.key },
        reference_for: ->(row) { row.ref },
        resolve_persisted: ->(_ref, row) { seen = row; nil }
      )
      resolver.resolve
      assert_same a, seen
    end

    test "resolves a reference to an already-persisted record when not found in-batch" do
      a = Row.new("A", "EXISTING")
      existing_record = Object.new
      results = resolver_for([a], persisted: { "EXISTING" => existing_record }).resolve
      assert_equal({ persisted: existing_record }, results[a])
    end

    test "in-batch match takes priority over an already-persisted match with the same key" do
      a = Row.new("A", "B")
      b = Row.new("B", nil)
      results = resolver_for([a, b], persisted: { "B" => Object.new }).resolve
      assert_equal({ in_batch: b }, results[a])
    end

    test "an unresolvable reference is a per-row error, not an exception" do
      a = Row.new("A", "NOWHERE")
      results = resolver_for([a]).resolve
      assert_equal({ error: "Reference 'NOWHERE' not found in this file or existing records" }, results[a])
    end

    test "matching is case and whitespace insensitive" do
      a = Row.new("A", "  b  ")
      b = Row.new("B", nil)
      results = resolver_for([a, b]).resolve
      assert_equal({ in_batch: b }, results[a])
    end

    test "raises on a direct self-reference" do
      a = Row.new("A", "A")
      assert_raises(DeferredReferences::CircularReferenceError) { resolver_for([a]).resolve }
    end

    test "raises on an indirect cycle" do
      a = Row.new("A", "B")
      b = Row.new("B", "C")
      c = Row.new("C", "A")
      assert_raises(DeferredReferences::CircularReferenceError) { resolver_for([a, b, c]).resolve }
    end

    test "does not raise for a chain that terminates without a cycle" do
      a = Row.new("A", "B")
      b = Row.new("B", "C")
      c = Row.new("C", nil)
      results = resolver_for([a, b, c]).resolve
      assert_equal({ in_batch: b }, results[a])
      assert_equal({ in_batch: c }, results[b])
      assert_nil results[c]
    end
  end
end
