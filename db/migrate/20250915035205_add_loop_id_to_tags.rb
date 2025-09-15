class AddLoopIdToTags < ActiveRecord::Migration[8.0]
  def change
    # Add the column as nullable first
    add_column :tags, :loop_id, :string
    add_index :tags, :loop_id
    
    # Backfill existing records
    reversible do |dir|
      dir.up do
        # SQLite compatible version
        execute <<-SQL
          UPDATE tags 
          SET loop_id = UPPER(SUBSTR(prefix, 1, 1)) || 
                        SUBSTR('0000' || serial, -4, 4)
          WHERE prefix IS NOT NULL AND serial IS NOT NULL
        SQL
        
        # Make the column non-nullable after backfill
        change_column_null :tags, :loop_id, false
      end
    end
  end
end
