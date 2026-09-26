# app/models/import/mapping_preset.rb
module Import
  # A user's remembered column mapping for a given importer, so a returning
  # user's next import of the same kind needs no remapping. Durable (not
  # ephemeral like Import::Batch) - upserted whenever a mapping is confirmed.
  class MappingPreset < ApplicationRecord
    self.table_name = "import_mapping_presets"

    belongs_to :user

    validates :importer_key, presence: true, uniqueness: { scope: :user_id }

    def self.remember!(user:, importer_key:, column_mapping:)
      preset = find_or_initialize_by(user: user, importer_key: importer_key)
      preset.update!(column_mapping: column_mapping)
      preset
    end
  end
end
