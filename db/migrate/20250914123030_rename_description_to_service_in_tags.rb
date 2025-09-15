class RenameDescriptionToServiceInTags < ActiveRecord::Migration[7.0]
  def up
    # Rename the column
    rename_column :tags, :description, :service
    
    # Update any indexes that might be using the old column name
    # (No indexes found on the description column)
  end
  
  def down
    # Revert the column name change
    rename_column :tags, :service, :description
  end
end
