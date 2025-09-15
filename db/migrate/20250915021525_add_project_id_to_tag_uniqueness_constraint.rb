class AddProjectIdToTagUniquenessConstraint < ActiveRecord::Migration[8.0]
  def up
    # Remove the existing full_tag index if it exists
    if index_exists?(:tags, nil, name: 'index_tags_on_full_tag')
      remove_index :tags, name: 'index_tags_on_full_tag'
    end
    
    # Only add the new index if it doesn't already exist
    unless index_exists?(:tags, [:project_id, :discipline_id, :prefix, :serial, :suffix], name: 'index_tags_on_project_and_full_tag', unique: true)
      add_index :tags, 
                [:project_id, :discipline_id, :prefix, :serial, :suffix],
                unique: true,
                name: 'index_tags_on_project_and_full_tag'
    end
  end

  def down
    # Recreate the original index if it doesn't exist
    unless index_exists?(:tags, nil, name: 'index_tags_on_full_tag')
      add_index :tags, [:prefix, :serial, :suffix],
                unique: true,
                name: 'index_tags_on_full_tag'
    end
    
    # Remove the new index if it exists
    if index_exists?(:tags, nil, name: 'index_tags_on_project_and_full_tag')
      remove_index :tags, name: 'index_tags_on_project_and_full_tag'
    end
  end
end
