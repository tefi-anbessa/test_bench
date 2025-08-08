class AddIndexToTags < ActiveRecord::Migration[7.0]
  # Consider including project and discipline in unique index for tags.
  def change
    add_index(:tags, [:prefix, :serial, :suffix],
      name: 'index_tags_on_full_tag', unique: true)
  end
end
