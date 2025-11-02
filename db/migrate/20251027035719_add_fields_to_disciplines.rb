class AddFieldsToDisciplines < ActiveRecord::Migration[7.0]
  def change
    add_column :disciplines, :label, :string, comment: 'Short 2-3 character code for display'
    add_column :disciplines, :module_name, :string, comment: 'Associated module for extended functionality'
    add_column :disciplines, :sort_order, :integer, default: 100, comment: 'Display order in UI (lower numbers first)'

    # Add index on sort_order for faster sorting
    add_index :disciplines, :sort_order
    # Ensure code is unique within a project
    add_index :disciplines, [:project_id, :code], unique: true
    # Ensure label is unique within a project
    add_index :disciplines, [:project_id, :label], unique: true
  end
end
