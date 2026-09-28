class AddCreateMissingTagsToImportBatches < ActiveRecord::Migration[8.0]
  def change
    # Opt-in, per-batch flag for a tagable import (see Import::TagableBase):
    # when set, a row whose Tag reference isn't found creates a new Tag +
    # tagable together instead of the default hard "not found" error.
    add_column :import_batches, :create_missing_tags, :boolean, default: false, null: false
  end
end
