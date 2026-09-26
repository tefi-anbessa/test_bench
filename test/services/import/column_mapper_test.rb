require "test_helper"

module Import
  class ColumnMapperTest < ActiveSupport::TestCase
    def definitions
      [
        ColumnDefinition.new(key: :full_tag, label: "Tag Number", required: true),
        ColumnDefinition.new(key: :discipline, label: "Discipline", aliases: ["Disc"]),
        ColumnDefinition.new(key: :service, label: "Service", required: true)
      ]
    end

    test "suggests a match for each header that fits a definition, and nil for one that doesn't" do
      mapper = ColumnMapper.new(definitions, headers: ["Tag Number", "Disc", "Notes"])
      assert_equal(
        { "Tag Number" => :full_tag, "Disc" => :discipline, "Notes" => nil },
        mapper.suggested_mapping
      )
    end

    test "a saved preset mapping wins over alias-matching" do
      mapper = ColumnMapper.new(
        definitions,
        headers: ["Tag Number", "Instrument Discipline"],
        preset_mapping: { "Instrument Discipline" => "discipline" }
      )
      assert_equal :discipline, mapper.suggested_mapping["Instrument Discipline"]
    end

    test "missing_required_keys lists required definitions nothing was mapped to" do
      mapper = ColumnMapper.new(definitions, headers: [])
      mapping = { "Tag Number" => :full_tag, "Notes" => nil }
      assert_equal [:service], mapper.missing_required_keys(mapping)
    end

    test "missing_required_keys is empty once every required definition is mapped" do
      mapper = ColumnMapper.new(definitions, headers: [])
      mapping = { "Tag Number" => :full_tag, "Service Column" => :service }
      assert_empty mapper.missing_required_keys(mapping)
    end
  end
end
