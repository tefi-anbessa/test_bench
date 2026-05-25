class AddUniqueIndexToTagsOnTagable < ActiveRecord::Migration[8.0]
  def up
    add_index :tags,
              [:tagable_type, :tagable_id],
              unique: true,
              where: "tagable_id IS NOT NULL",
              name: "index_tags_on_tagable_unique",
              algorithm: :concurrently
  end

  def down
    remove_index :tags, name: "index_tags_on_tagable_unique"
  end
end
