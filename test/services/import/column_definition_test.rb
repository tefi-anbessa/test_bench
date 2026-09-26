require "test_helper"

module Import
  class ColumnDefinitionTest < ActiveSupport::TestCase
    test "matches its own label regardless of case/whitespace/punctuation" do
      definition = ColumnDefinition.new(key: :full_tag, label: "Tag Number")
      assert definition.matches?("Tag Number")
      assert definition.matches?("tag  number")
      assert definition.matches?(" TAG-NUMBER ")
    end

    test "matches a declared alias" do
      definition = ColumnDefinition.new(key: :full_tag, label: "Tag Number", aliases: ["Instrument Tag", "Tag No"])
      assert definition.matches?("Instrument Tag")
      assert definition.matches?("tag no")
      refute definition.matches?("Something Else")
    end

    test "matches its own key even without an explicit alias" do
      definition = ColumnDefinition.new(key: :full_tag, label: "Tag Number")
      assert definition.matches?("full_tag")
      assert definition.matches?("full tag")
    end

    test "required? reflects the required: option" do
      assert ColumnDefinition.new(key: :prefix, label: "Prefix", required: true).required?
      refute ColumnDefinition.new(key: :suffix, label: "Suffix").required?
    end

    test "coerce runs the given coercer, and passes nil straight through" do
      definition = ColumnDefinition.new(key: :serial, label: "Serial", coercer: ->(value) { value.to_i })
      assert_equal 42, definition.coerce("42")
      assert_nil definition.coerce(nil)
    end

    test "coerce defaults to an identity function" do
      definition = ColumnDefinition.new(key: :notes, label: "Notes")
      assert_equal "hello", definition.coerce("hello")
    end
  end
end
