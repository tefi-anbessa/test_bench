require "test_helper"

module Import
  class MappingPresetTest < ActiveSupport::TestCase
    test "valid factory" do
      preset = build(:import_mapping_preset)
      assert preset.valid?, preset.errors.full_messages.join(", ")
    end

    test "importer_key is unique per user" do
      existing = create(:import_mapping_preset)
      duplicate = build(:import_mapping_preset, user: existing.user, importer_key: existing.importer_key)
      refute duplicate.valid?
      assert_includes duplicate.errors.attribute_names, :importer_key
    end

    test "the same importer_key is allowed for different users" do
      existing = create(:import_mapping_preset)
      other = build(:import_mapping_preset, importer_key: existing.importer_key)
      assert other.valid?, other.errors.full_messages.join(", ")
    end

    test ".remember! creates a new preset the first time" do
      user = create(:user)
      preset = MappingPreset.remember!(user: user, importer_key: "tags", column_mapping: { "A" => "prefix" })
      assert preset.persisted?
      assert_equal({ "A" => "prefix" }, preset.column_mapping)
    end

    test ".remember! updates the existing preset on a later call" do
      preset = create(:import_mapping_preset, importer_key: "tags", column_mapping: { "A" => "prefix" })
      MappingPreset.remember!(user: preset.user, importer_key: "tags", column_mapping: { "B" => "serial" })

      assert_equal 1, MappingPreset.where(user: preset.user, importer_key: "tags").count
      assert_equal({ "B" => "serial" }, preset.reload.column_mapping)
    end
  end
end
