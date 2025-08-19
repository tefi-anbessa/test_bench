class AddProjectToCableTypes < ActiveRecord::Migration[7.0]
  def change
    add_reference :cable_types, :project, null: true, foreign_key: true
    add_index :cable_types, :project_id
  end
end
