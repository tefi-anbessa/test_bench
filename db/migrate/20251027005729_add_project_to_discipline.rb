
class AddProjectToDiscipline < ActiveRecord::Migration[8.0]
  def up
    # Add the reference first as nullable
    add_reference :disciplines, :project, null: true, foreign_key: true
    
    # Set all existing disciplines to reference Project with ID 1
    execute 'UPDATE disciplines SET project_id = 1'
    
    # Now change the column to be non-nullable
    change_column_null :disciplines, :project_id, false
  end

  def down
    remove_reference :disciplines, :project, foreign_key: true
  end
end