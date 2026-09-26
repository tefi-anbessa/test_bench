class CreateImportMappingPresets < ActiveRecord::Migration[8.0]
  def change
    create_table :import_mapping_presets do |t|
      t.bigint :user_id, null: false
      t.string :importer_key, null: false
      t.jsonb :column_mapping, null: false, default: {}

      t.timestamps
    end

    # A user's remembered mapping for a given importer - one per (user,
    # importer_key), not per-discipline, on the assumption a user's habitual
    # spreadsheet layout doesn't vary by discipline.
    add_index :import_mapping_presets, [:user_id, :importer_key], unique: true,
      name: "index_import_mapping_presets_on_user_and_importer_key"
  end
end
