class RemoveProjectIdFromTags < ActiveRecord::Migration[8.0]
  def change
    # First remove the foreign key constraint
    remove_foreign_key :tags, :projects
    
    # Remove old indexes
    remove_index :tags, name: "index_tags_on_project_and_full_tag"
    remove_index :tags, :project_id
    remove_index :tags, :loop_id
    
    # Add the generated column for full_tag
    add_column :tags, :full_tag, :virtual, 
               type: :string, 
               as: "COALESCE(prefix, '') || LPAD(serial::text, 4, '0') || COALESCE(suffix, '')", 
               stored: true

    # Add a unique index on discipline_id and full_tag
    add_index :tags, [:discipline_id, :full_tag], 
              unique: true,
              name: "index_tags_on_discipline_and_full_tag"
    
    # Convert loop_id to a virtual stored column
    remove_column :tags, :loop_id, :string
    add_column :tags, :loop_id, :virtual,
               type: :string,
               as: "UPPER(LEFT(COALESCE(prefix, ''), 1)) || LPAD(serial::text, 4, '0')",
               stored: true
    add_index :tags, :loop_id, name: "index_tags_on_loop_id"
    
    # Remove the project_id column
    remove_column :tags, :project_id, :integer
  end
end