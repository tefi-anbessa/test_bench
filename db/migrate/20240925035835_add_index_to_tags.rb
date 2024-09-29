class AddIndexToTags < ActiveRecord::Migration[7.0]
  def change
    add_index(:tags, [:prefix, :serial, :suffix],
      name: 'index_tags_on_full_tag', unique: true)
  end
end
